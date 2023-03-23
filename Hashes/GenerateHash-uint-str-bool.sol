//SPDX-LICENSE-IDENTIFIER:MIT
pragma solidity ^0.8.17;

contract HashGenerator {
    //hash gen from 3 diff data types
    function generateHash(uint256 data1, string memory data2, bool data3) public pure returns (bytes32) {
        string memory s1 = uint256ToString(data1);
        string memory s2 = data2;
        string memory s3 = boolToString(data3);
        bytes memory data = abi.encodePacked(s1, s2, s3);
        bytes32 hash = keccak256(data);
        return hash;
    }
//helpers
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

    function boolToString(bool value) internal pure returns (string memory) {
        return value ? "true" : "false";
    }
}