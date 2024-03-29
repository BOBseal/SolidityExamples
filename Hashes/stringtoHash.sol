//SPDX-LICENSE-IDENTIFIER:MIT
pragma solidity ^0.8.17;

contract HashGenerator {
    //generate hash from 2 strings
    function generateHash(string memory data1, string memory data2) public pure returns (bytes32) {
        bytes memory data = abi.encodePacked(data1, data2);
        bytes32 hash = keccak256(data);
        return hash;
    }
}