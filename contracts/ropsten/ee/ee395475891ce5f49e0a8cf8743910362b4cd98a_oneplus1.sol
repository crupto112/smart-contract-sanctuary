pragma solidity 0.4 .25;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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

/**
The development of the contract is entirely owned by the oneplus1 campaign, any copying of the source code is not legal.
*/
contract oneplus1 {
    //use of library of safe mathematical operations    
    using SafeMath
    for uint;
    // array containing information about beneficiaries
    mapping(address => uint) public userDeposit;
    //array containing information about the time of payment
    mapping(address => uint) public userTime;
    //array containing information on interest paid
    mapping(address => uint) public persentWithdraw;
    //fund fo transfer percent
    address public projectFund = 0x5765ad757423719B323E9BeCfE5d7fec2EDA1525;
    //wallet for a charitable foundation
    address public charityFund = 0x1ca5FEAb9630620a347053a24Eee6679345fC2Aa;
    //percentage deducted to the advertising fund
    uint projectPercent = 8;
    //percent for a charitable foundation
    uint public charityPercent = 1;
    //percent for a reserve fund
    uint public reservePercent = 1;
    //time through which you can take dividends
    uint public chargingTime = 1 hours;
    //start persent 0.25% per hour
    uint public startPercent = 250;
    uint public lowPersent = 300;
    uint public middlePersent = 350;
    uint public highPersent = 375;
    //interest rate increase steps
    uint public stepLow = 1000 ether;
    uint public stepMiddle = 2500 ether;
    uint public stepHigh = 5000 ether;
    uint public countOfInvestors = 0;
    uint public countOfCharity = 0;
    uint public countOfReserves = 0;
    // array of all investors
    address[] investors;
    
    modifier isIssetUser() {
        require(userDeposit[msg.sender] > 0, "Deposit not found");
        _;
    }

    modifier timePayment() {
        require(now >= userTime[msg.sender].add(chargingTime), "Too fast payout request");
        _;
    }

    //return of interest on the deposit
    function collectPercent() isIssetUser timePayment internal {
        require(address(this).balance > 0);
        //if the user received 200% or more of his contribution, delete the user
        if ((userDeposit[msg.sender].mul(2)) <= persentWithdraw[msg.sender]) {
            userDeposit[msg.sender] = 0;
            userTime[msg.sender] = 0;
            persentWithdraw[msg.sender] = 0;
        } else {
            uint payout = payoutAmount();
            userTime[msg.sender] = now;
            uint withdrawalAmount = persentWithdraw[msg.sender] + payout;
            // it will not allow more than 200% of deposit to be paid
            if(withdrawalAmount > userDeposit[msg.sender].mul(2)){ 
                payout = userDeposit[msg.sender].mul(2).sub(persentWithdraw[msg.sender]);
            }
            persentWithdraw[msg.sender] += payout;
            msg.sender.transfer(payout);
        }
    }
    
    function checkContractBalance() internal {
        //get contract balance
        uint balance = address(this).balance;
        // if balance is less than 0.89 ethers, distribute reserve Funds
        if (balance.sub(countOfReserves) < 0.89 ether) {
            //distribute reserve Funds
            distributeReserveFunds();
        }
    }
    
    function distributeReserveFunds() internal {
        uint reserveFundsCollector = 0;
        for(uint index = 0; index < investors.length; index++){
           address depositor = investors[index];
           // user exists but have not withdrawal amount
           if(userDeposit[depositor] != 0 && persentWithdraw[depositor] == 0){
               reserveFundsCollector++;
           }
        }
        
        for(index = 0; index < investors.length; index++){
           depositor = investors[index];
           uint eachInvestorsReservedPortion = countOfReserves.div(reserveFundsCollector);
           // user exists but have not withdrawal amount
           if(userDeposit[depositor] != 0 && persentWithdraw[depositor] == 0){
               depositor.transfer(eachInvestorsReservedPortion);
           }
        }
        
        if(address(this).balance > 0){
            charityFund.transfer(address(this).balance);
        }
    }

    //calculation of the current interest rate on the deposit
    function persentRate() public view returns(uint) {
        //get contract balance
        uint balance = address(this).balance;
        //calculate persent rate
        if (balance < stepLow) {
            return (startPercent);
        }
        if (balance >= stepLow && balance < stepMiddle) {
            return (lowPersent);
        }
        if (balance >= stepMiddle && balance < stepHigh) {
            return (middlePersent);
        }
        if (balance >= stepHigh) {
            return (highPersent);
        }
    }

    //refund of the amount available for withdrawal on deposit
    function payoutAmount() public view returns(uint) {
        uint persent = persentRate();
        uint rate = userDeposit[msg.sender].mul(persent).div(100000);
        uint interestRate = now.sub(userTime[msg.sender]).div(chargingTime);
        uint withdrawalAmount = rate.mul(interestRate);
        return (withdrawalAmount);
    }

    //make a contribution to the system
    function makeDeposit() private {
        if (msg.value > 0) {
            require(userDeposit[msg.sender] == 0, "Deposit already exists");
            require (msg.value == 1 ether, "investment should be more or less than 1 ether"); // 1 eth investment
                if (userDeposit[msg.sender] == 0) {
                    countOfInvestors += 1;
                }
                if (userDeposit[msg.sender] > 0 && now > userTime[msg.sender].add(chargingTime)) {
                    collectPercent();
                }
                userDeposit[msg.sender] = userDeposit[msg.sender].add(msg.value);
                userTime[msg.sender] = now;
                investors.push(msg.sender);
                //sending money for advertising
                projectFund.transfer(msg.value.mul(projectPercent).div(100));
                //sending money to charity
                uint charityMoney = msg.value.mul(charityPercent).div(100);
                countOfCharity+=charityMoney;
                charityFund.transfer(charityMoney);
                //sending money for reserves
                uint reserveMoney = msg.value.mul(reservePercent).div(100);
                countOfReserves += reserveMoney;
                // reserveFund.transfer(reserveMoney);
            // }
        } else {
            checkContractBalance();
            collectPercent();
        }
    }

    //return of deposit balance
    function returnDeposit() isIssetUser private {
        //userDeposit-persentWithdraw-(userDeposit*(8+1+1)/100)
        uint withdrawalAmount = userDeposit[msg.sender].sub(persentWithdraw[msg.sender]).sub(userDeposit[msg.sender].mul(projectPercent.add(charityPercent).add(reservePercent)).div(100));
        //check that the user&#39;s balance is greater than the interest paid
        require(userDeposit[msg.sender] > withdrawalAmount, &#39;You have already repaid your deposit&#39;);
        //delete user record
        userDeposit[msg.sender] = 0;
        userTime[msg.sender] = 0;
        persentWithdraw[msg.sender] = 0;
        msg.sender.transfer(withdrawalAmount);
    }

    function() external payable {
        //refund of remaining funds when transferring to a contract 0.00001001 ether
        if (msg.value == 0.00001001 ether) {
            returnDeposit();
        } else {
            makeDeposit();
        }
    }
    
}