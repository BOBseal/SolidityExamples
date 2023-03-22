//SPDX-Licence-Identifier:MIT
pragma solidity ^0.8.17;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract ERC20Wallet {

    mapping(address => mapping(address => uint256)) private _balances;

    event TokensReceived(address indexed token, address indexed sender, uint256 amount);
    event tokensWithdrawn(address indexed token , address indexed reciever, uint256 account );
    function receiveTokens(address token, uint256 amount) external {
        IERC20 erc20 = IERC20(token);
        erc20.transferFrom(msg.sender, address(this), amount);
        _balances[msg.sender][token] += amount;
        emit TokensReceived(token, msg.sender, amount);
    }

    function getTokenBalance(address token, address user) external view returns (uint256) {
        return _balances[user][token];
    }

    function withdrawTokens(address token, uint256 amount) external {
        require(_balances[msg.sender][token] >= amount, "Insufficient balance");
        _balances[msg.sender][token] -= amount;
        IERC20 erc20 = IERC20(token);
        erc20.transfer(msg.sender, amount);
        emit tokensWithdrawn(token, msg.sender,amount);
    }
}