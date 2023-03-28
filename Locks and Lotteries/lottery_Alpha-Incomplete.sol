// SPDX-LICENSE-IDENTIFIER: MIT
pragma solidity ^0.8.17;
pragma abicoder v2;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

contract Lottery {
    ISwapRouter public immutable swapRouter;
    using SafeMath for uint256;
    struct UserInfo{
        uint256 totalAmountWon;
        uint256 LottosWon;
        uint256 LottosParticipated;
        bool ClaimedLastParticipation;
    }
    string public LottoTopic;
    address public Stable1 = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public Stable2 = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public LottoToken;
    uint256 public CurrentLottoCounter;
    uint256 public CurrentTicketPrice;
    uint256 public MaxParticipantCap;
    uint256 public feeAmount; // 1= 0.1%
    uint256 public Treasury;
    uint256 public RewardPool;
    uint256 public lottoStartTime;
    uint256 public lottoEndTime;
    uint256 public LottoConductPeriod;
    address private Owner;
    bool public started;
    bool public ended;
    uint24 public constant poolFee = 3000;
    

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
        uint256 TicketPrice,
        ISwapRouter _swapRouter,
        address stableaddress1,
        address WETHAddr,
        address stableaddress2

    ){
        require (LottoToken != address(0) , "Lotto Token Cannot be zero");
        require (LottoConductPeriod >= 900 ,"Lotto Conduct Period Should Atleast be of 900 seconds");
        LottoToken = LotteryBaseToken;
        MaxParticipantCap = maxUserCap;
        CurrentLottoCounter = 0;
        LottoConductPeriod = LottoTimeFrame;
        feeAmount = feeAmt;
        CurrentTicketPrice = TicketPrice;
        swapRouter = _swapRouter;
        Stable1 = stableaddress1;
        WETH=WETHAddr;
        Stable2=stableaddress2;
        Owner = msg.sender;
    }

    function Lock(address user,uint256 amount) internal {
        require( amount >0 ,"Cannot be zero");
        require (user != address(0));
        lockedBalances[LottoToken][user] = lockedBalances[LottoToken][user].add(amount);
    }
    
    function Participate() public {
        UserInfo storage userInfo = LottoUserInfo[msg.sender];
        uint256 balance = GetTokenBal(msg.sender);
        require(started,"lotto not started"); 
        require(!hasParticipated[msg.sender], "User has already participated");
        require(balance >0 , "Not Enough Balance of Tokens to buy TICKET" );
        require(participantList.length < MaxParticipantCap, "Max participants reached");
        require(userInfo.ClaimedLastParticipation,"Claim Your Last Participation Rewards Before Participating");
        IERC20(LottoToken).transferFrom(msg.sender, address(this), CurrentTicketPrice);
        uint256 f = CurrentTicketPrice.mul(feeAmount).div(10000);
        uint256 amtAfterFee = CurrentTicketPrice.sub(f);
        uint256 toLockAndPool = amtAfterFee.div(2);
        
        ISwapRouter.ExactInputParams memory params =
        ISwapRouter.ExactInputParams({
            path: abi.encodePacked(LottoToken, poolFee, WETH, poolFee, Stable1),
            recipient: msg.sender,
            deadline: block.timestamp,
            amountIn: f,
            amountOutMinimum: 0
        });

        uint256 amountOut = swapRouter.exactInput(params);
        Treasury.add(amountOut);
        Lock(msg.sender, toLockAndPool);
        RewardPool = RewardPool.add(toLockAndPool);
        participantList.push(msg.sender);
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
        require(ended, "Lotto has not ended");
        require(!userInfo.ClaimedLastParticipation, "User has already claimed their last participation");
        require(hasParticipated[msg.sender], "User Needs to Participate to Be eligible to Claim");
        address[] memory winners = CalculateWinners(); 
        bool isWinner = false;
        for (uint256 i = 0; i < winners.length; i++) {
            if (winners[i] == msg.sender) {
                isWinner = true;
                break;
            }
        }
        uint256 userReward = 0;
        if(isWinner){
        userReward = RewardPool.div(winners.length);
        RewardPool = RewardPool.sub(userReward);
        IERC20(LottoToken).transfer(msg.sender, lockedBalances[LottoToken][msg.sender].add(userReward));
        userInfo.totalAmountWon = userInfo.totalAmountWon.add(lockedBalances[LottoToken][msg.sender]).add(userReward);
        userInfo.LottosWon = userInfo.LottosWon.add(1);
        userInfo.ClaimedLastParticipation = true;
        } else {
        require(isWinner, "User is not a winner");
        IERC20(LottoToken).transfer(msg.sender,lockedBalances[LottoToken][msg.sender]);
        userInfo.ClaimedLastParticipation = true;
        }
    }
    function CalculateWinners() internal returns (address[] memory) {
        require(ended, "Lotto not ended");
        uint256 participants = participantList.length;
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

    function startLotto() external {
        require (msg.sender == Owner,"Only Owner Can Start Or Stop Lotto");
        //later complete from here on
    }

}