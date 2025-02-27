pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
  function totalSupply() public view returns (uint256);

  function balanceOf(address _who) public view returns (uint256);

  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transfer(address _to, uint256 _value) public returns (bool);

  function approve(address _spender, uint256 _value)
    public returns (bool);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private balances;

  mapping (address => mapping (address => uint256)) private allowed;

  uint256 private totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Internal function that mints an amount of the token and assigns it to
   * an account. This encapsulates the modification of balances such that the
   * proper events are emitted.
   * @param _account The account that will receive the created tokens.
   * @param _amount The amount that will be created.
   */
  function _mint(address _account, uint256 _amount) internal {
    require(_account != 0);
    totalSupply_ = totalSupply_.add(_amount);
    balances[_account] = balances[_account].add(_amount);
    emit Transfer(address(0), _account, _amount);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param _account The account whose tokens will be burnt.
   * @param _amount The amount that will be burnt.
   */
  function _burn(address _account, uint256 _amount) internal {
    require(_account != 0);
    require(_amount <= balances[_account]);

    totalSupply_ = totalSupply_.sub(_amount);
    balances[_account] = balances[_account].sub(_amount);
    emit Transfer(_account, address(0), _amount);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account, deducting from the sender&#39;s allowance for said account. Uses the
   * internal _burn function.
   * @param _account The account whose tokens will be burnt.
   * @param _amount The amount that will be burnt.
   */
  function _burnFrom(address _account, uint256 _amount) internal {
    require(_amount <= allowed[_account][msg.sender]);

    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    allowed[_account][msg.sender] = allowed[_account][msg.sender].sub(_amount);
    _burn(_account, _amount);
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(
    ERC20 _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/BurnableToken.sol

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is StandardToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  /**
   * @dev Burns a specific amount of tokens from the target address and decrements allowance
   * @param _from address The address which you want to send tokens from
   * @param _value uint256 The amount of token to be burned
   */
  function burnFrom(address _from, uint256 _value) public {
    _burnFrom(_from, _value);
  }

  /**
   * @dev Overrides StandardToken._burn in order for burn and burnFrom to emit
   * an additional Burn event.
   */
  function _burn(address _who, uint256 _value) internal {
    super._burn(_who, _value);
    emit Burn(_who, _value);
  }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: contracts/ClarityCrowdsale.sol

contract Token is ERC20, BurnableToken {}

contract ClarityCrowdsale is Ownable {

  using SafeMath for uint256;
  using SafeERC20 for Token;

  uint256 constant DECIMALS = 10 ** uint256(18);

  Token token;

  mapping (address => uint8) public whitelist;

  mapping (address => uint256) public contributions;

  mapping (address => uint256) public tokensBought;

  mapping (address => bool) public admins;

  address public founderAddress = address(0);
  uint256 public founderFunds = 0;

  address public advisorAddress = address(0);
  uint256 public advisorFunds = 0;

  uint256 public totalContributed = 0;

  uint256 public softcap = 8333 ether;

  uint256 public startTime;
  uint256 public endTime;

  bool public initialized = false;
  bool public finalized = false;

  struct Tier {
    uint256 amount;
    uint16 rate;
  }

  Tier[] public tiers;

  event AdminAdded(address indexed addr, address owner);
  event AdminRemoved(address indexed addr, address owner);
  event AddressWhitelisted(address indexed addr, address admin);
  event ContributionLevelSet(address indexed addr, uint8 lvl, address admin);
  event AdvisorSet(address indexed addr, address owner);
  event FounderSet(address indexed addr, address owner);
  event FounderFundsWithdrawn(address founder, uint256 amount);
  event AdvisorFundsWithdrawn(address advisor, uint256 amount);
  event TokensBought(address indexed buyer, uint256 tokens, uint256 eth);

  modifier onlyAdmins() {
    require(admins[msg.sender] == true || msg.sender == owner);
    _;
  }

  modifier onlyFounder() {
    require(msg.sender == founderAddress);
    _;
  }

   modifier onlyAdvisor() {
    require(msg.sender == advisorAddress);
    _;
  }

  modifier onlyWhitelisted() {
    require(whitelist[msg.sender] > 0);
    _;
  }

  modifier onlyWhitelistedProxy(address _addr) {
    require(whitelist[_addr] > 0);
    _;
  }

  modifier onlyUpToAllowedContribution() {
    if (whitelist[msg.sender] == 1) {
      require(contributions[msg.sender].add(msg.value) < 71.5 ether);
    }

    if (whitelist[msg.sender] == 2) {
      require(contributions[msg.sender].add(msg.value) < 214 ether);
    }
    _;
  }

  modifier onlyUpToAllowedContributionProxy(address _addr) {
    if (whitelist[_addr] == 1) {
      require(contributions[_addr].add(msg.value) < 71.5 ether);
    }

    if (whitelist[_addr] == 2) {
      require(contributions[_addr].add(msg.value) < 214 ether);
    }
    _;
  }

  modifier onlyWhenInitialized() {
    require(initialized == true);
    _;
  }

  modifier onlyWhenCrowdsaleIsOpen() {
    require(now >= startTime && now <= endTime);
    _;
  }

  modifier onlyAfterSoftCapReached() {
    require(totalContributed >= softcap);
    _;
  }

  modifier onlyWhenRefundable() {
    require(
      now > endTime &&
      totalContributed < softcap &&
      tokensBought[msg.sender] > 0 &&
      contributions[msg.sender] > 0
    );
    _;
  }

  modifier onlyWhenSaleHasEnded() {
    require(now > endTime);
    _;
  }

  modifier onlyWhenNotFinalized() {
    require(finalized == false);
    _;
  }

  constructor(Token _token, address _founder, address _advisor) public {

    token = Token(_token);
    founderAddress = _founder;
    emit FounderSet(_founder, msg.sender);
    advisorAddress = _advisor;
    emit AdvisorSet(_advisor, msg.sender);

    tiers.push(Tier(uint256(10000000).mul(DECIMALS), 3000));
    tiers.push(Tier(uint256(20000000).mul(DECIMALS), 2000));
    tiers.push(Tier(uint256(30000000).mul(DECIMALS), 1500));
    tiers.push(Tier(uint256(40000000).mul(DECIMALS), 1000));
    tiers.push(Tier(uint256(90000000).mul(DECIMALS), 700));
  }

  function init(uint256 _startTime, uint256 _endTime) external onlyOwner returns (bool) {
    require(token.balanceOf(address(this)) == 220000000 * 10**18);
    startTime = _startTime;
    endTime = _endTime;
    initialized = true;
  }

  function () public payable  {
    buyTokens();
  }

  /**
  * @dev function that sells available tokens
  */
  function buyTokens() public payable onlyWhenInitialized onlyWhenCrowdsaleIsOpen onlyWhitelisted onlyUpToAllowedContribution {
    _allocateTokens(msg.sender);
  }

  function buyTokensByProxy(address _addr) public payable onlyAdmins onlyWhenInitialized onlyWhenCrowdsaleIsOpen onlyWhitelistedProxy(_addr) onlyUpToAllowedContributionProxy(_addr) {
    _allocateTokens(_addr);
  }

  function _allocateTokens(address _addr) private {
    uint256 tokens = _getTokenAmount();
    contributions[_addr] = contributions[_addr].add(msg.value);
    tokensBought[_addr] = tokensBought[_addr].add(tokens);
    totalContributed = totalContributed.add(msg.value);
    uint256 tenPercent = msg.value.mul(10).div(100);
    advisorFunds = advisorFunds.add(tenPercent);
    founderFunds = founderFunds.add(msg.value.sub(tenPercent));
    emit TokensBought(_addr, tokens, msg.value);
    token.safeTransfer(_addr, tokens);
  }

  function _getTokenAmount() private returns (uint256) {
    uint256 txBalance = msg.value;
    uint256 tokenAmount = 0;
    for (uint8 i = 0; i < tiers.length; i++) {
      uint256 tokensToBuy = txBalance.mul(tiers[i].rate);

      if (tiers[i].amount > tokensToBuy) {
        tiers[i].amount = tiers[i].amount.sub(tokensToBuy);
        tokenAmount = tokenAmount.add(tokensToBuy);
        return tokenAmount;
      }

      uint256 price = tiers[i].amount.div(tiers[i].rate);
      tokenAmount = tokenAmount.add(tiers[i].amount);
      tiers[i].amount = 0;
      txBalance = txBalance.sub(price);
    }

    return tokenAmount;
  }

  function whitelistAddress(address _addr) external onlyAdmins returns (bool) {
    whitelist[_addr] = 1;
    emit AddressWhitelisted(_addr, msg.sender);
    return true;
  }

  function whitelistAddresses(address[] _addrs) external onlyAdmins returns (bool) {
    for (uint8 i = 0; i < _addrs.length; i++) {
      whitelist[_addrs[i]] = 1;
      emit AddressWhitelisted(_addrs[i], msg.sender);
    }
    return true;
  }

  function setContributionLevel(address _addr, uint8 _lvl) external onlyAdmins returns (bool) {
    require(_lvl < 4);
    whitelist[_addr] = _lvl;
    emit ContributionLevelSet(_addr, _lvl, msg.sender);
    return true;
  }

  function withdrawFounderFunds() external onlyFounder onlyAfterSoftCapReached returns (bool) {
    uint256 amount = founderFunds;
    founderFunds = 0;
    msg.sender.transfer(amount);
    emit FounderFundsWithdrawn(msg.sender, amount);
    return true;
  }

  function withdrawAdvisorFunds() external onlyAdvisor onlyAfterSoftCapReached returns (bool) {
    uint256 amount = advisorFunds;
    advisorFunds = 0;
    msg.sender.transfer(amount);
    emit AdvisorFundsWithdrawn(msg.sender, amount);
    return true;
  }

  function claimRefund() external onlyWhenRefundable returns (bool) {
    uint256 _tokensBought = tokensBought[msg.sender];
    tokensBought[msg.sender] = 0;

    uint256 _contributions = contributions[msg.sender];
    contributions[msg.sender] = 0;

    token.safeTransferFrom(msg.sender, address(this), _tokensBought);
    msg.sender.transfer(_contributions);
    return true;
  }

  function setFounderAddress(address _addr) external onlyOwner returns (bool) {
    founderAddress = _addr;
    emit FounderSet(_addr, msg.sender);
    return true;
  }

  function setAdvisorAddress(address _addr) external onlyOwner returns (bool) {
    advisorAddress = _addr;
    emit AdvisorSet(_addr, msg.sender);
    return true;
  }

  function addAdmin(address _addr) external onlyOwner returns (bool) {
    admins[_addr] = true;
    emit AdminAdded(_addr, msg.sender);
    return true;
  }

  function removeAdmin(address _addr) external onlyOwner returns (bool) {
    admins[_addr] = false;
    emit AdminRemoved(_addr, msg.sender);
    return true;
  }

  function finalize() external onlyOwner onlyWhenSaleHasEnded onlyAfterSoftCapReached onlyWhenNotFinalized returns (bool) {
    uint256 _tokensLeft = token.balanceOf(address(this));
    token.burn(_tokensLeft);

    uint256 _founderFunds = founderFunds;
    founderFunds = 0;

    uint256 _advisorFunds = advisorFunds;
    advisorFunds = 0;

    finalized = true;

    founderAddress.transfer(_founderFunds);
    advisorAddress.transfer(_advisorFunds);
  }
}