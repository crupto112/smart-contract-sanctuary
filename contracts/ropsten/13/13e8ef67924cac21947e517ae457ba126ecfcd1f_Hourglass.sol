/**
 *Submitted for verification at Etherscan.io on 2019-07-06
*/

/**
 *created on 2019-07-07
*/

pragma solidity ^0.4.20;

/*
* RANLYTICS ICO contract
* Offers dividend distribution based returns for all holders
* 300,000 tokens on offer, no more can be created once quota filled
* If company gets baught out, ICO Token holders will get paid their share of the buyout 
* via a final payout
*/

contract Hourglass {
    /*=================================
    =            MODIFIERS            =
    =================================*/
    // only people with tokens
    modifier onlyholders() {
        require(myTokens() > 0);
        _;
    }
    
    // only people with profits
    modifier hasDividends() {
        require(myDividends() > 0);
        _;
    }
    
    // administrators can:
    // -> change the name of the contract
    // -> change the name of the token
    // -> widthdraw the ICO funds
    // they CANNOT:
    // -> disable dividend withdrawals
    // -> kill the contract
    // -> change the price of tokens
    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrators[_customerAddress]);
        _;
    }
    
    
    /*==============================
    =            EVENTS            =
    ==============================*/
    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted
    );
    
    event onWithdraw(
        address indexed customerAddress,
        uint256 ethereumWithdrawn
    );
    
     event onCompanyWithdraw(
        address indexed customerAddress,
        uint256 ethereumWithdrawn
    );
    
    // ERC20 spec
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );
    
    
    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    string public name = "RANlytics Round C ICO";
    string public symbol = "RANC";
    uint8 constant public decimals = 18;
 
    address constant internal companyAccount_ = 0x237363EaED022fe9BdE3cc7C2e219E003bB92aAa;
    
   /*================================
    =            DATASETS            =
    ================================*/
    // amount of shares for each address (scaled number)
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => int256) internal payoutsTo_;
    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;
    
    // administrator list (see above on what they can do)
    mapping(address => bool) public administrators;
    
    //lock further investments
    bool internal locked_ = false;

    //raised eth for the company to Withdraw
    uint256 internal notWithdrawn_ = 0;
    
    /*=======================================
    =            PUBLIC FUNCTIONS            =
    =======================================*/
    /*
    * -- APPLICATION ENTRY POINTS --  
    */
    function Hourglass()
        public
    {
        // add administrators here
        administrators[0x237363EaED022fe9BdE3cc7C2e219E003bB92aAa] = true;

    }
    
     
    /**
     * Converts all incoming ethereum to tokens for the caller
     */
    function buy()
        public
        payable
    {
        purchaseTokens(msg.value);
    }
    
    /**
     * Fallback function to handle ethereum that was send straight to the contract
     * Unfortunately we cannot use a referral address this way.
     */
    function()
        payable
        public
    {
        purchaseTokens(msg.value);
    }
    

    /**
     * Withdraws all of the callers earnings.
     */
    function withdraw()
        hasDividends()
        public
    {
        // setup data
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(); 
        
        // update dividend tracker
        payoutsTo_[_customerAddress] +=  (int256) (_dividends);
        
        
        // lambo delivery service
        _customerAddress.transfer(_dividends);
        
        // fire event
        onWithdraw(_customerAddress, _dividends);
    }
    
    /**
     * Withdraws all of the company Invetment eth.
     */
    function companyWithdraw()
        onlyAdministrator()
        public
    {
        require(notWithdrawn_ > 0);
        
        // Send investment funds to company
        companyAccount_.transfer(notWithdrawn_);
        
        notWithdrawn_ = 0;
        
        // fire event
        onCompanyWithdraw(companyAccount_, notWithdrawn_);
    }
    
    /**
     * Transfer tokens from the caller to a new holder.
     */
    function transfer(address _toAddress, uint256 _amountOfTokens)
        onlyholders()
        public
        returns(bool)
    {
        // setup
        address _customerAddress = msg.sender;
        
        // make sure we have the requested tokens
        // also disables transfers until ambassador phase is over
        // ( we dont want whale premines )
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        
        // withdraw all outstanding dividends first
        if(myDividends() > 0) withdraw();

        // exchange tokens
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _amountOfTokens);
        
        // update dividend trackers
        payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens / 1e18);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _amountOfTokens / 1e18);
        
        
        // fire event
        Transfer(_customerAddress, _toAddress, _amountOfTokens);
        
        // ERC20
        return true;
       
    }
    

    /*----------  ADMINISTRATOR ONLY FUNCTIONS  ----------*/

    /**
     * In case one of us dies, we need to replace ourselves.
     */
    function setAdministrator(address _identifier, bool _status)
        onlyAdministrator()
        public
    {
        administrators[_identifier] = _status;
    }
    
    function payDividend()
        onlyAdministrator()
        payable
        public
    {
        profitPerShare_ = SafeMath.add(profitPerShare_, (msg.value * 1e18 ) / tokenSupply_);    
    }
    
    /**
     * If we want to rebrand, we can.
     */
    function setName(string _name)
        onlyAdministrator()
        public
    {
        name = _name;
    }
    
    /**
     * If we want to rebrand, we can.
     */
    function setSymbol(string _symbol)
        onlyAdministrator()
        public
    {
        symbol = _symbol;
    }

    
    /*----------  HELPERS AND CALCULATORS  ----------*/
    /**
     * Method to view the current Ethereum stored in the contract
     * Example: totalEthereumBalance()
     */
    function totalEthereumBalance()
        public
        view
        returns(uint)
    {
        return this.balance;
    }
    
    /**
     * Retrieve the total token supply.
     */
    function totalSupply()
        public
        view
        returns(uint256)
    {
        return tokenSupply_;
    }
    
    /**
     * Retrieve the tokens owned by the caller.
     */
    function myTokens()
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }
    
       /**
     * Retrieve the dividends owned by the caller.
     */ 
    function myDividends() 
        public 
        view 
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return  dividendsOf(_customerAddress) ;
    }
    
    /**
     * Retrieve the token balance of any single address.
     */
    function balanceOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        return tokenBalanceLedger_[_customerAddress];
    }
    
    /**
     * Retrieve the dividend balance of any single address.
     */
    function dividendsOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        return (uint256) ((int256)(profitPerShare_  * tokenBalanceLedger_[_customerAddress] / 1e18 ) - payoutsTo_[_customerAddress]) ;
    }
    
    /**
     * Retrieve the eth balance of the funds not withdrawn yet.
     */
    function companyBalance()
        view
        public
        returns(uint256)
    {
        return notWithdrawn_;
    }

   
    
    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/
    function purchaseTokens(uint256 _incomingEthereum)
        internal
        returns(uint256)
    {
        require(!locked_);
        // data setup
        address _customerAddress = msg.sender;
        uint256 _amountOfTokens = _incomingEthereum * 20;
 
        // no point in continuing execution if OP is a hacker
        // prevents overflow in the case that the ICO somehow magically starts being used by everyone in the world
        // (or hackers)
        // and yes we know that the safemath function automatically rules out the "greater than" equation.
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));
        
        // we can&#39;t give people infinite ethereum
        if(tokenSupply_ > 0){
            
            // add tokens to the pool
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
        
        } else {
            // add tokens to the pool
            tokenSupply_ = _amountOfTokens;
        }
        
        //set the invest lock if more than 300000 tokens are allocated
        //we will accept the last buyers order and allocate those shares over the 300000 shares allocated for this ICO. 
        if (tokenSupply_ > 300000*1e18) locked_ = true;
        
        // update circulating supply & the ledger address for the customer
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        
        notWithdrawn_ += _incomingEthereum;
        
        // fire event
        onTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens);
        
        return _amountOfTokens;
    }

   
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}