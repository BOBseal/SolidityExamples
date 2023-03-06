// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenLocker is Ownable {
    using SafeMath for uint256;

    mapping(address => mapping(address => uint256)) private _lockedBalances;
    mapping(address => mapping(address => uint256)) private _unlockTime;

    function lockTokens(address token, uint256 amount, uint256 unlockTime) external onlyOwner {
        require(amount > 0, "TokenLocker: amount must be greater than zero");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        _lockedBalances[token][msg.sender] = _lockedBalances[token][msg.sender].add(amount);
        _unlockTime[token][msg.sender] = unlockTime;
    }

    function withdrawTokens(address token, uint256 amount) external onlyOwner {
        require(amount > 0, "TokenLocker: amount must be greater than zero");
        uint256 lockedAmount = _lockedBalances[token][msg.sender];
        require(lockedAmount >= amount, "TokenLocker: not enough locked tokens");
        require(block.timestamp >= _unlockTime[token][msg.sender], "TokenLocker: tokens are still locked");
        _lockedBalances[token][msg.sender] = lockedAmount.sub(amount);
        IERC20(token).transfer(msg.sender, amount);
    }
   
    function changeUnlockTime(address token, address account, uint256 newUnlockTime) external onlyOwner {
        require(_lockedBalances[token][account] > 0, "TokenLocker: no locked tokens for account");
        require(msg.sender == account , "You're Not Permitted to change other's LockTime");
        require(block.timestamp < _unlockTime[token][account], "TokenLocker: tokens are already unlocked");
        _unlockTime[token][account] = newUnlockTime;
    }

    function getLockedBalance(address token, address account) external onlyOwner view returns (uint256) {
        return _lockedBalances[token][account];
    }

    function getUnlockTime(address token, address account) external onlyOwner view returns (uint256) {
        return _unlockTime[token][account];
    }
}
