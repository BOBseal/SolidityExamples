//SPDX-LICENSE-IDENTIFIER: MIT
pragma solidity ^0.8.17;

contract MultiHasher {
    uint256 private nonce = 0;
    modifier validUint256(uint256 data) {
        require(data >= 0, "Invalid uint256 value");
        _;
    }
    modifier nonEmptyString(string memory data) {
        require(bytes(data).length > 0, "Empty string");
        _;
    }
    function generateHash(uint256 data1, string memory data2, bool data3) external pure validUint256(data1) nonEmptyString(data2) returns (bytes32) {
        string memory s1 = uint256ToString(data1);
        string memory s2 = data2;
        string memory s3 = boolToString(data3);
        bytes memory data = abi.encodePacked(s1, s2, s3);
        bytes32 hash = keccak256(data);
        return hash;
    }

    function uint256ToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    function boolToString(bool value) public pure returns (string memory) {
        return value ? "true" : "false";
    }
     function generateStringHash(string memory data) external pure nonEmptyString(data) returns (bytes32) {
        bytes memory dataBytes = bytes(data);
        bytes32 hash = keccak256(dataBytes);
        return hash;
    }
    function generateUint256Hash(uint256 data) external pure validUint256(data) returns (bytes32){
        bytes32 hash = keccak256(abi.encodePacked(data));
        return hash;
    }
    function generateBoolHash(bool data) external pure returns (bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(data));
        return hash;
    }
    function hashOfTwoHashes(bytes32 hash1, bytes32 hash2) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(hash1, hash2));
    }
    function generateRandomHash() public returns(bytes32){
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % (2**256 - 1);
        nonce++;
        bytes32 hash = keccak256(abi.encodePacked(randomNumber));
        return hash;
    } 
}