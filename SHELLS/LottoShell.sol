//AN EXAMPLE SHELL/Framework for Lotteries


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 

contract EtherLottery is ReentrancyGuard , Ownable{
    using SafeMath for uint256;

    uint256 public maxParticipants;
    uint256 public ticketPriceInWei;
    uint256 public OperatorShare;
    uint256 public duration;
    uint256 private Nonce;
    uint256 public roundCounter;

    struct Lotto{
        address[] participants;
        address[] winners;
        address[] losers;
        uint256 roundId;
        uint256 totalPool;
        uint256 rewardPool;
        bool participationTimeOver;
        bool fundsDistributed;
        uint256 startTime;
        uint256 endTime;
        uint256 distributionTime;
    }

    mapping(uint256 => Lotto) public lottoRounds;
    mapping(address => bool) public operators;
    mapping(address => bool) public allowedFeeTokens;

    event NewRoundStarted(uint256 indexed roundNumber, uint256 indexed Time);
    event ParitcationTimeOver(uint256 indexed roundNumber , uint256 Time);
    event PrizesDistributed(uint256 indexed roundNumber, uint256 indexed Time, uint256 indexed prizePool);
    
    constructor(
        uint256 _maxParticipants,
        uint256 _ticketPriceInWei,
        uint256 _feePercent,
        uint256 _LotteryDurationInSeconds,
        address _token
    ){
        roundCounter = 1;
        Nonce =  1;
        allowedFeeTokens[_token] = true;
        maxParticipants = _maxParticipants;
        ticketPriceInWei = _ticketPriceInWei;
        OperatorShare = _feePercent;
        duration = _LotteryDurationInSeconds;  
    }

    modifier isAllowed()  {
        _isAllowedOP();
        _;
    }

    function _isAllowedOP() internal view{
        require(_msgSender() == owner() || operators[_msgSender()] == true,"Do Not Have Operator Level Access to call the Function");
    }
   
    function r2(uint256 seed)internal view returns (uint256) {
        uint256 nonce = Nonce;
        Nonce.add(1);
        return uint256(keccak256(abi.encodePacked(~uint256(0) - nonce * block.timestamp, roundCounter * nonce, roundCounter * block.timestamp , seed , seed * nonce))); 
    }
    function r1(uint256 key)public view returns (bytes32) {
        uint256 seed  = r2(key);
        uint256 nonce = Nonce;
        return keccak256(abi.encodePacked(roundCounter * nonce, roundCounter ,seed , seed * nonce)); 
    }

    function addOperator(address operator) external isAllowed {
        require(operator != address(0), "Invalid operator address");
        operators[operator] = true;
    }

    function removeOperator(address operator) external isAllowed {
        require(operator != address(0), "Invalid operator address");
        operators[operator] = false;
    }

    function addFeeToken(address token) external isAllowed {
        require(token != address(0), "Invalid token address");
        allowedFeeTokens[token] = true;
    }

    function removeFeeToken(address token) external isAllowed {
        require(token != address(0), "Invalid token address");
        allowedFeeTokens[token] = false;
    }

    function getCurrentLotteryId() public view returns(uint256){
        return roundCounter.sub(1);
    }

    function startNewLotto()public isAllowed{}
    
    function buyTicket() public nonReentrant{}

    function selectWinners() internal {}

    function distributeRewards() public {}

    function distributeToWinnders() internal{} // returns 80% of total Pool to winners 

    function refundLosers() internal{} //returns 20 % of total pool to all participants
}