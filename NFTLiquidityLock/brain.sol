pragma solidity ^0.8.0;

import "./Key.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

 contract ExternalContract is IERC721Receiver {
    DepositNFT public depositNFTContract;
    IERC20 public tokenContract;

    constructor(address _depositNFTContractAddress, address _tokenContractAddress) {
        depositNFTContract = DepositNFT(_depositNFTContractAddress);
        tokenContract = IERC20(_tokenContractAddress);
    }

    function depositAndTransfer(uint256 _amount) external {
        uint256 allowance = tokenContract.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Token allowance not enough");
        tokenContract.transferFrom(msg.sender, address(this), _amount);
        uint256 tokenId = dep(_amount);
        depositNFTContract.transferFrom(address(this), msg.sender, tokenId);
    }
        
    function TransferAndWithdraw(uint256 _tokenId) external {
        // transfer the NFT to this contract
        depositNFTContract.transferFrom(msg.sender, address(this), _tokenId);
        depositNFTContract.withdraw(_tokenId);
        (uint256 amount, ) = depositNFTContract.getDeposit(_tokenId);
        tokenContract.transfer(msg.sender, amount);
    }

    function dep(uint256 _amount) internal returns (uint256 tokenId) {
        // lock the tokens by transferring them to the depositNFTContract
        tokenContract.approve(address(depositNFTContract), _amount);
        depositNFTContract.deposit( _amount);
    }

    function getDeposit(uint256 _tokenId) external view returns (uint256 amount, uint256 timestamp) {
        return depositNFTContract.getDeposit(_tokenId);
    }

    function setLockDuration(uint256 _lockDuration) external {
        depositNFTContract.setLockDuration(_lockDuration);
    }

    function setDepositCap(uint256 _depositCap) external {
        depositNFTContract.setDepositCap(_depositCap);
    }

    function getAllTokenIds() external view returns (uint256[] memory) {
        return depositNFTContract.getAllTokenIds();
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4) {
        // return the ERC721_RECEIVED value defined in the interface
        return IERC721Receiver.onERC721Received.selector;
    }
}