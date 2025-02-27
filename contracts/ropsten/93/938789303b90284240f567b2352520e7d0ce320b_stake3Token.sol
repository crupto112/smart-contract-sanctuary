pragma solidity ^0.4.24;


// ----------------------------------------------------------------------------
// &#39;Stake POS&#39; CROWDSALE token contract
//
// Deployed to : pragma solidity ^0.4.24;


// ----------------------------------------------------------------------------
// &#39;Stake POS&#39; CROWDSALE token contract
//
// Deployed to : 0x938789303b90284240f567b2352520e7d0ce320b
// Symbol      : STAKE3
// Name        : STAKE3 Token
// Total supply: 60,000,000
// Decimals    : 18


contract IMigrationContract {
    function migrate(address addr, uint256 nas) public returns (bool success);
}

/* taking ideas from FirstBlood token */
contract SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSubtract(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMult(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


/*  ERC 20 token */
contract StandardToken is Token, SafeMath {

/*
    function transfer(address _to, uint256 _value) public returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }
*/
    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to `to` account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint256 tokens) public returns (bool success) {
        balances[msg.sender] = safeSubtract(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }



    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    //
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success) {
        balances[from] = safeSubtract(balances[from], tokens);
        allowed[from][msg.sender] = safeSubtract(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

/*
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
    }
*/



    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract stake3Token is StandardToken {

    // metadata
    string  public constant name = "STAKE3 Token";
    string  public constant symbol = "STAKE3";
    uint256 public constant decimals = 18;
    string  public version = "1.0";

    // contracts
    address public ethFundDeposit;          // deposit address for ETH for STAKE Team.
    address public newContractAddr;         // the new contract for stake token updates;

    // crowdsale parameters
    bool    public isFunding;                // switched to true in operational state
    uint256 public fundingStartBlock;
    uint256 public fundingStopBlock;

    uint256 public currentSupply;           // current supply tokens for sale
    uint256 public tokenRaised = 0;         // the number of total sold token
    uint256 public tokenMigrated = 0;     // the number of total transferted token
    uint256 public tokenExchangeRate = 400;             // 400 Stake tokens per 1 ETH

    // events
    event AllocateToken(address indexed _to, uint256 _value);   // allocate token for private sale;
    event IssueToken(address indexed _to, uint256 _value);      // issue token for public sale;
    event IncreaseSupply(uint256 _value);
    event DecreaseSupply(uint256 _value);
    event IncreaseTotalSupply(uint256 _value);
    event DecreaseTotalSupply(uint256 _value);
    
    event Migrate(address indexed _to, uint256 _value);

    // format decimals.
    function formatDecimals(uint256 _value) internal pure returns (uint256 ) {
        return _value * 10 ** decimals;
    }

    // constructor
    constructor (
        address _ethFundDeposit,
        uint256 _currentSupply) public
    {
        ethFundDeposit = _ethFundDeposit;

        isFunding = false;                           //controls pre through crowdsale state
        fundingStartBlock = 0;
        fundingStopBlock = 0;

        currentSupply = formatDecimals(_currentSupply);
        totalSupply = formatDecimals(60000000);
        require(currentSupply < totalSupply);
    }

    modifier isOwner()  { require(msg.sender == ethFundDeposit); _; }

    /// @dev set the token&#39;s tokenExchangeRate,
    function setTokenExchangeRate(uint256 _tokenExchangeRate) isOwner external {
        require (_tokenExchangeRate != 0);
        require (_tokenExchangeRate != tokenExchangeRate);

        tokenExchangeRate = _tokenExchangeRate;
    }

    /// @dev increase the token&#39;s current supply
    function increaseSupply (uint256 _value) isOwner external {
        uint256 value = formatDecimals(_value);
        require(value + currentSupply < totalSupply);
        currentSupply = safeAdd(currentSupply, value);
        emit IncreaseSupply(value);
    }

    /// @dev decrease the token&#39;s current supply
    function decreaseSupply (uint256 _value) isOwner external {
        uint256 value = formatDecimals(_value);
        require(value + tokenRaised < currentSupply);
        currentSupply = safeSubtract(currentSupply, value);
        emit DecreaseSupply(value);
    }

    /// @dev increase the token&#39;s total supply
    function increaseTotalSupply (uint256 _value) isOwner external {
        uint256 value = formatDecimals(_value);
        currentSupply = safeAdd(totalSupply, value);
        emit IncreaseTotalSupply(value);
    }

    /// @dev decrease the token&#39;s total supply
    function decreaseTotalSupply (uint256 _value) isOwner external {
        uint256 value = formatDecimals(_value);
        require (totalSupply - value > currentSupply);

        totalSupply = safeSubtract(currentSupply, value);
        emit DecreaseTotalSupply(value);
    }


    /// @dev turn on the funding state
    function startFunding (uint256 _fundingStartBlock, uint256 _fundingStopBlock) isOwner external {
        require (!isFunding);
        require (_fundingStartBlock <= _fundingStopBlock);
        require (block.number <= _fundingStartBlock);

        fundingStartBlock = _fundingStartBlock;
        fundingStopBlock = _fundingStopBlock;
        isFunding = true;
    }

    /// @dev turn off the funding state
    function stopFunding() isOwner external {
        require (isFunding);
        isFunding = false;
    }

    /// @dev set a new contract for recieve the tokens (for update contract)
    function setMigrateContract(address _newContractAddr) isOwner external {
        require(_newContractAddr != newContractAddr);
        newContractAddr = _newContractAddr;
    }

    /// @dev set a new owner.
    function changeOwner(address _newFundDeposit) isOwner() external {
        require (_newFundDeposit != address(0x0));
        ethFundDeposit = _newFundDeposit;
    }

    /// sends the tokens to new contract
    function migrate() external {
        require(!isFunding);
        require(newContractAddr != address(0x0));

        uint256 tokens = balances[msg.sender];
        require (tokens != 0);

        balances[msg.sender] = 0;
        tokenMigrated = safeAdd(tokenMigrated, tokens);

        IMigrationContract newContract = IMigrationContract(newContractAddr);
        require (newContract.migrate(msg.sender, tokens));

        emit Migrate(msg.sender, tokens);               // log it
    }

    /// @dev sends ETH to Nebulas team
    function transferETH() isOwner external {
    //    require (this.balance != 0);
        require (address(ethFundDeposit).balance != 0);
    
    //    require (ethFundDeposit.send(this.balance));
        require (ethFundDeposit.send(address(ethFundDeposit).balance));
     
    }

    /// @dev allocates tokens to pre-sell address.
    function allocateToken (address _addr, uint256 _eth) isOwner external {
        require (_eth != 0);
        require (_addr != address(0x0));

        uint256 tokens = safeMult(formatDecimals(_eth), tokenExchangeRate);
        require (tokens + tokenRaised < currentSupply);

        tokenRaised = safeAdd(tokenRaised, tokens);
        balances[_addr] += tokens;

        emit AllocateToken(_addr, tokens);  // logs token issued
    }

    /// buys the tokens
    function () payable public{
        require (isFunding);
        require (msg.value != 0);

        require (block.number >= fundingStartBlock);
        require (block.number <= fundingStopBlock);
         

        uint256 tokens = safeMult(msg.value, tokenExchangeRate);
        require (tokens + tokenRaised <= currentSupply);

        tokenRaised = safeAdd(tokenRaised, tokens);
        balances[msg.sender] += tokens;

        emit IssueToken(msg.sender, tokens);  // logs token issued
    }
}