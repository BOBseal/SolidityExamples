// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract TokenLock is ERC1155, ReentrancyGuard {
    using Address for address payable;
    uint256 nftId;
    using SafeMath for uint256;

    address private _owner;
    IERC20 private _token;
    mapping(uint256 => uint256) private _lockTimes;

    constructor(address tokenAddress) ERC1155("BANKPASS") {
        _owner = msg.sender;
        _token = IERC20(tokenAddress);
    }

    function deposit(uint256 amount) public {
    require(amount > 0, "Amount must be greater than 0");

    // Prompt user to approve contract to spend tokens
    require(_token.approve(address(this), amount), "Token approval failed");

    // Calculate fee
    uint256 fee = amount.mul(1).div(100);

    // Transfer fee to contract owner
    require(_token.transferFrom(msg.sender, _owner, fee), "Token transfer failed");

    // Transfer tokens from user to contract
    require(_token.transferFrom(msg.sender, address(this), amount), "Token transfer failed");

    // Mint NFT and associate with deposit data
    _mint(msg.sender, nftId, 1, abi.encodePacked(msg.sender, amount));

    // Set lock time
    _lockTimes[nftId] = block.timestamp.add(3600); // 1 hour
    nftId++;

    // Log NFT ID and contract address
    emit NftDeposited(nftId);
}


    function withdraw(uint256 tokenId, address to) public {
        require(balanceOf(msg.sender, tokenId) == 1, "User does not own this token");

        // Get deposit data from NFT metadata
        (address account, uint256 amount) = abi.decode(getData(tokenId), (address, uint256));

        // Check if lock time is completed
        require(block.timestamp >= _lockTimes[tokenId], "Lock time not completed");

        // Transfer tokens from contract to user
        require(_token.transfer(to, amount), "Token transfer failed");

        // Burn NFT
        _burn(msg.sender, tokenId, 1);
    }

    function getData(uint256 tokenId) public view returns (bytes memory) {
        return abi.encodePacked(IERC1155MetadataURI(address(this)).uri(tokenId));
    }

    function setToken(address tokenAddress) public onlyOwner {
        _token = IERC20(tokenAddress);
    }

    function setOwner(address newOwner) public onlyOwner {
        _owner = newOwner;
    }

    event NftDeposited(uint256 indexed nftId);

    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not the owner");
        _;
    }
}
