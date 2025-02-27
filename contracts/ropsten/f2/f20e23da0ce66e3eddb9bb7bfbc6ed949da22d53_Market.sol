pragma solidity ^0.4.13;

interface IERC20 {
  function transfer(address _to, uint256 _amount) external returns (bool success);
  function transferFrom(address _from, address _to, uint256 _amount) external returns (bool success);
  function balanceOf(address _owner) constant external returns (uint256 balance);
  function approve(address _spender, uint256 _amount) external returns (bool success);
  function allowance(address _owner, address _spender) external constant returns (uint256 remaining);
  function approveAndCall(address _spender, uint256 _amount, bytes _extraData) external returns (bool success);
  function totalSupply() external constant returns (uint);
}

interface IPrizeCalculator {
    function calculatePrizeAmount(uint _predictionTotalTokens, uint _winOutputTotalTokens, uint _forecastTokens)
        pure
        external
        returns (uint);
}

interface IResultStorage {
    function getResult(bytes32 _predictionId) external returns (uint8);
}

library BytesHelper {

    function bytesToBytes32(bytes memory source) internal pure returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }
}

contract Owned {
    address public owner;
    address public executor;
    address public newOwner;
    address public newExecutor;
  
    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
        executor = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "User is not owner");
        _;
    }

    modifier onlyAllowed {
        require(msg.sender == owner || msg.sender == executor, "Not allowed");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function transferExecutorOwnership(address _newExecutor) public onlyOwner {
        newExecutor = _newExecutor;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }

     function acceptExecutorOwnership() public {
        require(msg.sender == newExecutor);
        emit OwnershipTransferred(executor, newExecutor);
        executor = newExecutor;
        newOwner = address(0);
    }
}

contract Market is Owned {
    using SafeMath for uint;
    using BytesHelper for bytes;

    event PredictionAdded(bytes32 id);
    event ForecastAdded(bytes32 predictionId, uint8 outcomeId, address user); 
    event PredictionStatusChanged(bytes32 predictionId, PredictionStatus oldStatus, PredictionStatus newStatus);
    event Refunded(address indexed owner, bytes32 predictionId, uint8 outcomeId, uint i, uint refundAmount);
    event PredictionResolved(bytes32 predictionId, uint8 winningOutcomeId);
    event PaidOut(bytes32 _predictionId, uint8 winningOutcomeId, uint index, address user, uint winAmount);

    enum PredictionStatus {
        NotSet,    // 0
        Published, // 1
        Resolved,  // 2
        Paused,    // 3
        Canceled   // 4
    }  
    
    struct Prediction {
        uint endTime;
        uint fee; // in WEIS       
        PredictionStatus status;    
        uint8 outcomesCount;
        mapping(uint8 => OutcomesForecasts) outcomes; 
        mapping(address => uint) userPayments;
        uint totalTokens;          
        uint totalForecasts; 
        uint totalTokensNeedForPayout;        
        address resultStorage;   
        address prizeCalculator;
    }

    struct OutcomesForecasts {    
        Forecast[] forecasts;
        uint totalTokens;
    }

    struct Forecast {    
        address user;
        uint amount;
        uint paidOut;
    }

    struct ForecastIndex {    
        bytes32 predictionId;
        uint8 outcomeId;
        uint positionIndex;
    }

    uint8 public constant version = 1;
    address public token;
    bool public paused = true;

    mapping(bytes32 => Prediction) public predictions;

    mapping(address => ForecastIndex[]) public walletPredictions;
  
    uint public totalFeeCollected;

    modifier notPaused() {
        require(paused == false, "Contract is paused");
        _;
    }

    modifier statusIsCanceled(bytes32 _predictionId) {
        require(predictions[_predictionId].status == PredictionStatus.Canceled, "Prediction is not canceled");
        _;
    }

    modifier validPrediction(bytes32 _id, uint _amount, uint8 _outcomeId) {
        require(predictions[_id].status == PredictionStatus.Published, "Prediction is not published");
        require(predictions[_id].endTime > now, "Prediction is over");
        require(predictions[_id].outcomesCount >= _outcomeId && _outcomeId > 0, "Outcome id is not in range");
        require(predictions[_id].fee < _amount, "Amount should be bigger then fee");
        _;
    }

    modifier senderIsToken() {
        require(msg.sender == address(token), "Sender is not token");
        _;
    }
    
    function initialize(address _token) external onlyOwner {
        token = _token;
        paused = false;
    }

    // TODO: for testing 1,1929412716 ,3,1,6,0,"0xca35b7d915458ef540ade6068dfe2f44e8fa733c" 
    function addPrediction(
        bytes32 _id,
        uint _endTime,
        uint _fee,
        uint8 _outcomesCount,  
        uint _totalTokens,   
        address _resultStorage, address _prizeCalculator) public onlyAllowed notPaused {

        predictions[_id].endTime = _endTime;
        predictions[_id].fee = _fee;
        predictions[_id].status = PredictionStatus.Published;  
        predictions[_id].outcomesCount = _outcomesCount;
        predictions[_id].totalTokens = _totalTokens;
        predictions[_id].resultStorage = _resultStorage;
        predictions[_id].prizeCalculator = _prizeCalculator;

        emit PredictionAdded(_id);
    }

    // TODO: for testing  1,"0xca35b7d915458ef540ade6068dfe2f44e8fa733c",15,1
    // TODO: reconfigure fallback from AIX token 
    function addForecast(bytes32 _predictionId, uint _amount, uint8 _outcomeId) 
            public 
            notPaused 
            validPrediction(_predictionId, _amount, _outcomeId) {
        
        // TODO: Add require that checks that user already forcasted
        // require(predictions[_predictionId].userPayments[msg.sender] == _amount, "User haven&#39;t paid for the forecast");

        uint amount = _amount.sub(predictions[_predictionId].fee);
        totalFeeCollected = totalFeeCollected.add(predictions[_predictionId].fee);
   
        predictions[_predictionId].totalTokens = predictions[_predictionId].totalTokens.add(amount);
        predictions[_predictionId].totalForecasts++;
        predictions[_predictionId].outcomes[_outcomeId].totalTokens = predictions[_predictionId].outcomes[_outcomeId].totalTokens.add(_amount);
        predictions[_predictionId].outcomes[_outcomeId].forecasts.push(Forecast(msg.sender, amount, 0));
       
        walletPredictions[msg.sender].push(ForecastIndex(_predictionId, _outcomeId, predictions[_predictionId].outcomes[_outcomeId].forecasts.length - 1));

        emit ForecastAdded(_predictionId, _outcomeId, msg.sender);
    }

    function changePredictionStatus(bytes32 _predictionId, PredictionStatus _status) 
            public 
            onlyAllowed {
        require(predictions[_predictionId].status != PredictionStatus.NotSet, "Prediction not exist");
        require(_status != PredictionStatus.Resolved, "Use resolve function");
        require(_status != PredictionStatus.Canceled, "Use cancel function");
        emit PredictionStatusChanged(_predictionId, predictions[_predictionId].status, _status);
        predictions[_predictionId].status = _status;            
    }

    function cancel(bytes32 _predictionId) public onlyAllowed {    
        emit PredictionStatusChanged(_predictionId, predictions[_predictionId].status, PredictionStatus.Canceled);
        predictions[_predictionId].status = PredictionStatus.Canceled;    
        predictions[_predictionId].totalTokensNeedForPayout = predictions[_predictionId].totalTokens;
    }

    function resolve(bytes32 _predictionId) public onlyAllowed {
        require(predictions[_predictionId].status == PredictionStatus.Published, "Prediction must be Published"); 
        require(predictions[_predictionId].endTime < now, "Prediction is not finished");

        uint8 winningOutcomeId = IResultStorage(predictions[_predictionId].resultStorage).getResult(_predictionId);
        require(winningOutcomeId <= predictions[_predictionId].outcomesCount && winningOutcomeId > 0, "OutcomeId is not valid");

        emit PredictionStatusChanged(_predictionId, predictions[_predictionId].status, PredictionStatus.Resolved);
        predictions[_predictionId].status = PredictionStatus.Resolved;    
        predictions[_predictionId].totalTokensNeedForPayout = predictions[_predictionId].totalTokens;
        
        emit PredictionResolved(_predictionId, winningOutcomeId);
    }

    function payout(bytes32 _predictionId, uint _indexFrom, uint _indexTo) public {
        require(predictions[_predictionId].status == PredictionStatus.Resolved, "Prediction should be resolved");

        uint8 winningOutcomeId = IResultStorage(predictions[_predictionId].resultStorage).getResult(_predictionId);

        require(_indexFrom <= _indexTo && _indexTo < predictions[_predictionId].outcomes[winningOutcomeId].forecasts.length, "Index is not valid");

        //predictions[_predictionId].totalTokens
        IPrizeCalculator calculator = IPrizeCalculator(predictions[_predictionId].prizeCalculator);
        
        for (uint i = _indexFrom; i <= _indexTo; i++) {
            Forecast storage forecast = predictions[_predictionId].outcomes[winningOutcomeId].forecasts[i];

            if (forecast.paidOut == 0) {
                uint winAmount = calculator.calculatePrizeAmount(
                    predictions[_predictionId].totalTokens,
                    predictions[_predictionId].outcomes[winningOutcomeId].totalTokens,
                    forecast.amount
                );
                assert(winAmount > 0);
                // assert(IERC20(token).transfer(forecast.user, winAmount));
                forecast.paidOut = winAmount;
                predictions[_predictionId].totalTokensNeedForPayout = predictions[_predictionId].totalTokensNeedForPayout.sub(winAmount);
                emit PaidOut(_predictionId, winningOutcomeId, i, forecast.user, winAmount);
            }
        }          
    }

    // Owner can refund users forecasts
    function refundUser(bytes32 _predictionId, uint8 _outcomeId, uint _indexFrom, uint _indexTo) public onlyAllowed {
        require (predictions[_predictionId].status != PredictionStatus.Resolved);
        
        performRefund(_predictionId, _outcomeId, _indexFrom, _indexTo);
    }
   
    // User can refund when status is CANCELED
    function refund(bytes32 _predictionId, uint8 _outcomeId, uint _indexFrom, uint _indexTo) public statusIsCanceled(_predictionId) {
        performRefund(_predictionId, _outcomeId, _indexFrom, _indexTo);
    }

    function performRefund(bytes32 _predictionId, uint8 _outcomeId, uint _indexFrom, uint _indexTo) private {
        require(_indexFrom <= _indexTo && _indexTo < predictions[_predictionId].outcomes[_outcomeId].forecasts.length, "Index is not valid");

        for (uint i = _indexFrom; i <= _indexTo; i++) {
            require(predictions[_predictionId].outcomes[_outcomeId].forecasts[i].paidOut == 0, "Already paid");  

            uint refundAmount = predictions[_predictionId].outcomes[_outcomeId].forecasts[i].amount;
            
            predictions[_predictionId].totalTokensNeedForPayout = predictions[_predictionId].totalTokensNeedForPayout.sub(refundAmount);
            predictions[_predictionId].outcomes[_outcomeId].totalTokens = predictions[_predictionId].outcomes[_outcomeId].totalTokens.sub(refundAmount);
            predictions[_predictionId].outcomes[_outcomeId].forecasts[i].paidOut = refundAmount;
                                                        
            assert(IERC20(token).transfer(predictions[_predictionId].outcomes[_outcomeId].forecasts[i].user, refundAmount)); 
            emit Refunded(predictions[_predictionId].outcomes[_outcomeId].forecasts[i].user, _predictionId, _outcomeId, i, refundAmount);
        }
    }

    /// Called by token contract after Approval: this.TokenInstance.methods.approveAndCall()
    function receiveApproval(address _from, uint _amountOfTokens, address _token, bytes _data) 
            external 
            senderIsToken
            notPaused {
        require(_amountOfTokens > 0, "amount should be > 0");
        require(_from != address(0), "not valid from");

        bytes32 predictionId = _data.bytesToBytes32();

        // Enable require below, to avoid cheating
        // require(predictions[predictionId].userPayments[_from] == 0, "User already forcasted this prediction");
        
        predictions[predictionId].userPayments[_from] = _amountOfTokens;

        // Transfer tokens from sender to this contract
        require(IERC20(_token).transferFrom(_from, address(this), _amountOfTokens), "Tokens transfer failed.");
    }

    //////////
    // View
    //////////
    function getForecast(bytes32 _predictionId, uint8 _outcomeId, uint _index) public view returns(address, uint, uint) {
        return (predictions[_predictionId].outcomes[_outcomeId].forecasts[_index].user,
            predictions[_predictionId].outcomes[_outcomeId].forecasts[_index].amount,
            predictions[_predictionId].outcomes[_outcomeId].forecasts[_index].paidOut);
    }

    //////////
    // Safety Methods
    //////////
    function () public payable {
        require(false);
    }

    function withdrawETH() external onlyOwner {
        owner.transfer(address(this).balance);
    }

    function withdrawTokens(uint _amount, address _token) external onlyOwner {
        IERC20(_token).transfer(owner, _amount);
    }

    function pause(bool _paused) external onlyOwner {
        paused = _paused;
    }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}