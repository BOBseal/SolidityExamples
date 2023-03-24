// SPDX-LICENSE-IDENTIFIER: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
contract Lottery {
    
    using SafeMath for uint256;
    struct UserInfo{
        uint256 totalAmountWon;
        uint256 LottosWon;
        uint256 LottosParticipated;
        bool ClaimedCurrent;
    }

    address public LottoToken;
    uint256 public CurrentLottoCounter;
    uint256 public CurrentTicketPrice;
    uint256 public MaxParticipantCap;
    uint256 public feeAmount; // 1= 0.1%
    uint256 public Treasury;
    uint256 public RewardPool;
    uint256 public LottoConductPeriod;
    address private Owner;
    bool public LottoInProgress;

    mapping (address => UserInfo) private LottoUserInfo;
    mapping(address => mapping(address => uint256)) private lockedBalances;
    mapping(address => bool) private hasParticipated;
    address[] private participantList;

    event NewLottoStarted(uint256 indexed LottoCounter, uint256 indexed TicketPrice, uint256 indexed MaxParticipantCap);
    event ParticipantRegistered(address indexed participant, uint256 indexed ticketPrice);
    event WinnersSelected(address[] indexed winners, uint256 indexed rewardAmount);

    constructor (
        address LotteryBaseToken ,
        uint256 maxUserCap, 
        uint256 LottoTimeFrame,
        uint256 feeAmt,
        uint256 TicketPrice

    ){
        require (LottoToken != address(0) , "Lotto Token Cannot be zero");
        require (LottoConductPeriod >= 900 ,"Lotto Conduct Period Should Atleast be of 900 seconds");
        LottoToken = LotteryBaseToken;
        MaxParticipantCap = maxUserCap;
        CurrentLottoCounter = 0;
        LottoConductPeriod = LottoTimeFrame;
        feeAmount = feeAmt;
        CurrentTicketPrice = TicketPrice;
    }

    function Lock(address user,uint256 amount) internal {
        require( amount >0 ,"Cannot be zero");
        require (user != address(0));
        lockedBalances[LottoToken][user] = lockedBalances[LottoToken][user].add(amount);
    }
    
    function Participate() public {
        require(!hasParticipated[msg.sender], "User has already participated");
        uint256 balance = GetTokenBal(msg.sender);
        require(balance >0 , "Not Enough Balance of Tokens to buy TICKET" );
        IERC20(LottoToken).transferFrom(msg.sender, address(this), CurrentTicketPrice);
        uint256 toLockAndPool = CurrentTicketPrice.div(2);
        Lock(msg.sender, toLockAndPool);
        RewardPool = RewardPool.add(toLockAndPool);
        participantList.push(msg.sender);
        UserInfo storage userInfo = LottoUserInfo[msg.sender];
        hasParticipated[msg.sender] = true;
        userInfo.LottosParticipated = userInfo.LottosParticipated.add(1);
        emit ParticipantRegistered(msg.sender, CurrentTicketPrice);
    }

    function GetTokenBal(address user) internal view returns(uint256){
        require (user != address(0),"");
        return IERC20(LottoToken).balanceOf(user);
    }

    function claim() public {
        UserInfo storage userInfo = LottoUserInfo[msg.sender];
        require(userInfo.LottosParticipated > 0, "User did not participate in any lotto");

        if (hasParticipated[msg.sender]) {
            require(!LottoInProgress, "Lotto is still in progress, winners not selected yet");
            //check already claimed
            uint256 userReward = RewardPool.div(10);
            for (uint256 i = 0; i < 10; i++) {
                if (participantList[i] == msg.sender) {
                    userInfo.LottosWon = userInfo.LottosWon.add(1);
                   
                    //Logic
                    break;
                }
            }
        } else {
            // Else Send Lock only
        }
    }

    function CalculateWinners() internal returns (address[] memory) {
        require(CurrentLottoCounter > 0, "No lotto played yet");
        uint256 participants = CurrentLottoCounter;
        if (participants > MaxParticipantCap) {
            participants = MaxParticipantCap;
        }
        address[] memory winners = new address[](10);
        for (uint256 i = 0; i < 10; i++) {
            uint256 winnerIndex = uint256(keccak256(abi.encodePacked(block.timestamp, i))) % participants;
            address winner = address(0);
            for (uint256 j = winnerIndex; j < participants; j++) {
                if (!hasParticipated[participantList[j]]) {
                    continue;
                }
                winner = participantList[j];
                break;
            }
            if (winner == address(0)) {
                for (uint256 j = 0; j < winnerIndex; j++) {
                    if (!hasParticipated[participantList[j]]) {
                        continue;
                    }
                    winner = participantList[j];
                    break;
                }
            }
            winners[i] = winner;
            hasParticipated[winner] = false;
        }
        return winners;
    }

    //function admin stop lotto and refund

    //function admin stop lotto and select winner

    //function admin start lotto 

    //claim win amount


}