/**
 *Submitted for verification at Etherscan.io on 2021-01-18
*/

// File: @openzeppelin/contracts/math/Math.sol

pragma solidity ^0.5.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

// File: @openzeppelin/contracts/token/ERC20/ERC20Detailed.sol

pragma solidity ^0.5.0;


/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.5.5;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.5.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/Storage.sol

pragma solidity 0.5.16;

contract Storage {

    address public governance;
    address public controller;

    constructor() public {
        governance = msg.sender;
    }

    modifier onlyGovernance() {
        require(isGovernance(msg.sender), "Not governance");
        _;
    }

    function setGovernance(address _governance) public onlyGovernance {
        require(_governance != address(0), "new governance shouldn't be empty");
        governance = _governance;
    }

    function setController(address _controller) public onlyGovernance {
        require(_controller != address(0), "new controller shouldn't be empty");
        controller = _controller;
    }

    function isGovernance(address account) public view returns (bool) {
        return account == governance;
    }

    function isController(address account) public view returns (bool) {
        return account == controller;
    }
}

// File: contracts/Governable.sol

pragma solidity 0.5.16;


contract Governable {

    Storage public store;

    constructor(address _store) public {
        require(_store != address(0), "new storage shouldn't be empty");
        store = Storage(_store);
    }

    modifier onlyGovernance() {
        require(store.isGovernance(msg.sender), "Not governance");
        _;
    }

    function setStorage(address _store) public onlyGovernance {
        require(_store != address(0), "new storage shouldn't be empty");
        store = Storage(_store);
    }

    function governance() public view returns (address) {
        return store.governance();
    }
}

// File: contracts/Controllable.sol

pragma solidity 0.5.16;


contract Controllable is Governable {

    constructor(address _storage) Governable(_storage) public {
    }

    modifier onlyController() {
        require(store.isController(msg.sender), "Not a controller");
        _;
    }

    modifier onlyControllerOrGovernance(){
        require((store.isController(msg.sender) || store.isGovernance(msg.sender)),
            "The caller must be controller or governance");
        _;
    }

    function controller() public view returns (address) {
        return store.controller();
    }
}

// File: contracts/hardworkInterface/IStrategy.sol

pragma solidity 0.5.16;

interface IStrategy {

    function unsalvagableTokens(address tokens) external view returns (bool);

    function governance() external view returns (address);
    function controller() external view returns (address);
    function underlying() external view returns (address);
    function vault() external view returns (address);

    function withdrawAllToVault() external;
    function withdrawToVault(uint256 amount) external;

    function investedUnderlyingBalance() external view returns (uint256); // itsNotMuch()

    // should only be called by controller
    function salvage(address recipient, address token, uint256 amount) external;

    function doHardWork() external;
    function depositArbCheck() external view returns(bool);
}

// File: contracts/uniswap/interfaces/IUniswapV2Router01.sol

pragma solidity >=0.5.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: contracts/uniswap/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.5.0;


interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File: contracts/strategies/idle/IdleToken.sol

/**
 * @title: Idle Token interface
 * @author: Idle Labs Inc., idle.finance
 */
pragma solidity 0.5.16;

interface IIdleTokenV3_1 {
    // view
    /**
     * IdleToken price calculation, in underlying
     *
     * @return : price in underlying token
     */
    function tokenPrice() external view returns (uint256 price);

    /**
     * @return : underlying token address
     */
    function token() external view returns (address);
    /**
     * Get APR of every ILendingProtocol
     *
     * @return addresses: array of token addresses
     * @return aprs: array of aprs (ordered in respect to the `addresses` array)
     */
    function getAPRs() external view returns (address[] memory addresses, uint256[] memory aprs);

    // external
    // We should save the amount one has deposited to calc interests

    /**
     * Used to mint IdleTokens, given an underlying amount (eg. DAI).
     * This method triggers a rebalance of the pools if needed
     * NOTE: User should 'approve' _amount of tokens before calling mintIdleToken
     * NOTE 2: this method can be paused
     *
     * @param _amount : amount of underlying token to be lended
     * @param _skipRebalance : flag for skipping rebalance for lower gas price
     * @param _referral : referral address
     * @return mintedTokens : amount of IdleTokens minted
     */
    function mintIdleToken(uint256 _amount, bool _skipRebalance, address _referral) external returns (uint256 mintedTokens);

    /**
     * Here we calc the pool share one can withdraw given the amount of IdleToken they want to burn
     * This method triggers a rebalance of the pools if needed
     * NOTE: If the contract is paused or iToken price has decreased one can still redeem but no rebalance happens.
     * NOTE 2: If iToken price has decresed one should not redeem (but can do it) otherwise he would capitalize the loss.
     *         Ideally one should wait until the black swan event is terminated
     *
     * @param _amount : amount of IdleTokens to be burned
     * @return redeemedTokens : amount of underlying tokens redeemed
     */
    function redeemIdleToken(uint256 _amount) external returns (uint256 redeemedTokens);
    /**
     * Here we calc the pool share one can withdraw given the amount of IdleToken they want to burn
     * and send interest-bearing tokens (eg. cDAI/iDAI) directly to the user.
     * Underlying (eg. DAI) is not redeemed here.
     *
     * @param _amount : amount of IdleTokens to be burned
     */
    function redeemInterestBearingTokens(uint256 _amount) external;

    /**
     * @return : whether has rebalanced or not
     */
    function rebalance() external returns (bool);
}

// File: contracts/strategies/idle/IIdleTokenHelper.sol

pragma solidity 0.5.16;

contract IIdleTokenHelper {
    function getMintingPrice(address idleYieldToken) view external returns (uint256 mintingPrice);
    function getRedeemPrice(address idleYieldToken) view external returns (uint256 redeemPrice);
    function getRedeemPrice(address idleYieldToken, address user) view external returns (uint256 redeemPrice);
}

// File: contracts/hardworkInterface/IController.sol

pragma solidity 0.5.16;

interface IController {
    // [Grey list]
    // An EOA can safely interact with the system no matter what.
    // If you're using Metamask, you're using an EOA.
    // Only smart contracts may be affected by this grey list.
    //
    // This contract will not be able to ban any EOA from the system
    // even if an EOA is being added to the greyList, he/she will still be able
    // to interact with the whole system as if nothing happened.
    // Only smart contracts will be affected by being added to the greyList.
    // This grey list is only used in Vault.sol, see the code there for reference
    function greyList(address _target) external view returns(bool);

    function addVaultAndStrategy(address _vault, address _strategy) external;
    function doHardWork(address _vault, uint256 hint, uint256 devianceNumerator, uint256 devianceDenominator) external;
    function hasVault(address _vault) external returns(bool);

    function salvage(address _token, uint256 amount) external;
    function salvageStrategy(address _strategy, address _token, uint256 amount) external;

    function notifyFee(address _underlying, uint256 fee) external;
    function profitSharingNumerator() external view returns (uint256);
    function profitSharingDenominator() external view returns (uint256);
}

// File: contracts/strategies/RewardTokenProfitNotifier.sol

pragma solidity 0.5.16;






contract RewardTokenProfitNotifier is Controllable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public profitSharingNumerator;
    uint256 public profitSharingDenominator;
    address public rewardToken;

    constructor(
        address _storage,
        address _rewardToken
    ) public Controllable(_storage){
        rewardToken = _rewardToken;
        // persist in the state for immutability of the fee
        profitSharingNumerator = 30; //IController(controller()).profitSharingNumerator();
        profitSharingDenominator = 100; //IController(controller()).profitSharingDenominator();
        require(profitSharingNumerator < profitSharingDenominator, "invalid profit share");
    }

    event ProfitLogInReward(uint256 profitAmount, uint256 feeAmount, uint256 timestamp);

    function notifyProfitInRewardToken(uint256 _rewardBalance) internal {
        if( _rewardBalance > 0 ){
            uint256 feeAmount = _rewardBalance.mul(profitSharingNumerator).div(profitSharingDenominator);
            emit ProfitLogInReward(_rewardBalance, feeAmount, block.timestamp);
            IERC20(rewardToken).safeApprove(controller(), 0);
            IERC20(rewardToken).safeApprove(controller(), feeAmount);

            IController(controller()).notifyFee(
                rewardToken,
                feeAmount
            );
        } else {
            emit ProfitLogInReward(0, 0, block.timestamp);
        }
    }

}

// File: contracts/hardworkInterface/IVault.sol

pragma solidity 0.5.16;

interface IVault {

    function underlyingBalanceInVault() external view returns (uint256);
    function underlyingBalanceWithInvestment() external view returns (uint256);

    // function store() external view returns (address);
    function governance() external view returns (address);
    function controller() external view returns (address);
    function underlying() external view returns (address);
    function strategy() external view returns (address);

    function setStrategy(address _strategy) external;
    function setVaultFractionToInvest(uint256 numerator, uint256 denominator) external;

    function deposit(uint256 amountWei) external;
    function depositFor(uint256 amountWei, address holder) external;

    function withdrawAll() external;
    function withdraw(uint256 numberOfShares) external;
    function getPricePerFullShare() external view returns (uint256);

    function underlyingBalanceWithInvestmentForHolder(address holder) view external returns (uint256);

    // hard work should be callable only by the controller (by the hard worker) or by governance
    function doHardWork() external;
}

// File: contracts/strategies/idle/IdleFinanceStrategy.sol

pragma solidity 0.5.16;












contract IdleFinanceStrategy is IStrategy, RewardTokenProfitNotifier {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event ProfitsNotCollected(address);
    event Liquidating(address, uint256);

    IERC20 public underlying;
    address public idleUnderlying;
    uint256 public virtualPrice;
    IIdleTokenHelper public idleTokenHelper;

    address public vault;
    address public comp;
    address public idle;

    address[] public uniswapComp;
    address[] public uniswapIdle;

    address public uniswapRouterV2;

    bool public sellComp = true;
    bool public sellIdle = true;
    bool public claimAllowed = true;
    bool public protected;

    // These tokens cannot be claimed by the controller
    mapping (address => bool) public unsalvagableTokens;

    modifier restricted() {
        require(msg.sender == vault || msg.sender == address(controller()) || msg.sender == address(governance()),
            "The sender has to be the controller or vault or governance");
        _;
    }

    modifier updateVirtualPrice() {
        if (protected) {
            require(virtualPrice <= idleTokenHelper.getRedeemPrice(idleUnderlying), "virtual price is higher than needed");
        }
        _;
        virtualPrice = idleTokenHelper.getRedeemPrice(idleUnderlying);
    }

    constructor(
        address _storage,
        address _underlying,
        address _idleUnderlying,
        address _vault,
        address _comp,
        address _idle,
        address _weth,
        address _uniswap
    ) RewardTokenProfitNotifier(_storage, _idle) public {
        comp = _comp;
        idle = _idle;
        underlying = IERC20(_underlying);
        idleUnderlying = _idleUnderlying;
        vault = _vault;
        uniswapRouterV2 = _uniswap;
        protected = true;

        // set these tokens to be not salvagable
        unsalvagableTokens[_underlying] = true;
        unsalvagableTokens[_idleUnderlying] = true;
        unsalvagableTokens[_comp] = true;
        unsalvagableTokens[_idle] = true;

        uniswapComp = [_comp, _weth, _idle];
        uniswapIdle = [_idle, _weth, _underlying];

        idleTokenHelper = IIdleTokenHelper(0x2a55D81c83595eF38f5C0Dafc63A8dA6D7B0a9b8);
        virtualPrice = idleTokenHelper.getRedeemPrice(idleUnderlying);
    }

    function depositArbCheck() public view returns(bool) {
        return true;
    }

    /**
    * The strategy invests by supplying the underlying token into IDLE.
    */
    function investAllUnderlying() public restricted updateVirtualPrice {
        uint256 balance = underlying.balanceOf(address(this));
        underlying.safeApprove(address(idleUnderlying), 0);
        underlying.safeApprove(address(idleUnderlying), balance);
        IIdleTokenV3_1(idleUnderlying).mintIdleToken(balance, true, address(0));
    }

    /**
    * Exits IDLE and transfers everything to the vault.
    */
    function withdrawAllToVault() external restricted updateVirtualPrice {
        withdrawAll();
        IERC20(address(underlying)).safeTransfer(vault, underlying.balanceOf(address(this)));
    }

    /**
    * Withdraws all from IDLE
    */
    function withdrawAll() internal {
        uint256 balance = IERC20(idleUnderlying).balanceOf(address(this));

        // this automatically claims the crops
        IIdleTokenV3_1(idleUnderlying).redeemIdleToken(balance);

        liquidateComp();
        liquidateIdle();
    }

    function withdrawToVault(uint256 amountUnderlying) public restricted {
        // this method is called when the vault is missing funds
        // we will calculate the proportion of idle LP tokens that matches
        // the underlying amount requested
        uint256 balanceBefore = underlying.balanceOf(address(this));
        uint256 totalIdleLpTokens = IERC20(idleUnderlying).balanceOf(address(this));
        uint256 totalUnderlyingBalance = totalIdleLpTokens.mul(virtualPrice).div(1e18);
        uint256 ratio = amountUnderlying.mul(1e18).div(totalUnderlyingBalance);
        uint256 toRedeem = totalIdleLpTokens.mul(ratio).div(1e18);
        IIdleTokenV3_1(idleUnderlying).redeemIdleToken(toRedeem);
        uint256 balanceAfter = underlying.balanceOf(address(this));
        underlying.safeTransfer(vault, balanceAfter.sub(balanceBefore));
    }

    /**
    * Withdraws all assets, liquidates COMP, and invests again in the required ratio.
    */
    function doHardWork() public restricted updateVirtualPrice {
        if (claimAllowed) {
            claim();
        }
        liquidateComp();
        liquidateIdle();

        // this updates the virtual price
        investAllUnderlying();

        // state of supply/loan will be updated by the modifier
    }

    /**
    * Salvages a token.
    */
    function salvage(address recipient, address token, uint256 amount) public onlyGovernance {
        // To make sure that governance cannot come in and take away the coins
        require(!unsalvagableTokens[token], "token is defined as not salvagable");
        IERC20(token).safeTransfer(recipient, amount);
    }

    function claim() internal {
        IIdleTokenV3_1(idleUnderlying).redeemIdleToken(0);
    }

    function liquidateComp() internal {
        if (!sellComp) {
            // Profits can be disabled for possible simplified and rapid exit
            emit ProfitsNotCollected(comp);
            return;
        }

        // no profit notification, comp is liquidated to IDLE and will be notified there

        uint256 compBalance = IERC20(comp).balanceOf(address(this));
        if (compBalance > 0) {
            emit Liquidating(address(comp), compBalance);
            IERC20(comp).safeApprove(uniswapRouterV2, 0);
            IERC20(comp).safeApprove(uniswapRouterV2, compBalance);
            // we can accept 1 as the minimum because this will be called only by a trusted worker
            IUniswapV2Router02(uniswapRouterV2).swapExactTokensForTokens(
                compBalance, 1, uniswapComp, address(this), block.timestamp
            );
        }
    }

    function liquidateIdle() internal {
        if (!sellIdle) {
            // Profits can be disabled for possible simplified and rapid exit
            emit ProfitsNotCollected(idle);
            return;
        }

        uint256 rewardBalance = IERC20(idle).balanceOf(address(this));
        notifyProfitInRewardToken(rewardBalance);

        uint256 idleBalance = IERC20(idle).balanceOf(address(this));
        if (idleBalance > 0) {
            emit Liquidating(address(idle), idleBalance);
            IERC20(idle).safeApprove(uniswapRouterV2, 0);
            IERC20(idle).safeApprove(uniswapRouterV2, idleBalance);
            // we can accept 1 as the minimum because this will be called only by a trusted worker
            IUniswapV2Router02(uniswapRouterV2).swapExactTokensForTokens(
                idleBalance, 1, uniswapIdle, address(this), block.timestamp
            );
        }
    }

    /**
    * Returns the current balance. Ignores COMP that was not liquidated and invested.
    */
    function investedUnderlyingBalance() public view returns (uint256) {
        // NOTE: The use of virtual price is okay for appreciating assets inside IDLE,
        // but would be wrong and exploitable if funds were lost by IDLE, indicated by
        // the virtualPrice being greater than the token price.
        if (protected) {
            require(virtualPrice <= idleTokenHelper.getRedeemPrice(idleUnderlying), "virtual price is higher than needed");
        }
        uint256 invested = IERC20(idleUnderlying).balanceOf(address(this)).mul(virtualPrice).div(1e18);
        return invested.add(IERC20(underlying).balanceOf(address(this)));
    }

    function setLiquidation(bool _sellComp, bool _sellIdle, bool _claimAllowed) public onlyGovernance {
        sellComp = _sellComp;
        sellIdle = _sellIdle;
        claimAllowed = _claimAllowed;
    }

    function setProtected(bool _protected) public onlyGovernance {
        protected = _protected;
    }
}

// File: contracts/strategies/idle/IdleStrategyUSDTMainnet.sol

pragma solidity 0.5.16;


/**
* Adds the mainnet addresses to the PickleStrategy3Pool
*/
contract IdleStrategyUSDTTestnet is IdleFinanceStrategy {

    // token addresses
    address constant public __weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address constant public __usdt = address(0x87c74f9a8af61e2Ef33049E299dF919a17792115);
    address constant public __uniswap = address(0x2a55D81c83595eF38f5C0Dafc63A8dA6D7B0a9b8);
    address constant public __idleUnderlying= address(0x2a55D81c83595eF38f5C0Dafc63A8dA6D7B0a9b8);
    address constant public __comp = address(0x5d4046DBDAfdbB5B34861a266186e31d5F8B4920);
    address constant public __idle = address(0xf86303f85747fFDb873DA97FFD15D40A6Ac075b8);

    constructor(
        address _storage,
        address _vault
    )
    IdleFinanceStrategy(
        _storage,
        __usdt,
        __idleUnderlying,
        _vault,
        __comp,
        __idle,
        __weth,
        __uniswap
    )
    public {
    }

    function changeVault(address _vault) public onlyGovernance {
        vault = _vault;
    }

}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}