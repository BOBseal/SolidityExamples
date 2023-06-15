//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

contract CoreRandomiser{
    uint256 private nonce = 3;
    uint256 private x = 9;
    uint256 private y = ~uint256(0);
    uint256 private Max = y;
    uint256 private feeForCalls;
    address private Owner;

    mapping(address => bool) private exclusionList;

    constructor(){
        Owner = msg.sender;
        feeForCalls = 0;
    }

    modifier allowlist{
        require(exclusionList[msg.sender] == true || msg.sender == Owner,"Private Function Called");
        _;
    }

    function gen(uint256 _input, uint256 _input2) internal returns(bytes32){
        uint256 yy = y;
        y-=1;
        return keccak256(abi.encodePacked(msg.sender, _input, x , nonce, _input2 , Max - _input2, Max - _input, yy , y));
    } 

    function _a() internal returns(uint256){
        uint256 aa = nonce ** nonce;
        uint256 bbb = x ** x ;
        nonce = x++;
        x = nonce++;
        uint256 bb = Max - aa;
        uint256 cc = Max - bbb;
        return uint256(gen(cc, bb));
    }

    function _reqModifiableRandomUint256(uint256 YYY , string memory ZZZ , uint256 XXX) external allowlist returns(uint256){
       uint256 ff = _a();
       bytes32 af = keccak256(abi.encodePacked(ff,YYY,ZZZ, nonce));
       uint256 fff = _a();
       bytes32 aff = keccak256(abi.encodePacked(ff, fff, af,YYY,ZZZ));
       uint256 ffff = _a();
       uint256 ass = uint256(gen(YYY,XXX));
       return uint256(keccak256(abi.encodePacked(ff, fff, af, aff, ffff,ZZZ, ass)));
    }

    function _reqModifiableRandomBytes32(uint256 YYY , string memory ZZZ , uint256 XXX) external allowlist returns(bytes32){
       uint256 ff = _a();
       bytes32 af = keccak256(abi.encodePacked(ff,YYY,ZZZ , nonce));
       uint256 fff = _a();
       bytes32 aff = keccak256(abi.encodePacked(ff, fff, af, YYY,ZZZ));
       uint256 ffff = _a();
       uint256 ass = uint256(gen(YYY,XXX));
       return keccak256(abi.encodePacked(ff, fff, af, aff, ffff,ZZZ, ass));
    }

    function reqRandomUint256(uint256 seed) external payable returns(uint256){
        require(msg.value == feeForCalls,"Please Send the Fee Amount Along With the Request to get the random number, use getFee() from this contract to get Info about fee");
        uint256 ff = _a();
        bytes32 af = keccak256(abi.encodePacked(ff,seed + nonce));
        uint256 fff = _a();
        bytes32 aff = keccak256(abi.encodePacked(ff, fff, af));
        uint256 ffff = _a();
        uint256 ass = uint256 (gen(seed, seed*2));
        return uint256(keccak256(abi.encodePacked(ff, fff, af, aff, ffff, ass, seed)));
    }

    function reqRandomBytes32(uint256 seed) external payable returns(bytes32){
        require(msg.value == getCurrent(),"Please Send the Fee Amount Along With the Request to get the random hash, use getFee() from this contract to get Info about fee");
        uint256 ff = _a();
        bytes32 af = keccak256(abi.encodePacked(ff,seed + nonce));
        uint256 fff = _a();
        bytes32 aff = keccak256(abi.encodePacked(ff, fff, af));
        uint256 ffff = _a();
        uint256 ass = uint256 (gen(seed, seed*2));
        return keccak256(abi.encodePacked(ff, fff, af, aff, ffff,ass, seed));
    }

    function reqRandomUint256_(uint256 seed) external payable allowlist returns(uint256){
        uint256 ff = _a();
        bytes32 af = keccak256(abi.encodePacked(ff,seed + nonce));
        uint256 fff = _a();
        bytes32 aff = keccak256(abi.encodePacked(ff, fff, af));
        uint256 ffff = _a();
        uint256 ass = uint256 (gen(seed, seed*2));
        return uint256(keccak256(abi.encodePacked(ff, fff, af, aff, ffff, ass, seed)));
    }

    function reqRandomBytes32_(uint256 seed) external payable allowlist returns(bytes32){
        uint256 ff = _a();
        bytes32 af = keccak256(abi.encodePacked(ff,seed + nonce));
        uint256 fff = _a();
        bytes32 aff = keccak256(abi.encodePacked(ff, fff, af));
        uint256 ffff = _a();
        uint256 ass = uint256 (gen(seed, seed*2));
        return keccak256(abi.encodePacked(ff, fff, af, aff, ffff,ass, seed));
    }

    function getFee() external view returns(uint256){
        return getCurrent();
    }

    function getCurrent() internal view returns(uint256){
        return feeForCalls;
    }

    function addToAllowList(address addr) external {
        require(msg.sender ==  Owner,"Owner Function!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        exclusionList[addr] = true;
    }

    function removeFromAllowList(address addr) external {
        require(msg.sender ==  Owner,"Owner Function!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        exclusionList[addr] = false;
    }

    function transferOwnerShip(address _to) external {
        require(msg.sender ==  Owner,"Owner Function!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        Owner = _to;
    }

    function changeFee(uint256 _wei) external {
        require(msg.sender ==  Owner,"Owner Function!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        feeForCalls = _wei;
    }

    function recieve() external payable {}
    
    function withdrawEther() external {
        require(msg.sender == Owner, "Only the contract owner can withdraw Ether");
        uint256 balance = address(this).balance;
        require(balance > 0, "Contract has no Ether balance");
        payable(msg.sender).transfer(balance);
    }

}