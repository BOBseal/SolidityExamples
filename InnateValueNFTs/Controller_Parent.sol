// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../Children/key.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "./Children/valueLocker.sol";
import "./Children/fragments.sol";


  contract DepositNFTMinter is IERC721Receiver , IERC1155Receiver{
    DepositNFT private depositNFT;
    TokenLocker private tokenLocker;
    FRAGMENTS private friggit;
    address private feeRecipient;
    uint256 private feePercentage;
    

    constructor(DepositNFT _depositNFT, TokenLocker _tokenLocker,address _feeRecipient, uint256 _feePercentage , FRAGMENTS fragmenterAddress) {
        depositNFT = _depositNFT;
        tokenLocker = _tokenLocker;
         feeRecipient = _feeRecipient;
        feePercentage = _feePercentage;
        friggit = fragmenterAddress;
    }
    
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
     function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external override returns(bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external override returns(bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
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

        uint256 fee = _amount * feePercentage / 1000;
        uint256 amountAfterFee = _amount - fee;
        tokenLocker.lockTokens(_depositToken, amountAfterFee, block.timestamp + _lockTime);
        if (fee > 0) {
            depositTokenContract.transfer(feeRecipient, fee);
        }
    }

    function MintFragsWithERC20 (uint256 amountorSupply , uint256 depositedAmt , address depositToken , uint256 lockingTimeMin ) external {
        require ( amountorSupply > 0 , "Supply to Mint and deposit amount must not be empty");
         require ( depositedAmt > 0 , "Supply to Mint and deposit amount must not be empty");
        uint256 amm = depositedAmt / amountorSupply; 
        friggit.mint(amountorSupply , amm , depositToken);
        uint256 tokenID = friggit.TOKEN_ID() - 1 ;
        (uint256 deposit , uint256 supply , address tokenLocked) = friggit.getDepositData(tokenID);
        friggit.transfer(msg.sender ,tokenID, supply );
        IERC20 tokenContract = IERC20(tokenLocked);
        tokenContract.transferFrom(msg.sender , address(this) , deposit);
        uint256 fee = deposit * feePercentage / 1000;
        uint256 amtAfterfee = deposit - fee ;
        tokenLocker.lockTokens( tokenLocked , amtAfterfee , block.timestamp + lockingTimeMin);
         if (fee > 0) {
            tokenContract.transfer(feeRecipient, fee);
        }
    }

    function MintFragsWith721(uint256 id , uint256 supplyToMint) external {
        require(msg.sender == depositNFT.ownerOf(id), "DepositNFTMinter: caller must be NFT owner");
        (uint256 amount, address token ) = getDepositData(id);
        Burn(id);
        uint256 am = amount / supplyToMint;
        friggit.mint(supplyToMint , am , token);
        uint256 fragID = friggit.TOKEN_ID() - 1 ;
        friggit.transfer(msg.sender ,fragID , supplyToMint);
    }

    function Deposit721forERC20(uint256 _tokenId , address reciever) external {
        require(msg.sender == depositNFT.ownerOf(_tokenId), "DepositNFTMinter: caller must be NFT owner");
        // transfer and burn the tokens
        (uint256 amount, address token ) = getDepositData(_tokenId);
        uint256 fee = amount * feePercentage / 1000;
        uint256 amountAfterFee = amount - fee;
        tokenLocker.withdrawTokens(token,amount);
        if (fee > 0) {
            IERC20 tokenContract = IERC20(token);
            tokenContract.transferFrom(address(this) , feeRecipient, fee );
        }
        IERC20(token).transferFrom(address(this) , reciever, amountAfterFee);
        Burn(_tokenId);
    }
    function fragWithdraw(uint256 id , uint256 supplytoWithdraw , address receiver) external {
         ( uint256 deposit,  , address tokenid  )=friggit.getDepositData(id);
        fragdepdatatowithdraw(id , supplytoWithdraw);
        uint256 finalerc20amt = deposit * supplytoWithdraw;
        uint256 fee = finalerc20amt * feePercentage / 1000;
        uint256 amountAfterFee = finalerc20amt - fee;
        if (fee > 0) {
            IERC20 tokenContract = IERC20(tokenid);
            tokenContract.transferFrom(address(this) , feeRecipient, fee );
        }
        tokenLocker.withdrawTokens(tokenid,finalerc20amt);
        IERC20(tokenid).transferFrom(address(this), receiver, amountAfterFee);
    }
    function fragdepdatatowithdraw(uint256 id , uint256 supplytoWithdraw)internal  {
        friggit.safeTransferFrom(msg.sender, address(this), id, supplytoWithdraw, "");
        friggit.burnNFT(id , supplytoWithdraw);
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

