pragma solidity 0.4.24;


library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns(uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns(uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns(uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns(uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20Basic {
  function transfer(address to, uint256 value) public returns(bool);
}

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
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

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract payment is Ownable {
  event EtherPay(uint256 balance, address[] receivers, uint256[] shares);
  event TokenTransfer(address token, address owner, uint256 _eth);

  using SafeMath for uint256;

  address public feeWallet;
  uint256 public adminFee = 1 * (10 ** 15);

  constructor(address _adminWallet) public{
    require(_adminWallet != address(0));
    feeWallet = _adminWallet;
  }

  function() public payable {

  }

  function payEther(address[] receivers, uint[] shares) external payable{
    require(receivers.length == shares.length);
    require(msg.value > adminFee.mul(shares.length));
    uint256 _eth = msg.value;
    uint256 totalshares = 0;
    
    for (uint256 i = 0; i < receivers.length; i++){
      require(shares[i] > 0);
      totalshares = totalshares.add(shares[i]);
    }

    for (uint256 j = 0; j < receivers.length; j++){
      uint256 eth_ = _eth.mul(shares[j]).div(totalshares).sub(adminFee);
      receivers[j].transfer(eth_);
    }

    emit EtherPay(_eth, receivers, shares);
    feeWallet.transfer(adminFee.mul(receivers.length));
  }
  function transferToken(address token, uint256 amount) external onlyOwner{
    require(amount > 0);
    require(ERC20Basic(token).transfer(msg.sender, amount));
    emit TokenTransfer(token, msg.sender, amount);
  }
  function updatefee(uint256 _eth) external onlyOwner{
    adminFee = _eth;
  }
  function updateWallet(address _address) external onlyOwner{
    feeWallet = _address;
  }
}