pragma solidity ^0.4.25;


contract RiseOfNations {
    using SafeMath for *;
    
    /*=================================
    =            MODIFIERS            =
    =================================*/
    modifier onlyAdministrator() {
        address _customerAddress = msg.sender;
        require(administrator_ == _customerAddress);
        _;
    }
	
	modifier roundRunning() {
	    require(now >= roundStart_);	// start time reached
		require(
		    now <= roundEnd_  			// transaction is in time
		    ||
			roundStart_ == roundEnd_ &&	            // round was initialized, ready to flip a card
			roundStart_ != 0 && roundEnd_ != 0	    // first round not initialized
		);
		_;
	}
    
    
    /*=================================
    =             EVENTS              =
    =================================*/
    event onCardFlip (
        uint8 index,
        address indexed owner,
        uint256 price,
		uint256 time,
		uint256 timeEnd
    );
	
	event onRoundEnd (
		uint256 roundStart,
		uint256 nextPot
	);
    
    
    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    // attack timers
    uint256 internal baseTenMinutes_ = 10 minutes;
    uint256 internal baseOneMinutes_ = 2 minutes;
    
    // base price for a card
    uint256 internal initialPrice_ = 0.005 ether;
	
	// fund fee
	uint256 internal fundFee_ = 3;	// 3% of each card flip
    
    // warmup phase countdown after starting new round
    uint256 internal countdown_ = 5 minutes;
    
    // game shall be activated manually for the first round.
    // Also if the wargame shall be upgraded (with new contract deployment),
    // it can be deactivated, which will users not allow to start the next round,
    // but they can still withdraw the pot. Rest goes to the fund
    bool internal contractActivated_ = false;
    
    
    /*=================================
    =             DATASET             =
    =================================*/
    address internal administrator_;    // administrator address
    address internal currentWinner_;    // this rounds winner
	address internal fundAddress_;      // fund address
	uint256 internal etherToFund_;		// value send to fund
	uint8 internal currentHero_;		// index of nation that is (currently) the winner
    
    // Cards
    Card[12] internal nations_;         // always 12 Cards
    
    // timer
    uint256 internal roundEnd_;           // end of round time stamp
    uint256 internal roundStart_;         // start of round time stamp
    
    
    /*=================================
    =   PRIVATE / INTERNAL FUNCTIONS  =
    =================================*/
    function initCard(uint8 _index, Card storage _nation)
		internal 
	{
		uint256 _baseTenMinutes = uint256((_index/4) + 1) * baseTenMinutes_;
		uint256 _column = (_index%4);
		uint256 _baseOneMinutes = _column * baseOneMinutes_;
		
		// set time for each card
		_nation.time = _baseTenMinutes + _baseOneMinutes;
        
    }
    
    /**
     * Set up cards for a new round by resetting price and owner of each card
     */
    function resetCards() 
		internal 
	{
        for (uint8 i = 0; i < nations_.length; i++) {
            Card storage _nation = nations_[i];
            
            // reset Cards
            _nation.price = initialPrice_;  // reset price
            _nation.owner = address(this);  // reset owner to this contract
        }
    }
    
    /**
     * Set new values of a card when flipping it
     */
    function setCard(Card storage _nation, address _buyer)
        internal 
    {
        // reset Cards
        _nation.price = _nation.price * 2;  // double the price
        _nation.owner = _buyer;             // set owner equal to buyer
    }
	
	function setSatoShi()
		internal
	{
		uint8 _random = randomSatoShiTime();
		Card storage _satoShi = nations_[11];
		
		// lucky one
		if (_random == 12) {
			_satoShi.time = 8 minutes;	// Sato-Shi is pure winrar, and so are you
		// get timer 10-36 minutes
		} else {
			initCard(_random, _satoShi);
		}
	}
	
	function setNewRound(uint256 _nextPot) 
		internal
	{
		// set globale variables and therefore start a new round
		resetCards();
		currentWinner_ = address(0x0);
		roundStart_ = now + countdown_;
		roundEnd_   = roundStart_;
		etherToFund_ = 0;
		
		// trigger round end event
		emit onRoundEnd(roundStart_, _nextPot);
	}
    
    /**
     * Buy a card by index for the given value of eth
     */
    function _buyNationInternal(uint8 _index, uint256 _value)
		roundRunning()
        internal
    {		
        Card storage _nation = nations_[_index];
        
        address _buyer = msg.sender;    // new card owner
        address _owner = _nation.owner; // old card owner
        require(_buyer != _owner);      // restrict self flipping, use second account instead
        
        // 62,5 % to current owner
        // 6% to fund
        // 31,5% to pot
        uint256 _ethToOwner = _value.mul(5).div(8);     	// 62,5% owner
		uint256 _ethToFund = _value.mul(fundFee_).div(100);	// 3% of buy price
		etherToFund_ = etherToFund_.add(_ethToFund);		// add to global fund fee pool
        
        // if the buy order is for the first card, do nothing bcs contract already has the eth.
        // Instead pay fund at the end of the round
        if (_nation.price != initialPrice_) {
            _owner.transfer(_ethToOwner);   // instant delivery service
        }
        
        setCard(_nation, _buyer);   // set new values for the flipped card
		
		if (_index == 11) {
			setSatoShi();
		}
        
        // set globale variables
        currentWinner_ = _buyer;            // set buyer as current winner
		currentHero_ = _index;				// set index as current hero
        roundEnd_ = now + _nation.time;     // reset round end timer to nation time
        
        // trigger event
        emit onCardFlip(_index, _buyer, _nation.price, _nation.time, roundEnd_);
    }
	
	function deliveryService(uint256 _balance, uint256 _winnings, uint256 _fund) 
		internal 
	{
		// only deliver if there is eth left
		if (_balance > 0) {
			if (currentWinner_ != address(0x0)) {
				currentWinner_.transfer(_winnings);	// payout winner
				fundAddress_.transfer(_fund);		// payout fund
			}
		}
	}
	
	function randomSatoShiTime()
		internal 
		view 
		returns(uint8)
	{
        return uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 13);
    }
    
    
    /*=================================
    =         PUBLIC FUNCTIONS        =
    =================================*/
    constructor() 
        public
    {
        administrator_ = 0x6bca7e1EC8595B2f0F4D7Ff578F1D25643004825;
        fundAddress_ = 0x6bca7e1EC8595B2f0F4D7Ff578F1D25643004825;
        currentHero_ = 11;	// Sato-Shi!
		
		for (uint8 i = 0; i < nations_.length; i++) {
			Card storage _nation = nations_[i];
			initCard(i, _nation);
		}
        resetCards();
    }
    
    /**
     * Accept eth to increase the pot
     */
    function() public payable {}
    
    /**
     * Start a round. 
     */
    function startRound()
        public
    {
		// calculate percentages
        uint256 _balance  = address(this).balance;      		// 100%
		uint256 _fund     = etherToFund_;						// 3% total
		uint256 _nextPot  = _balance.sub(_fund).div(4);			// 25% for next rounds pot
        uint256 _winnings = _balance.sub(_fund).sub(_nextPot);  // 75% to winner
		
		// round has ended now
		if (now > roundEnd_ && 			// time lapsed, round over
			roundStart_ != roundEnd_	// each round starts with same start and end timer
			||
			roundStart_ == 0 && roundEnd_ == 0	// initialize first round
		){
		    // start new round
    		if (contractActivated_) {			
    			// payout winner and fund
    			deliveryService(_balance, _winnings, _fund);
    			setNewRound(_nextPot);
    		} else {	// payout winner and send rest to fund
    			// make sure winner is set
    			require(currentWinner_ != address(0x0));
    			deliveryService(_balance, _winnings, _balance.sub(_winnings));
    			
    			// reset values
    			etherToFund_ = 0;   // reset in case of underflow when starting new round (after contract reactivation)
    			currentWinner_ = address(0x0);
    		}	
		} else {
			// bcs we are nice, this ensures your transaction throws you an exception
			revert();
		}
    }
    
    /**
     * Buy the nation for the exact amount of eth 
     */
    function buyNation(uint8 _index)
        public
        payable
    {		
        Card storage _nation = nations_[_index];
        uint256 _value = msg.value;
        
        // nation is buyable for the exact amount of eth
        require(_value == _nation.price, "Nation has already been bought");
        
		_buyNationInternal(_index, _value);
    }
    
    /**
     * Buy the nation for up to the amount of eth 
     */
    function overbidNation(uint8 _index)
        public 
        payable
    {		
        Card storage _nation = nations_[_index];
        uint256 _value = msg.value;
        
        // nation is buyable for the exact amount of eth
        require(_value >= _nation.price, "Nation has already been bought");
        uint256 _nationValue = _nation.price; // set value equal to price of the nation
        
        _buyNationInternal(_index, _nationValue);
        
        // transfer back the overbid amount
        uint256 _excess = _value.sub(_nationValue);
		
		// payback
        if (_excess > 0) {
            address _buyer = msg.sender;
            _buyer.transfer(_excess);
        }
    }
    
    /* Views */
    function getNation(uint8 _index)
        public 
        view 
        returns(uint256, uint256, address)
    {
        Card storage _nation = nations_[_index];
        return (_nation.price, _nation.time, _nation.owner);
    }
	
	function getCurrentWinner()
		public
		view
		returns(address)
	{
		return currentWinner_;
	}
	
	function getCurrentHero()
		public
		view
		returns(uint8)
	{
		return currentHero_;
	}
	
	function getCurrentPot()
		public
		view
		returns(uint256)
	{
		// calculate percentages
        uint256 _balance  = address(this).balance;      		// 100%
		uint256 _fund     = etherToFund_;						// 3% total
		uint256 _nextPot  = _balance.sub(_fund).div(4);			// 25% for next rounds pot
        uint256 _winnings = _balance.sub(_fund).sub(_nextPot);  // 75% to winner
		
		// there is ETH in contract
		if (_balance > 0) {
			return _winnings;
		} else {
			return 0;
		}
	}
	
	function getRoundStart()
		public
		view
		returns(uint256)
	{
		return roundStart_;
	}
	
	function getRoundEnd()
		public
		view
		returns(uint256)
	{
		return roundEnd_;
	}
    
    /* Setter */
    function setGameStatus(bool _active) 
        onlyAdministrator()
        public
    {
        contractActivated_ = _active;
    }
    
    
    /*=================================
    =            DATA TYPES           =
    =================================*/
    struct Card {
        uint256 price;
        uint256 time;
        address owner;
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