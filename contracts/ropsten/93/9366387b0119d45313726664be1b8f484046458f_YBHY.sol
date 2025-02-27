/*
Implements EIP20 token standard: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
.*/


pragma solidity ^0.4.21;

contract EIP20 {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    // solhint-disable-next-line no-simple-event-func-name
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract YBHY is EIP20 {

    address owner;
    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    mapping (address => uint256) public availableInventory;

    string public name;
    uint8 public decimals;
    string public symbol;

    function YBHY() public {
        owner = msg.sender;
        totalSupply = 1000000000;           // Update total supply
        balances[msg.sender] = totalSupply; // Give the creator all initial tokens
        name = &#39;Bhired Test Token v2.0&#39;;    // Set the name for display purposes
        decimals = 0;                       // Amount of decimals for display purposes
        symbol = &#39;YBHY&#39;;                    // Set the symbol for display purposes
    }

    function whoOwnsYou() public view returns(address){
        return owner;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        availableInventory[_to] += _value;
        allowed[_to][_to] += _value;
        emit Approval(_to, _to, _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function getAllowance(address _owner, address _spender) public view returns (uint256 remaining) {
        if(_owner == _spender) {
            return balances[_owner];
        } else {
            return allowed[_owner][_spender];
        }
    }

    function addAllowance(address _owner, address _spender, uint256 _value) public returns (bool success) {
        require(balances[_owner] >= _value && availableInventory[_owner] >= _value);
        allowed[_owner][_spender] += _value;
        availableInventory[_owner] -= _value;
        emit Approval(owner, _spender, _value);
        return true;
    }

    function reduceAllowance(address _owner, address _spender, uint256 _value) public returns (bool success) {
        allowed[_owner][_spender] -= _value;
        availableInventory[_owner] += _value;
        emit Approval(owner, _spender, _value);
        return true;
    }

    function revokeAllowance(address _owner, address _spender) public returns (bool success) {
        availableInventory[_owner] += allowed[_owner][_spender];
        allowed[_owner][_spender] = 0;
        emit Approval(owner, _spender, 0);
        return true;
    }

    function payFromAllowance(address _from, address _spender, address _to, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value && allowed[_from][_spender] >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        
        allowed[_from][_spender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

}