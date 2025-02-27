// SPDX-License-Identifier: Unlicensed
pragma solidity 0.7.3;

import "./helpers/TollCore.sol";


/// @title Toll smart contract
/// @author DAO.MAKER
/// @notice Contract calculates, distribute and keep the investors state and balances
/// @dev The contract accepts calls only from Toll factory contract (owner)
/// All percentage variables uses x100, eg: 15% should be provided as 1500
contract Toll is TollCore {
  using SafeMath for uint256;

  // ------------------
  // OWNER PUBLIC METHODS
  // ------------------

  /// @dev Operator should add whitelisted users with this method
  /// It can be called several times for big amount of users
  function addWhitelistedUsers(
    address[] calldata _usersArray,
    uint256[] calldata _amountsArray
  ) external onlyOwner {
    require(initialized, "addWhitelistedUsers: Initialization should be done before calling this method!");
    require(_usersArray.length != 0, "addWhitelistedUsers: could not be 0 length array!");
    require(_usersArray.length == _amountsArray.length, "addWhitelistedUsers: could not be different length arrays!");

    uint256 totalTokens;

    for (uint256 i = 0; i < _usersArray.length; i++) {
      address user = _usersArray[i];
      uint256 amount = _amountsArray[i];

      require(!_users[user].whitelisted, "addWhitelistedUsers: user duplication!");

      _users[user] = User({
        whitelisted: true,
        maxTokens: amount,
        receivedReleases: 0,
        burnedTokens: 0,
        distributedTokens: 0,
        naturallyReceivedTokens: 0
      });

      totalTokens = totalTokens.add(amount);
    }
  }

  /// @dev Operator can distribute naturally available tokens to provided receivers
  function massClaimNaturalTokens(address[] calldata receivers) external onlyOwner returns (uint256[] memory) {
    require(!paused(), "massRelease: Claiming tokens is paused!");

    uint256[] memory transferrableAmounts = new uint256[](receivers.length);

    for (uint256 i = 0; i < receivers.length; i++) {
      address receiver = receivers[i];
      require(_users[receiver].whitelisted, "massClaimNaturalTokens: Some receivers are not whitelisted!");

      uint256 transferableTokens = _getNaturalAvailableTokens(receiver);
      transferrableAmounts[i] = transferableTokens;

      if (transferableTokens > 0) {
        _users[receiver].receivedReleases = _getPassedReleasesCount();
        _users[receiver].distributedTokens = _users[receiver].distributedTokens.add(transferableTokens);
        _users[receiver].naturallyReceivedTokens = _users[receiver].naturallyReceivedTokens.add(transferableTokens);

        _transferTokens(receiver, transferableTokens);
      }
    }

    return transferrableAmounts;
  }

  // ------------------
  // PUBLIC SETTERS
  // ------------------

  /// @dev Method automatically calculates and knows which feature to use (natural nor bridge)
  /// It will never been reverted (only if toll bridge paused).
  function claimTokens(
    address receiver,
    uint256 amount
  ) external onlyOwner onlyWhitelisted(receiver) returns (
    uint256 burnableTokens,
    uint256 transferableTokens
  ) {
    require(amount != 0, "claimTokens: Amount should be bigger 0!");
    require(receiver != address(0), "claimTokens: Receiver can not be zero address!");

    if (amount > _users[receiver].maxTokens.sub(_users[receiver].distributedTokens)) {
      amount = _users[receiver].maxTokens.sub(_users[receiver].distributedTokens);
    }

    uint256 naturalAvailableTokens = _getNaturalAvailableTokens(receiver);

    if (amount > naturalAvailableTokens && !_isFinished()) {
      require(!paused(), "claimTokens: Claiming tokens via toll bridge is paused!");

      if (naturalAvailableTokens != 0) {
        _users[receiver].receivedReleases = _getPassedReleasesCount();
        _users[receiver].distributedTokens = _users[receiver].distributedTokens.add(naturalAvailableTokens);
        _users[receiver].naturallyReceivedTokens = _users[receiver].naturallyReceivedTokens.add(naturalAvailableTokens);

        transferableTokens = naturalAvailableTokens;
      }

      uint256 overageAmount = amount.sub(naturalAvailableTokens);
      (uint256 burnPercent, uint256 transferPercent) = _getBurnAndTransferPercents(receiver);
      burnableTokens = _percentToAmount(overageAmount, burnPercent);
      uint256 tollBridgeTransferableTokens = _percentToAmount(overageAmount, transferPercent);

      transferableTokens = transferableTokens.add(tollBridgeTransferableTokens);
      _users[receiver].burnedTokens = _users[receiver].burnedTokens.add(burnableTokens);
      _users[receiver].distributedTokens = _users[receiver].distributedTokens.add(tollBridgeTransferableTokens.add(burnableTokens));
    } else {
      if (amount != naturalAvailableTokens) {
        amount = naturalAvailableTokens;
      }

      _users[receiver].receivedReleases = _getPassedReleasesCount();
      _users[receiver].distributedTokens = _users[receiver].distributedTokens.add(amount);
      _users[receiver].naturallyReceivedTokens = _users[receiver].naturallyReceivedTokens.add(amount);

      transferableTokens = amount;
    }

    _transferTokens(receiver, transferableTokens);
    if (burnableTokens != 0) {
      if (isBurnableToken) {
        _burnTokens(burnableTokens);
      } else {
        _transferTokens(burnValley, burnableTokens);
      }
    }

    return (
      burnableTokens,
      transferableTokens
    );
  }

  // ------------------
  // PUBLIC GETTERS
  // ------------------

  /// @dev Method returns ONLY natural available tokens, without toll bridge tokens
  function getNaturalAvailable(address user) external view returns (uint256) {
    return _getNaturalAvailableTokens(user);
  }

  // ------------------
  // INTERNAL METHODS
  // ------------------

  /// @dev Method calculates percent of toll bridge (transferable/burnable
  /// The formula is following:
  /// ----------------
  /// TOLL_BRIDGE_CLAIM = (100 - X) * (Y * (A - Z) / A) + B * (Z / A)
  /// CLAIM_PERCENT = 100 - TOLL_BRIDGE_CLAIM - X
  /// BURN_PERCENT = 100 - (CLAIM_PERCENT / (TOLL_BRIDGE_CLAIM + CLAIM_PERCENT) * 100 )
  /// SENT_PERCENT = 100 - BURN_PERCENT
  /// ----------------
  /// X => at the time of claim, percentage of tokens naturally distributed
  /// Y => the percent of tokens burned for claims right after TGE (cost to instant flippers)
  /// A => full distribution delay by seconds (provided by operator during initialization)
  /// Z => days since TGE
  /// B => Distribution rate
  /// ----------------
  /// It uses the current state of the user (naturallyReceivedTokens), and returns 2 percent values
  /// Percents can be used only for this state, and will be changed after call
  function _getBurnAndTransferPercents(address user) private view returns (uint256, uint256) {
    uint256 burnPercent;
    uint256 transferPercent;
    uint256 tollBridgeClaim;
    uint256 additionalClaim;
    uint256 timeSinceCreation = _timeSinceCreation();
    uint256 naturallyClaimedPercent = (_users[user].naturallyReceivedTokens.mul(HUNDRED_PERCENT)).div(_users[user].maxTokens);

    tollBridgeClaim = (HUNDRED_PERCENT.sub(naturallyClaimedPercent))
      .mul((MULTIPLIER.mul(tollFee).mul(fullDistributionSeconds.sub(timeSinceCreation))).div(fullDistributionSeconds.mul(HUNDRED_PERCENT)))
      .add(MULTIPLIER.mul(distributionRate.mul(timeSinceCreation)).div(fullDistributionSeconds))
      .div(MULTIPLIER);

    additionalClaim = HUNDRED_PERCENT.sub(tollBridgeClaim.add(naturallyClaimedPercent));
    burnPercent = HUNDRED_PERCENT.sub(((additionalClaim.mul(HUNDRED_PERCENT)).div(tollBridgeClaim.add(additionalClaim))));
    transferPercent = HUNDRED_PERCENT.sub(burnPercent);

    return (
      burnPercent,
      transferPercent
    );
  }

  function _getNaturalAvailableTokens(address user) internal view returns (uint256) {
    uint256 naturalAvailableTokens;
    uint256 receivedReleases = _users[user].receivedReleases;
    uint256 missedReleases = _getPassedReleasesCount().sub(receivedReleases);
    uint256 availableTokens = _users[user].maxTokens.sub(_users[user].distributedTokens);

    while (missedReleases > 0) {
      uint256 tokensPerRelease = _getTokensPerRelease(receivedReleases, availableTokens);
      availableTokens = availableTokens.sub(tokensPerRelease);
      naturalAvailableTokens = naturalAvailableTokens.add(tokensPerRelease);

      missedReleases--;
      receivedReleases++;
    }

    return naturalAvailableTokens;
  }

  /// @dev Returns tokens of provided release of the certain user
  /// The formula is following:
  /// ----------------
  /// RELEASE_PERCENT * LEFT_TOKENS / (RELEASE_PERCENT + REST_PERCENTS_SUM)
  function _getTokensPerRelease(uint256 releaseId, uint256 leftTokens) internal view returns (uint256) {
    (uint256 releasePercent, uint256 restPercents) = _getReleaseAndLeftPercents(releaseId);

    return (releasePercent.mul(leftTokens).div(releasePercent.add(restPercents)));
  }

  /// @dev Returns the percent of thee current release and sum of the left releases
  function _getReleaseAndLeftPercents(uint256 releaseId) internal view returns (uint256, uint256) {
    uint256 restPercents = HUNDRED_PERCENT;
    uint256 releasePercent = distributionPercents[releaseId];

    for (uint8 i = 0; i <= releaseId; i++) {
      restPercents = restPercents.sub(distributionPercents[i]);
    }

    return (releasePercent, restPercents);
  }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.7.3;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interfaces/IBurnable.sol";
import "./Ownable.sol";


/// @title Toll core smart contract
/// @author DAO.MAKER
/// @dev Contract includes the storage variables and methods, which not contains the main logical functions.
contract TollCore is Pausable, Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  uint256 public finish;
  uint256 public tollFee;
  uint256 public createdAt;
  uint256 public distributionRate;
  uint256 public fullDistributionSeconds;
  uint256 public constant MULTIPLIER = 10**24;
  uint256 public constant HUNDRED_PERCENT = 10000;

  uint256[] public distributionDelays;
  uint256[] public distributionPercents;

  address public burnValley;

  bool public initialized;
  bool public isBurnableToken;

  IERC20 public token;

  struct User {
    bool whitelisted;
    uint256 maxTokens;
    uint256 receivedReleases;
    uint256 burnedTokens;
    uint256 distributedTokens;
    uint256 naturallyReceivedTokens;
  }

  mapping(address => User) internal _users;

  modifier onlyWhitelisted(address receiver) {
    require(_users[receiver].whitelisted, "onlyWhitelisted: Receiver is not whitelisted!");
    _;
  }


  // ------------------
  // PUBLIC SETTERS (OWNER)
  // ------------------

  /// @dev Should be called only once, after contract cloning
  function init(
    address _token,
    uint256 _tollFee,
    uint256 _distributionRate,
    uint256 _fullDistributionSeconds,
    uint256[] calldata _distributionDelays,
    uint256[] calldata _distributionPercents,
    bool _isBurnableToken,
    address _burnValley
  ) external {
    require(!initialized, "init: Can not be initialized twice!");
    require(_token != address(0), "init: Token address can not be ZERO_ADDR!");
    require(_distributionDelays.length != 0 && _distributionDelays.length < 12, "init: Incompatible delays count!");
    require(_distributionDelays.length == _distributionPercents.length, "init: Delays and percents should be equal!");
    require(HUNDRED_PERCENT >= _tollFee, "init: The toll fee can not be bigger then 100%!");
    require(_getArraySum(_distributionPercents) == HUNDRED_PERCENT, "init: The total percent of all releases is not equal to hundred percent!");

    initialized = true;
    tollFee = _tollFee;
    token = IERC20(_token);
    burnValley = _burnValley;
    createdAt = block.timestamp;
    isBurnableToken = _isBurnableToken;
    distributionRate = _distributionRate;
    fullDistributionSeconds = _fullDistributionSeconds;
    distributionDelays = _distributionDelays;
    distributionPercents = _distributionPercents;
    finish = block.timestamp.add(_getArraySum(_distributionDelays));

    _transferOwnership(msg.sender);
  }

  /// @dev Pause toll bridge feature, natural claiming method still will be available
  function pause() external onlyOwner {
    _pause();
  }

  /// @dev Resume toll bridge feature
  function unpause() external onlyOwner {
    _unpause();
  }

  /// @dev Exit contract and funds if extra situation happens.
  /// Operator can get back all tokens back
  function emergencyExit(address receiver) external onlyOwner {
    token.safeTransfer(receiver, token.balanceOf(address(this)));
  }

  // ------------------
  // PUBLIC GETTERS
  // ------------------

  /// @dev Method returns user data (whitelisted, max tokens, received tokens, last activity timestamp)
  function getUserStats(address user) external view returns (
    bool whitelisted,
    uint256 maxTokens,
    uint256 receivedReleases,
    uint256 burnedTokens,
    uint256 distributedTokens,
    uint256 naturallyReceivedTokens
  ) {
    return (
      _users[user].whitelisted,
      _users[user].maxTokens,
      _users[user].receivedReleases,
      _users[user].burnedTokens,
      _users[user].distributedTokens,
      _users[user].naturallyReceivedTokens
    );
  }

  /// @dev Get upcoming release date (timestamp)
  /// After reaching the time it will return the timestamp of the last release
  function getUpcomingReleaseDate() external view returns (uint256) {
    return _getUpcomingReleaseDate();
  }

  // ------------------
  // INTERNAL HELPERS
  // ------------------

  /// @dev Returns date of the next release
  function _getUpcomingReleaseDate() internal view returns (uint256) {
    if (_isFinished()) {
      return finish;
    }

    uint256 nextReleaseDate = createdAt;

    for (uint256 i = 0; i < distributionDelays.length; i++) {
      nextReleaseDate = nextReleaseDate.add(distributionDelays[i]);
      if (nextReleaseDate > block.timestamp) break;
    }

    return nextReleaseDate;
  }

  /// @dev Returns the passed releases count since contract creation
  function _getPassedReleasesCount() internal view returns (uint256) {
    uint256 releaseId;
    uint256 timePassed;
    uint256 timeSinceCreation = _timeSinceCreation();

    for (uint256 i = 0; i < distributionDelays.length; i++) {
      timePassed = timePassed.add(distributionDelays[i]);

      if (timeSinceCreation > timePassed) {
        releaseId++;
      } else break;
    }

    return releaseId;
  }

  /// @dev Simple method, returns percent of the provided amount
  function _percentToAmount(uint256 amount, uint256 percent) internal pure returns (uint256) {
    return amount.mul(percent).div(HUNDRED_PERCENT);
  }

  /// @dev Returns time after contract deployment (seconds)
  function _timeSinceCreation() internal view returns (uint256) {
    return block.timestamp.sub(createdAt);
  }

  /// @dev Return is Toll finished or not
  function _isFinished() internal view returns (bool) {
    return block.timestamp > finish;
  }

  /// @dev Compute sum of arrays' all elements
  function _getArraySum(uint256[] calldata uintArray) internal pure returns (uint256) {
    uint256 sum;

    for (uint256 i = 0; i < uintArray.length; i++) {
      sum = sum.add(uintArray[i]);
    }

    return sum;
  }

  /// @dev Transfer tokens to receiver by safeTransfer method
  function _transferTokens(address to, uint256 amount) internal {
    token.safeTransfer(to, amount);
  }

  /// @dev Transfer tokens to receiver by safeTransfer method
  function _transferTokensFrom(address from, address to, uint256 amount) internal {
    token.safeTransferFrom(from, to, amount);
  }

  /// @dev Burn amount of tokens from contract balance
  function _burnTokens(uint256 amount) internal {
    IBurnable(address(token)).burn(amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.7.3;

interface IBurnable {
  function burn(uint256 amount) external;
  function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "@openzeppelin/contracts/GSN/Context.sol";


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}