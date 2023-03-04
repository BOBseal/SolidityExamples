// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Children/key.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./Children/valueLocker.sol";

contract DepositNFTMinter is IERC721Receiver {
    DepositKey private depositNFT;
    TokenLocker private tokenLocker;

    constructor(DepositNFT _depositNFT, TokenLocker _tokenLocker) {
        depositNFT = _depositNFT;
        tokenLocker = _tokenLocker;
    }
    
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function mintDeposit721(uint256 _amount, address _depositToken, uint256 _lockTime) external {
        require(_amount > 0, "DepositNFTMinter: amount must be greater than zero");
        depositNFT.mintKey(_amount, _depositToken);
        uint256 tokenId = depositNFT.tokenIdCounter() - 1;
        (uint256 amount, ) = depositNFT.getDepositData(tokenId);
        depositNFT.safeTransferFrom(address(this), msg.sender, tokenId, "");
        // lock the tokens
        IERC20 depositTokenContract = IERC20(_depositToken);
        depositTokenContract.approve(address(tokenLocker), amount);
        depositTokenContract.transferFrom(msg.sender, address(this) , _amount);
        tokenLocker.lockTokens(_depositToken, amount, block.timestamp + _lockTime);
    }

     function Deposit721forERC20(uint256 _tokenId , address reciever) external {
        require(msg.sender == depositNFT.ownerOf(_tokenId), "DepositNFTMinter: caller must be NFT owner");
        // transfer and burn the tokens
        (uint256 amount, address token ) = getDepositData(_tokenId);
        IERC20 tokenContract = IERC20(token);
        withdrawLockedTokens(token , amount);
        tokenContract.transferFrom(address(this), reciever , amount);
        Burn(_tokenId);
    }

    function getDepositData(uint256 _tokenId) internal view returns(uint256 amount, address depositToken){
        return depositNFT.getDepositData(_tokenId);
    }
    function Burn(uint256 _tokenId) internal {
        depositNFT.safeTransferFrom(msg.sender, address(this) , _tokenId);
        depositNFT.burnKey(_tokenId);
    }
    function withdrawLockedTokens(address _token , uint256 _amount) internal {
        tokenLocker.withdrawTokens(_token , _amount);
    }

    function changeTokenLockTime(address _token, address _account, uint256 _newUnlockTime) internal {
        tokenLocker.changeUnlockTime(_token, _account, _newUnlockTime);
    }

    function getLockedTokenBalance(address _token, address _account) internal view returns (uint256) {
        return tokenLocker.getLockedBalance(_token, _account);
    }

    function getUnlockTime(address _token, address _account) internal view returns (uint256) {
        return tokenLocker.getUnlockTime(_token, _account);
    }
}

