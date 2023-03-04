// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Children/key.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./Children/valueLocker.sol";
import "./BASIS/token/TokenERC1155.sol";

contract DepositNFTMinter is IERC721Receiver {
    DepositKey private depositNFT;
    TokenLocker private tokenLocker;
    address private feeRecipient;
    uint256 private feePercentage;
    

    constructor(DepositNFT _depositNFT, TokenLocker _tokenLocker,address _feeRecipient, uint256 _feePercentage) {
        depositNFT = _depositNFT;
        tokenLocker = _tokenLocker;
         feeRecipient = _feeRecipient;
        feePercentage = _feePercentage;
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

        uint256 fee = _amount * feePercentage / 100;
        uint256 amountAfterFee = _amount - fee;
        tokenLocker.lockTokens(_depositToken, amountAfterFee, block.timestamp + _lockTime);
        if (fee > 0) {
            depositTokenContract.transfer(feeRecipient, fee);
        }
    }

    function Deposit721forERC20(uint256 _tokenId , address reciever) external {
        require(msg.sender == depositNFT.ownerOf(_tokenId), "DepositNFTMinter: caller must be NFT owner");
        // transfer and burn the tokens
        (uint256 amount, address token ) = getDepositData(_tokenId);
        uint256 fee = amount * feePercentage / 100;
        uint256 amountAfterFee = amount - fee;
        withdrawLockedTokens(token , amountAfterFee);
        if (fee > 0) {
            IERC20 tokenContract = IERC20(token);
            tokenContract.transfer(feeRecipient, fee);
        }
        IERC20(token).transfer(reciever , amountAfterFee);
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

