pragma solidity ^0.8.0;

contract HashGenerator {
    struct Data {
        string data1;
        string data2;
    }

    mapping(bytes32 => Data) private hashToData;
    mapping(bytes32 => address) private hashToUser;
//generatehash and store map
    function generateHash(string memory data1, string memory data2) public returns(bytes32) {
        bytes memory data = abi.encodePacked(data1, data2);
        bytes32 hash = keccak256(data);
        hashToData[hash] = Data(data1, data2);
        hashToUser[hash] = msg.sender;
        return hash;
    }
//get data
    function getDataFromHash(bytes32 hash) public view returns (string memory, string memory) {
        require(hashToUser[hash] == msg.sender, "Unauthorized access");
        Data memory data = hashToData[hash];
        return (data.data1, data.data2);
    }
}