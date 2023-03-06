
//SPDX-LICENSE-IDENTIFIER: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DepositNFT is ERC721URIStorage, ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    // States and Basics
    uint256 public tokenIdCounter;
    struct DepositData {
        uint256 amount;
        address depositToken;
    }
    event TokenMinted(address indexed owner, uint256 indexed tokenId, uint256 amount, address depositToken);
    mapping(uint256 => DepositData) private depositData;

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

  function mintKey(uint256 _amount , address _depositToken) external onlyOwner nonReentrant {
    require(_amount > 0, "DepositNFT: amount must be greater than zero");
    _safeMint(msg.sender, tokenIdCounter);
    _setTokenURI(tokenIdCounter, string(abi.encodePacked(uint2str(_amount), ",", _depositToken)));
    ( uint256 amount, address depositToken) = ( _amount, _depositToken);
    depositData[tokenIdCounter] = DepositData({ amount: amount, depositToken:depositToken});
    tokenIdCounter++;
    emit TokenMinted(msg.sender, tokenIdCounter, _amount , _depositToken);
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
            k = k - 1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        str = string(bstr);
    }

    function burnKey(uint256 _tokenId) external nonReentrant {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "DepositNFT: caller is not owner nor approved");
        _burn(_tokenId);
    }

    function getDepositData(uint256 _tokenId) external onlyOwner view returns (uint256 amount, address depositToken) {
        require(_exists(_tokenId), "DepositNFT: invalid token id");
        amount = depositData[_tokenId].amount;
        depositToken = depositData[_tokenId].depositToken;
    }

    function getAllTokenIds() external onlyOwner view returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](tokenIdCounter);
        for (uint256 i = 0; i < tokenIdCounter; i++) {
            tokenIds[i] = i;
        }
        return tokenIds;
    }
}