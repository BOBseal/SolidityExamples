// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}
interface IUniswapV2Router02 {
    function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
}

contract swapperv2 {
    address private feeReciepeint;
    address private constant UNISWAP_ROUTER_ADDRESS =0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D ;//ADDRRESS_UNISWAP_ROUTER_V2; Replace current must
    IUniswapV2Router02 private uniswapRouter;
    address private owner;

    constructor() {
        uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
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
}
