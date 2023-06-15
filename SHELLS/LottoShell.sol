// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 

interface CoreRandomiser {
    function requestRandomUint256_(uint256 seed) external payable returns (uint256);
}

contract Lottery is ReentrancyGuard , Ownable{
    using SafeMath for uint256;
    
    CoreRandomiser private randomiser;
    address public stableCoin;
    
    uint256 public maxParticipants;
    uint256 public ticketPriceInWei;
    uint256 public OperatorShare;
    uint256 public duration;
    uint256 public roundCounter;

    struct Lotto{
        address[] participants;
        address[] winners;
        address[] losers;
        uint256 roundId;
        uint256 totalPool;
        uint256 participationTimeOver;
        uint256 startTime;
        uint256 endTime;
        uint256 distributionTime;
        bool fundsDistributed;
    }

    mapping(uint256 => Lotto) public lottoRounds;
    mapping(address => bool) public operators;

    event NewRoundStarted(uint256 indexed roundNumber, uint256 indexed Time);
    event ParitcationTimeOver(uint256 indexed roundNumber , uint256 Time);
    event PrizesDistributed(uint256 indexed roundNumber, uint256 indexed Time, uint256 indexed prizePool);
    
    constructor(
        uint256 _maxParticipants,
        uint256 _ticketPriceInWei,
        uint256 _feePercent,
        address _token,
        address randomiserAddress
    ){
        stableCoin = _token;
        maxParticipants = _maxParticipants;
        ticketPriceInWei = _ticketPriceInWei;
        OperatorShare = _feePercent;
        randomiser = CoreRandomiser(randomiserAddress);
        duration = uint256(7).mul(day());  
    }

    modifier isAllowed()  {
        _isAllowedOP();
        _;
    }

    function day()internal pure returns(uint256){
        return 86400;
    }

    function _isAllowedOP() internal view{
        require(_msgSender() == owner() || operators[_msgSender()] == true || msg.sender == address(this),"Do Not Have Operator Level Access to call the Function");
    }

    function randomUint(uint256 _seed) public returns (uint256) {
        return randomiser.requestRandomUint256_(_seed);
    }

    function addOperator(address operator) external isAllowed {
        require(operator != address(0), "Invalid operator address");
        operators[operator] = true;
    }

    function removeOperator(address operator) external isAllowed {
        require(operator != address(0), "Invalid operator address");
        operators[operator] = false;
    }

    function changeFeeToken(address token) external isAllowed {
        require(token != address(0), "Invalid token address");
        stableCoin = token;
    }

    function getFeeTokenAddress() public view returns(address){
        return stableCoin;
    }

    function changeFee(uint256 feeInWei) public isAllowed{
        OperatorShare = feeInWei;
    }

    function changeDuration(uint256 timeInSeconds) public isAllowed{
        duration = timeInSeconds;
    }

    function currentRoundId() public view returns(uint256){
        return roundCounter.sub(1);
    }

    function isParticipantForRound(uint256 roundNumber, address participant) public view returns (bool) {
        require(roundNumber <= roundCounter, "Invalid round number");
        address[] memory participants = lottoRounds[roundNumber].participants;
        for (uint256 i = 0; i < participants.length; i++) {
            if (participants[i] == participant) {
                return true;
            }
        }
        return false;
    }

    function isLoserForRound(uint256 roundNumber, address loser) public view returns (bool) {
        require(roundNumber <= roundCounter, "Invalid round number");
        address[] memory losers = lottoRounds[roundNumber].losers;
        for (uint256 i = 0; i < losers.length; i++) {
            if (losers[i] == loser) {
                return true;
            }
        }   
        return false;
    }

    function isWinnerForRound(uint256 roundNumber, address winner) public view returns (bool) {
        require(roundNumber <= roundCounter, "Invalid round number");
        address[] memory winners = lottoRounds[roundNumber].winners;
        for (uint256 i = 0; i < winners.length; i++) {
            if (winners[i] == winner) {
                return true;
            }
        }
        return false;
    }

    function startNewRound()public isAllowed{
        require(lottoRounds[currentRoundId()].fundsDistributed || block.timestamp >= lottoRounds[currentRoundId()].endTime, "Previous round is still ongoing");
        roundCounter.add(1);
        lottoRounds[roundCounter].roundId = roundCounter;
        lottoRounds[roundCounter].startTime = block.timestamp;
        lottoRounds[roundCounter].endTime = block.timestamp.add(duration);
        uint256 dur = day().mul(2);
        lottoRounds[roundCounter].participationTimeOver = block.timestamp.add(duration).sub(dur);
        emit NewRoundStarted(roundCounter, block.timestamp);
    }
    
    function buyTicket() public payable nonReentrant{
        require(IERC20(stableCoin).balanceOf(msg.sender) >= OperatorShare,"Fee Balance Not Enough");
        require(isParticipantForRound(currentRoundId(), msg.sender) == true,"Already a Participant");
        require(lottoRounds[currentRoundId()].participants.length < maxParticipants, "Max participants reached");
        require(block.timestamp <= lottoRounds[roundCounter].participationTimeOver, "Participation time is over");
        IERC20(stableCoin).transferFrom(msg.sender, address(this), OperatorShare);
        lottoRounds[currentRoundId()].participants.push(msg.sender);
        lottoRounds[currentRoundId()].totalPool = lottoRounds[currentRoundId()].totalPool.add(OperatorShare);
    }

    function distributeRewards() public isAllowed {}

    function selectWinners() internal {}

    function distributeToWinnders() internal{} // returns 80% of total Pool to winners 

    function refundLosers() internal{} //returns 20 % of total pool to all participants
}