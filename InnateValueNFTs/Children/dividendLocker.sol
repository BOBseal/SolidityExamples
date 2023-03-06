// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DividendTokenLocker is Ownable {
    using SafeMath for uint256;
    address private token;

    constructor(address _token) {
        _token = token;
    }
     mapping(address => mapping(address => uint256)) private _lockedBalances;

    function addDividendFunds( uint256 amount) external onlyOwner {
        require(amount > 0, "TokenLocker: amount must be greater than zero");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        _lockedBalances[token][msg.sender] = _lockedBalances[token][msg.sender].add(amount);
    }

    function withdrawDividends( uint256 amount) external onlyOwner {
        require(amount > 0, "TokenLocker: amount must be greater than zero");
        uint256 lockedAmount = _lockedBalances[token][msg.sender];
        require(lockedAmount >= amount, "TokenLocker: not enough locked tokens");
        _lockedBalances[token][msg.sender] = lockedAmount.sub(amount);
        IERC20(token).transfer(msg.sender, amount);
    }

    function withdrawall() external onlyOwner{
        uint256 totalLocked = _lockedBalances[token][msg.sender];
        IERC20(token).transfer(msg.sender , totalLocked);
    }
   
    function getLockedBalance( address account) external onlyOwner view returns (uint256) {
        return _lockedBalances[token][account];
    }

}
