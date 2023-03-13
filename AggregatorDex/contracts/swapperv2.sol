// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract Exchangerv2 {

    address public feeReciepeint;
    address private constant UNISWAP_ROUTER_ADDRESS =0x3aF9929A6f53a729E62ED57CF1187Ea99c2Ba08B ;//ADDRRESS_UNISWAP_ROUTER_V2; Replace current must
    IUniswapV2Router02 private uniswapRouter;
    address public owner;
    IUniswapV2Factory public uniswapFactory;

    constructor(address _uniswapFactory) {
        uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
        uniswapFactory = IUniswapV2Factory(_uniswapFactory);
        owner = msg.sender;
    }

    event SwapExecuted(address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut, address to);
    
    function swapTokens(
    address tokenIn, 
    uint256 amountIn, 
    address tokenOut, 
    uint256 amountOutMin, 
    address to, 
    uint256 deadline, 
    uint256 gasLimit
) external {
    require(msg.sender == owner, "Only owner can execute swaps");
    address[] memory path = new address[](2);
    path[0] = tokenIn;
    path[1] = tokenOut;
    uint256[] memory amounts = uniswapRouter.getAmountsOut(amountIn, path);
    require(amounts[1] >= amountOutMin, "Received amount is less than the minimum specified");
    uint256 feeAmount = amountIn / 1000;
    require(IERC20(tokenIn).transfer(feeReciepeint, feeAmount), "Failed to transfer fee to owner");
    uint256 amountInAdjusted = amountIn - feeAmount;
    uint256[] memory swapAmounts;
    bytes memory data = abi.encodeWithSelector(
        uniswapRouter.swapExactTokensForTokens.selector,
        amountInAdjusted,
        amountOutMin,
        path,
        to,
        deadline
    );
    assembly {
        let success := call(
            gasLimit, 
            UNISWAP_ROUTER_ADDRESS, 
            0, 
            add(data, 0x20), 
            mload(data), 
            0, 
            0
        )
        swapAmounts := mload(0)
        switch success
        case 0 {
            revert(0, 0)
        }
    }
    emit SwapExecuted(tokenIn, tokenOut, amountInAdjusted, swapAmounts[1], to);
}

   function getPoolData(address _token1, address _token2) public view returns (uint256 reserve1, uint256 reserve2, uint256 totalSupply) {
        address pair = uniswapFactory.getPair(_token1, _token2);
        IUniswapV2Pair uniswapPair = IUniswapV2Pair(pair);
        (uint256 _reserve1, uint256 _reserve2, uint256 _totalSupply) = uniswapPair.getReserves();
        reserve1 = _reserve1;
        reserve2 = _reserve2;
        totalSupply = _totalSupply;
    }
}
