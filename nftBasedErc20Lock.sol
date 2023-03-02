//SPDX-License-Identifier : MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DepositNFT is ERC721URIStorage, ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    IERC20 public depositToken;
    uint256 public lockDuration;
    uint256 public depositCap;
    uint256 public tokenIdCounter;
    uint256 public totalDeposited;
    address private feeReceiver;
    struct DepositData {
        address depositor;
        uint256 amount;
        uint256 timestamp;
    }
    event TokenMinted(address indexed owner, uint256 indexed tokenId, uint256 amount);
    mapping(uint256 => DepositData) private depositData;
    constructor(
        string memory _name,
        string memory _symbol,
        address _depositToken,
        uint256 _lockDuration,
        uint256 _depositCap,
        address _feeReciever
    ) ERC721(_name, _symbol) {
        depositToken = IERC20(_depositToken);
        lockDuration = _lockDuration;
        depositCap = _depositCap;
        feeReceiver = _feeReciever;
    }
    function deposit(uint256 _amount) external nonReentrant {
    require(_amount > 0, "DepositNFT: amount must be greater than zero");
    require(totalDeposited + _amount <= depositCap, "DepositNFT: deposit amount exceeds cap");
    // Transfer tokens from sender to contract
    depositToken.transferFrom(msg.sender, address(this), _amount);
    // Mint NFT to sender
    _safeMint(msg.sender, tokenIdCounter);
    _setTokenURI(tokenIdCounter, uint2str(_amount));
    tokenIdCounter++;
    // Save deposit information to token metadata
    (address depositor, uint256 amount, uint256 timestamp) = (msg.sender, _amount, block.timestamp);
    depositData[tokenIdCounter] = DepositData({depositor: depositor, amount: amount, timestamp: timestamp});
    // Update total deposited
    totalDeposited += _amount;
    emit TokenMinted(msg.sender, tokenIdCounter, _amount);
    }
    function uint2str(uint256 _i) internal pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        str = string(bstr);
    }
    function withdraw(uint256 _tokenId, address _to) external nonReentrant {
    require(_isApprovedOrOwner(msg.sender, _tokenId), "DepositNFT: caller is not owner nor approved");
    // Get deposit information from token metadata
    (address depositor, uint256 amount, uint256 timestamp) = getDeposit(_tokenId);
    require(block.timestamp >= timestamp + lockDuration, "DepositNFT: lock duration has not elapsed");
    // Calculate fee amount
    uint256 feeAmount = amount / 1000;
    // Transfer fee amount to fee receiver address
    depositToken.transfer(feeReceiver, feeAmount);
    // Transfer tokens from contract to specified address
    depositToken.transfer(_to, amount - feeAmount);
    // Burn NFT
    _burn(_tokenId);
    // Update total deposited
    totalDeposited -= amount;
    }
    function getDeposit(uint256 _tokenId) public view returns (address depositor, uint256 amount, uint256 timestamp) {
        require(_exists(_tokenId), "DepositNFT: invalid token id");
        // Get deposit information from depositData mapping
        depositor = depositData[_tokenId].depositor;
        amount = depositData[_tokenId].amount;
        timestamp = depositData[_tokenId].timestamp;
    }
    function setLockDuration(uint256 _lockDuration) external onlyOwner {
        lockDuration = _lockDuration;
    }
    function setDepositCap(uint256 _depositCap) external onlyOwner {
        depositCap = _depositCap;
    }
    function getAllTokenIds() external view returns (uint256[] memory) {
    uint256[] memory tokenIds = new uint256[](tokenIdCounter);
    for (uint256 i = 0; i < tokenIdCounter; i++) {
        tokenIds[i] = i;
    }
    return tokenIds;
    }
}
