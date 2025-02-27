pragma solidity ^0.4.22;

// File: contracts\Controlled.sol

contract Controlled {
    /// @notice The address of the controller is the only address that can call
    ///  a function with this modifier
    modifier onlyController { require(msg.sender == controller); _; }

    address public controller;

    constructor() public { controller = msg.sender;}

    /// @notice Changes the controller of the contract
    /// @param _newController The new controller of the contract
    function changeController(address _newController) public onlyController {
        controller = _newController;
    }
}

// File: contracts\TokenController.sol

/// @dev The token controller contract must implement these functions
contract TokenController {
    /// @notice Called when `_owner` sends ether to the MiniMe Token contract
    /// @param _owner The address that sent the ether to create tokens
    /// @return True if the ether is accepted, false if it throws
    function proxyPayment(address _owner) public payable returns(bool);

    /// @notice Notifies the controller about a token transfer allowing the
    ///  controller to react if desired
    /// @param _from The origin of the transfer
    /// @param _to The destination of the transfer
    /// @param _amount The amount of the transfer
    /// @return False if the controller does not authorize the transfer
    function onTransfer(address _from, address _to, uint _amount) public returns(bool);

    /// @notice Notifies the controller about an approval allowing the
    ///  controller to react if desired
    /// @param _owner The address that calls `approve()`
    /// @param _spender The spender in the `approve()` call
    /// @param _amount The amount in the `approve()` call
    /// @return False if the controller does not authorize the approval
    function onApprove(address _owner, address _spender, uint _amount) public
        returns(bool);
}

// File: contracts\MiniMeToken.sol

/**
   Based on version https://github.com/Giveth/minime/commit/ea04d950eea153a04c51fa510b068b9dded390cb
   Changed by Lykke:
   - MiniMeTokenFactory contract and createCloneToken() methid not used and removed
   - code style aligned to Solidity 0.4.22:
        - uint256 -> uint256
        - emit events
        - if (.. || .. && ..) expressions on one line
        - constant -> view for functions
        - 4-space indentation
        - token-name-function -> constructor
 */

/*
    Copyright 2016, Jordi Baylina

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/// @title MiniMeToken Contract
/// @author Jordi Baylina
/// @dev This token contract&#39;s goal is to make it easy for anyone to clone this
///  token using the token distribution at a given block, this will allow DAO&#39;s
///  and DApps to upgrade their features in a decentralized manner without
///  affecting the original token
/// @dev It is ERC20 compliant, but still needs to under go further testing.

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 _amount, address _token, bytes _data) public;
}

/// @dev The actual token contract, the default controller is the msg.sender
///  that deploys the contract, so usually this token will be deployed by a
///  token controller contract, which Giveth will call a "Campaign"
contract MiniMeToken is Controlled {

    string public name;                //The Token&#39;s name: e.g. DigixDAO Tokens
    uint8 public decimals;             //Number of decimals of the smallest unit
    string public symbol;              //An identifier: e.g. REP
    string public version = "MMT_0.2"; //An arbitrary versioning scheme


    /// @dev `Checkpoint` is the structure that attaches a block number to a
    ///  given value, the block number attached is the one that last changed the
    ///  value
    struct  Checkpoint {

        // `fromBlock` is the block number that the value was generated from
        uint128 fromBlock;

        // `value` is the amount of tokens at a specific block number
        uint128 value;
    }

    // `parentToken` is the Token address that was cloned to produce this token;
    //  it will be 0x0 for a token that was not cloned
    MiniMeToken public parentToken;

    // `parentSnapShotBlock` is the block number from the Parent Token that was
    //  used to determine the initial distribution of the Clone Token
    uint256 public parentSnapShotBlock;

    // `creationBlock` is the block number that the Clone Token was created
    uint256 public creationBlock;

    // `balances` is the map that tracks the balance of each address, in this
    //  contract when the balance changes the block number that the change
    //  occurred is also included in the map
    mapping (address => Checkpoint[]) balances;

    // `allowed` tracks any extra transfer rights as in all ERC20 tokens
    mapping (address => mapping (address => uint256)) allowed;

    // Tracks the history of the `totalSupply` of the token
    Checkpoint[] totalSupplyHistory;

    // Flag that determines if the token is transferable or not.
    bool public transfersEnabled;

////////////////
// Constructor
////////////////

    /// @notice Constructor to create a MiniMeToken
    /// @param _parentToken Address of the parent token, set to 0x0 if it is a
    ///  new token
    /// @param _parentSnapShotBlock Block of the parent token that will
    ///  determine the initial distribution of the clone token, set to 0 if it
    ///  is a new token
    /// @param _tokenName Name of the new token
    /// @param _decimalUnits Number of decimals of the new token
    /// @param _tokenSymbol Token Symbol for the new token
    /// @param _transfersEnabled If true, tokens will be able to be transferred
    constructor(
        address _parentToken,
        uint256 _parentSnapShotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    ) public {
        name = _tokenName;                                 // Set the name
        decimals = _decimalUnits;                          // Set the decimals
        symbol = _tokenSymbol;                             // Set the symbol
        parentToken = MiniMeToken(_parentToken);
        parentSnapShotBlock = _parentSnapShotBlock;
        transfersEnabled = _transfersEnabled;
        creationBlock = block.number;
    }


///////////////////
// ERC20 Methods
///////////////////

    /// @notice Send `_amount` tokens to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);
        doTransfer(msg.sender, _to, _amount);
        return true;
    }

    /// @notice Send `_amount` tokens to `_to` from `_from` on the condition it
    ///  is approved by `_from`
    /// @param _from The address holding the tokens being transferred
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return True if the transfer was successful
    function transferFrom(address _from, address _to, uint256 _amount
    ) public returns (bool success) {

        // The controller of this contract can move tokens around at will,
        //  this is important to recognize! Confirm that you trust the
        //  controller of this contract, which in most situations should be
        //  another open source smart contract or 0x0
        if (msg.sender != controller) {
            require(transfersEnabled);

            // The standard ERC 20 transferFrom functionality
            require(allowed[_from][msg.sender] >= _amount);
            allowed[_from][msg.sender] -= _amount;
        }
        doTransfer(_from, _to, _amount);
        return true;
    }

    /// @dev This is the actual transfer function in the token contract, it can
    ///  only be called by other functions in this contract.
    /// @param _from The address holding the tokens being transferred
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return True if the transfer was successful
    function doTransfer(address _from, address _to, uint256 _amount
    ) internal {

        if (_amount == 0) {
            emit Transfer(_from, _to, _amount);    // Follow the spec to louch the event when transfer 0
            return;
        }

        require(parentSnapShotBlock < block.number);

        // Do not allow transfer to 0x0 or the token contract itself
        require((_to != 0) && (_to != address(this)));

        // If the amount being transfered is more than the balance of the
        //  account the transfer throws
        uint256 previousBalanceFrom = balanceOfAt(_from, block.number);

        require(previousBalanceFrom >= _amount);

        // Alerts the token controller of the transfer
        if (isContract(controller)) {
            require(TokenController(controller).onTransfer(_from, _to, _amount));
        }

        // First update the balance array with the new value for the address
        //  sending the tokens
        updateValueAtNow(balances[_from], previousBalanceFrom - _amount);

        // Then update the balance array with the new value for the address
        //  receiving the tokens
        uint256 previousBalanceTo = balanceOfAt(_to, block.number);
        require(previousBalanceTo + _amount >= previousBalanceTo); // Check for overflow
        updateValueAtNow(balances[_to], previousBalanceTo + _amount);

        // An event to make the transfer easy to find on the blockchain
        emit Transfer(_from, _to, _amount);

    }

    /// @param _owner The address that&#39;s balance is being requested
    /// @return The balance of `_owner` at the current block
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

    /// @notice `msg.sender` approves `_spender` to spend `_amount` tokens on
    ///  its behalf. This is a modified version of the ERC20 approve function
    ///  to be a little bit safer
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _amount The amount of tokens to be approved for transfer
    /// @return True if the approval was successful
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender,0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));

        // Alerts the token controller of the approve function call
        if (isContract(controller)) {
            require(TokenController(controller).onApprove(msg.sender, _spender, _amount));
        }

        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /// @dev This function makes it easy to read the `allowed[]` map
    /// @param _owner The address of the account that owns the token
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens of _owner that _spender is allowed
    ///  to spend
    function allowance(address _owner, address _spender
    ) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /// @notice `msg.sender` approves `_spender` to send `_amount` tokens on
    ///  its behalf, and then a function is triggered in the contract that is
    ///  being approved, `_spender`. This allows users to use their tokens to
    ///  interact with contracts in one function call instead of two
    /// @param _spender The address of the contract able to transfer the tokens
    /// @param _amount The amount of tokens to be approved for transfer
    /// @return True if the function call was successful
    function approveAndCall(address _spender, uint256 _amount, bytes _extraData
    ) public returns (bool success) {
        require(approve(_spender, _amount));

        if (isContract(_spender)) {
            ApproveAndCallFallBack(_spender).receiveApproval(
                msg.sender,
                _amount,
                this,
                _extraData
            );
        }

        return true;
    }

    /// @dev This function makes it easy to get the total number of tokens
    /// @return The total number of tokens
    function totalSupply() public view returns (uint256) {
        return totalSupplyAt(block.number);
    }


////////////////
// Query balance and totalSupply in History
////////////////

    /// @dev Queries the balance of `_owner` at a specific `_blockNumber`
    /// @param _owner The address from which the balance will be retrieved
    /// @param _blockNumber The block number when the balance is queried
    /// @return The balance at `_blockNumber`
    function balanceOfAt(address _owner, uint256 _blockNumber) public view
        returns (uint256) {

        // These next few lines are used when the balance of the token is
        //  requested before a check point was ever created for this token, it
        //  requires that the `parentToken.balanceOfAt` be queried at the
        //  genesis block for that token as this contains initial balance of
        //  this token
        if ((balances[_owner].length == 0)
            || (balances[_owner][0].fromBlock > _blockNumber)) {
            if (address(parentToken) != 0) {
                return parentToken.balanceOfAt(_owner, min(_blockNumber, parentSnapShotBlock));
            } else {
                // Has no parent
                return 0;
            }

        // This will return the expected balance during normal situations
        } else {
            return getValueAt(balances[_owner], _blockNumber);
        }
    }

    /// @notice Total amount of tokens at a specific `_blockNumber`.
    /// @param _blockNumber The block number when the totalSupply is queried
    /// @return The total amount of tokens at `_blockNumber`
    function totalSupplyAt(uint256 _blockNumber) public view returns(uint256) {

        // These next few lines are used when the totalSupply of the token is
        //  requested before a check point was ever created for this token, it
        //  requires that the `parentToken.totalSupplyAt` be queried at the
        //  genesis block for this token as that contains totalSupply of this
        //  token at this block number.
        if ((totalSupplyHistory.length == 0)
            || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
            if (address(parentToken) != 0) {
                return parentToken.totalSupplyAt(min(_blockNumber, parentSnapShotBlock));
            } else {
                return 0;
            }

        // This will return the expected totalSupply during normal situations
        } else {
            return getValueAt(totalSupplyHistory, _blockNumber);
        }
    }

////////////////
// Generate and destroy tokens
////////////////

    /// @notice Generates `_amount` tokens that are assigned to `_owner`
    /// @param _owner The address that will be assigned the new tokens
    /// @param _amount The quantity of tokens generated
    /// @return True if the tokens are generated correctly
    function generateTokens(address _owner, uint256 _amount
    ) public onlyController returns (bool) {
        uint256 curTotalSupply = totalSupply();
        require(curTotalSupply + _amount >= curTotalSupply); // Check for overflow
        uint256 previousBalanceTo = balanceOf(_owner);
        require(previousBalanceTo + _amount >= previousBalanceTo); // Check for overflow
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
        updateValueAtNow(balances[_owner], previousBalanceTo + _amount);
        emit Transfer(0, _owner, _amount);
        return true;
    }


    /// @notice Burns `_amount` tokens from `_owner`
    /// @param _owner The address that will lose the tokens
    /// @param _amount The quantity of tokens to burn
    /// @return True if the tokens are burned correctly
    function destroyTokens(address _owner, uint256 _amount
    ) onlyController public returns (bool) {
        uint256 curTotalSupply = totalSupply();
        require(curTotalSupply >= _amount);
        uint256 previousBalanceFrom = balanceOf(_owner);
        require(previousBalanceFrom >= _amount);
        updateValueAtNow(totalSupplyHistory, curTotalSupply - _amount);
        updateValueAtNow(balances[_owner], previousBalanceFrom - _amount);
        emit Transfer(_owner, 0, _amount);
        return true;
    }

////////////////
// Enable tokens transfers
////////////////


    /// @notice Enables token holders to transfer their tokens freely if true
    /// @param _transfersEnabled True if transfers are allowed in the clone
    function enableTransfers(bool _transfersEnabled) public onlyController {
        transfersEnabled = _transfersEnabled;
    }

////////////////
// Internal helper functions to query and set a value in a snapshot array
////////////////

    /// @dev `getValueAt` retrieves the number of tokens at a given block number
    /// @param checkpoints The history of values being queried
    /// @param _block The block number to retrieve the value at
    /// @return The number of tokens being queried
    function getValueAt(Checkpoint[] storage checkpoints, uint256 _block
    ) view internal returns (uint256) {
        if (checkpoints.length == 0) return 0;

        // Shortcut for the actual value
        if (_block >= checkpoints[checkpoints.length-1].fromBlock)
            return checkpoints[checkpoints.length-1].value;
        if (_block < checkpoints[0].fromBlock) return 0;

        // Binary search of the value in the array
        uint256 min = 0;
        uint256 max = checkpoints.length-1;
        while (max > min) {
            uint256 mid = (max + min + 1) / 2;
            if (checkpoints[mid].fromBlock <= _block) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }
        return checkpoints[min].value;
    }

    /// @dev `updateValueAtNow` used to update the `balances` map and the
    ///  `totalSupplyHistory`
    /// @param checkpoints The history of data being updated
    /// @param _value The new number of tokens
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint256 _value
    ) internal  {
        if ((checkpoints.length == 0) || (checkpoints[checkpoints.length - 1].fromBlock < block.number)) {
            Checkpoint storage newCheckPoint = checkpoints[checkpoints.length++];
            newCheckPoint.fromBlock = uint128(block.number);
            newCheckPoint.value = uint128(_value);
        } else {
            Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length-1];
            oldCheckPoint.value = uint128(_value);
        }
    }

    /// @dev Internal function to determine if an address is a contract
    /// @param _addr The address being queried
    /// @return True if `_addr` is a contract
    function isContract(address _addr) view internal returns(bool) {
        uint256 size;
        if (_addr == 0) return false;
        assembly {
            size := extcodesize(_addr)
        }
        return size>0;
    }

    /// @dev Helper function to return a min betwen the two uints
    function min(uint256 a, uint256 b) pure internal returns (uint256) {
        return a < b ? a : b;
    }

    /// @notice The fallback function: If the contract&#39;s controller has not been
    ///  set to 0, then the `proxyPayment` method is called which relays the
    ///  ether and creates tokens as described in the token controller contract
    function () public payable {
        require(isContract(controller));
        require(TokenController(controller).proxyPayment.value(msg.value)(msg.sender));
    }

//////////
// Safety Methods
//////////

    /// @notice This method can be used by the controller to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) public onlyController {
        if (_token == 0x0) {
            controller.transfer(address(this).balance);
            return;
        }

        MiniMeToken token = MiniMeToken(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(controller, balance);
        emit ClaimedTokens(_token, controller, balance);
    }

////////////////
// Events
////////////////

    event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount
    );

}

// File: contracts\ERC677.sol

/**
 * @title ERC677 transferAndCall token implementation.
 * @dev See https://github.com/ethereum/EIPs/issues/677 for specification and discussion.
 */
contract ERC677 is MiniMeToken {

    /**
     * @dev ERC677 constructor is just a fallback to the MiniMeToken constructor
     */
    constructor(address _parentToken, uint _parentSnapShotBlock, string _tokenName, uint8 _decimalUnits, string _tokenSymbol, bool _transfersEnabled) public MiniMeToken(
        _parentToken, _parentSnapShotBlock, _tokenName, _decimalUnits, _tokenSymbol, _transfersEnabled) {
    }

    /**
     * @notice `msg.sender` transfers `_amount` to `_to` contract and then tokenFallback() function is triggered in the `_to` contract.
     * @param _to The address of the contract able to receive the tokens
     * @param _amount The amount of tokens to be transferred
     * @param _data The payload to be treated by `_to` contract in corresponding format
     * @return True if the function call was successful
     */
    function transferAndCall(address _to, uint _amount, bytes _data) public returns (bool) {
        require(transfer(_to, _amount));

        emit Transfer(msg.sender, _to, _amount, _data);

        // call receiver
        if (isContract(_to)) {
            ERC677Receiver(_to).tokenFallback(msg.sender, _amount, _data);
        }

        return true;
    }

    /**
     * @notice Raised when transfer to contract has been completed
     */
    event Transfer(address indexed _from, address indexed _to, uint256 _amount, bytes _data);
}

/**
 * @title Receiver interface for ERC677 transferAndCall
 * @dev See https://github.com/ethereum/EIPs/issues/677 for specification and discussion.
 */
contract ERC677Receiver {
    function tokenFallback(address _from, uint _amount, bytes _data) public;
}

// File: contracts\Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
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

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: contracts\PrimeToken.sol

/**
 * To simplify flow and deploying process we don&#39;t use MiniMe controller approach, instead we extend it through inheritance.
 * See https://github.com/Giveth/minime for details of MiniMe.
 *
 * We use Ownable approach implementation from https://github.com/OpenZeppelin/zeppelin-solidity.
 *
 * This is a mintable token. Minting is performed through generateTokens() function of base MiniMe contract.
 * After minting is done controller must call finishMinting() function to enable transfers and to lock generating new tokens forever.
 * Also, we mix "Controlled" ans "Ownable" approaches (which are actually the same) to bring in double-layered authorization.
 * At the start controller and owner are the same. Controller can generate tokens and set locks.
 * After finishing minting controller loses all it&#39;s abilities, but owner remains able to burn tokens from the special pre-defined address.
 * Such an approach is intended to increase security and investor confidence.
 */

/**
 * @title Smart Containers PRIMETEST token contract
 */
contract PrimeToken is ERC677, Ownable {

    // mapping for locking certain addresses
    mapping(address => uint256) public lockups;

    event LockedTokens(address indexed _holder, uint256 _lockup);

    // burnable address
    address public burnable;

    /**
     * @dev Smarc constructor just parametrizes the ERC677 -> MiniMeToken constructor
     */
    constructor() public ERC677(
        0x0,                      // no parent token
        0,                        // no parent token - no snapshot block number
        "PrimeTestToken",             // Token name
        18,                       // Decimals
        "PRIMETEST",                  // Symbol
        false                     // Disable transfers for time of minting
    ) {}

    uint256 public constant maxSupply = 150 * 1000 * 1000 * 10**uint256(18); // use the smallest denomination unit to operate with token amounts

    /**
     * @notice Sets the locks of an array of addresses.
     * @dev Must be called while minting (enableTransfers = false). Sizes of `_holder` and `_lockups` must be the same.
     * @param _holders The array of investor addresses
     * @param _lockups The array of timestamps until which corresponding address must be locked
     */
    function setLocks(address[] _holders, uint256[] _lockups) public onlyController {
        require(_holders.length == _lockups.length);
        require(_holders.length < 256);
        require(transfersEnabled == false);

        for (uint8 i = 0; i < _holders.length; i++) {
            address holder = _holders[i];
            uint256 lockup = _lockups[i];

            // make sure lockup period can not be overwritten once set
            require(lockups[holder] == 0);

            lockups[holder] = lockup;

            emit LockedTokens(holder, lockup);
        }
    }

    /**
     * @notice Finishes minting process and throws out the controller.
     * @dev Owner can not finish minting without setting up address for burning tokens.
     * @param _burnable The address to burn tokens from
     */
    function finishMinting(address _burnable) public onlyController() {
        require(_burnable != address(0x0)); // burnable address must be set
        assert(totalSupply() <= maxSupply); // ensure hard cap
        enableTransfers(true); // turn-on transfers
        changeController(address(0x0)); // ensure no new tokens will be created
        burnable = _burnable; // set burnable address
    }

    modifier notLocked(address _addr) {
        require(now >= lockups[_addr]);
        _;
    }

    /**
     * @notice Send `_amount` tokens to `_to` from `msg.sender`
     * @dev We override transfer function to add lockup check
     * @param _to The address of the recipient
     * @param _amount The amount of tokens to be transferred
     * @return Whether the transfer was successful or not
     */
    function transfer(address _to, uint256 _amount) public notLocked(msg.sender) returns (bool success) {
        return super.transfer(_to, _amount);
    }

    /**
     * @notice Send `_amount` tokens to `_to` from `_from` on the condition it is approved by `_from`
     * @dev We override transfer function to add lockup check
     * @param _from The address holding the tokens being transferred
     * @param _to The address of the recipient
     * @param _amount The amount of tokens to be transferred
     * @return True if the transfer was successful
     */
    function transferFrom(address _from, address _to, uint256 _amount) public notLocked(_from) returns (bool success) {
        return super.transferFrom(_from, _to, _amount);
    }

    /**
     * @notice Burns `_amount` tokens from pre-defined "burnable" address.
     * @param _amount The amount of tokens to burn
     * @return True if the tokens are burned correctly
     */
    function burn(uint256 _amount) public onlyOwner returns (bool) {
        require(burnable != address(0x0)); // burnable address must be set

        uint256 currTotalSupply = totalSupply();
        uint256 previousBalance = balanceOf(burnable);

        require(currTotalSupply >= _amount);
        require(previousBalance >= _amount);

        updateValueAtNow(totalSupplyHistory, currTotalSupply - _amount);
        updateValueAtNow(balances[burnable], previousBalance - _amount);

        emit Transfer(burnable, 0, _amount);

        return true;
    }
}