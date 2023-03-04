
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MyERC1155 is Context, ERC1155 ,ReentrancyGuard, Ownable{
    using SafeMath for uint256;
    uint256 public TOKEN_ID;

    struct NFT{
        uint256 deposit;
        uint256 supply;
        address tokenLocked;
    }

    mapping (uint256 => NFT) private _nftInfo;

    constructor() ERC1155("") {}

    function mintNFT(uint256 amount, uint256 deposit, address tokenLocked) public {
        _mint(_msgSender(), TOKEN_ID, amount, "");
        _nftInfo[TOKEN_ID] = NFT(deposit,amount, tokenLocked);
        TOKEN_ID++;
    }

    function getDeposit() public view returns (uint256) {
        return _nftInfo[TOKEN_ID].deposit;
    }

    function getTokenLocked() public view returns (address) {
        return _nftInfo[TOKEN_ID].tokenLocked;
    }
    function getNFTInfo(uint256 id) public view returns (NFT memory) {
         require(id < TOKEN_ID, "Invalid NFT ID");
        return _nftInfo[id];
    }

    function transferNFT(address receiver, uint256 id, uint256 amount) public {
        safeTransferFrom(msg.sender, receiver, id, amount, "");
    }
    function burnNFT(uint256 id, uint256 amount) public {
        _burn(_msgSender(), id, amount);
        _nftInfo[id].supply = _nftInfo[id].supply.sub(amount);
    }
    function remainingSupply(uint256 id) public view returns (uint256) {
        return _nftInfo[id].supply.sub(balanceOf(_msgSender(), id));
    }

}
