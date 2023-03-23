//SPDX-LICENSE-IDENTIFIER: MIT
pragma solidity ^0.8.17;

contract HashGen {

    function generateHash(uint256 data1, string memory data2, bool data3) internal pure returns (bytes32) {
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

    function stringToUint256(string memory str) internal pure returns (uint256 result) {
        bytes memory b = bytes(str);
        uint256 i;
        result = 0;
        for (i = 0; i < b.length; i++) {
            uint256 c = uint256(uint8(b[i]));
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
    }

    function stringToBool(string memory str) internal pure returns (bool result) {
        bytes memory b = bytes(str);
        if (b.length == 1) {
            uint256 c = uint256(uint8(b[0]));
            if (c == 49) {
                result = true; // "1" character
            } else if (c == 48) {
                result = false; // "0" character
            }
        }
    }

    function boolToString(bool value) internal pure returns (string memory) {
        return value ? "true" : "false";
    }

    function generateStringHash(string memory data) internal pure returns (bytes32) {
        bytes memory dataBytes = bytes(data);
        bytes32 hash = keccak256(dataBytes);
        return hash;
    }

    function generateUint256Hash(uint256 data) internal pure returns (bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(data));
        return hash;
    }

    function generateBoolHash(bool data) internal pure returns (bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(data));
        return hash;
    }
}