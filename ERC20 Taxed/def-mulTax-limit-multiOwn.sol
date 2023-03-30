// SPDX-Licence-Identifier : MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DToken is IERC20 ,ReentrancyGuard{
    using SafeMath for uint256;
    struct Admins{
        address user;
    }
    string public name = "AXOMEE TOKEN";
    string public symbol ="AXOM";
    string private tokenLogo;
    uint256 public constant decimals = 18;
    uint256 public fee1;
    uint256 public maxTx;
    uint256 public fee2;
    uint256 public fee3;
    address private Owner;
    address public address1;
    address public address2;
    address public address3;
    uint256 public _totalSupply;
    mapping(address=>bool) isAdmin;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _excludedFromTxLimit;
    event ExcludeFromFee(address indexed account, bool isExcluded);
    event SetFeePercentage(uint256 feePercentage , uint256 timestamp);
    event Rebrand (string name , string symbol , uint256 timestamp);

    constructor(string memory _name , string memory _symbol,address _feereceiever1 , address _feereceiever2 , uint256 feea , uint256 feeb, uint256 feec , uint256 maxTxPercent , uint256 supply) {
        _totalSupply = supply * (10**18);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
        address1 = _feereceiever1; // fee recieving wallets ... Ecosystem MultiSig Wallet for the Ecosystem Revenue and Run Costs
        address2 = _feereceiever2; // Ecosystem Multisig Reward and Incentive Pool
        address3 = address(0); // burn this amount
        fee1 = feea;  // 1 = 0.01%
        fee2 = feeb;
        fee3 = feec;
        maxTx= maxTxPercent;
        name=_name;
        symbol=_symbol;
        Owner = msg.sender;
    }
    function addAdmin(address account) external {
        require(msg.sender == owner(), "Only the owner can set the Admins");
        require(isAdmin[account] == false , "Already an Admin");
        isAdmin[account] = true;
    }

    function changeNameNdLogo(string memory newname , string memory newsymbol) external {
        require(isAdmin[msg.sender] == true || msg.sender == owner() , "Not An Admin");
        name = newname;
        symbol = newsymbol;
        emit Rebrand(newname , newsymbol , block.timestamp);
    }
    function setLogo(string calldata hash) external{
        require(isAdmin[msg.sender] == true || msg.sender == owner() , "Not An Admin");
        tokenLogo = hash;
    }
    function removeAdmin(address account) external {
        require(msg.sender == owner(), "Only the owner can remove an admin");
        require(isAdmin[account] == true , "Already Removed Access"); 
        isAdmin[account] = false;
    }
    function checkAdminStats(address account) external view returns(bool){
        return isAdmin[account];
    }

    function getLogo() external view returns(string memory){
        return tokenLogo;
    }
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
     function totalUnburntSupply() external view returns (uint256) {
        uint256 totSupply = _totalSupply - _balances[address3];
        return totSupply;
    }
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }
    function allowance(address _Owner, address spender) external view override returns (uint256) {
        return _allowances[_Owner][spender];
    }
    function approve(address spender, uint256 amount) external override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        if (!_isExcludedFromFee[msg.sender] && isAdmin[msg.sender] == false) {
            uint256 feeAmount1 = amount.mul(fee1).div(10000);
            uint256 feeAmount2 = amount.mul(fee2).div(10000);
            uint256 feeAmount3 = amount.mul(fee3).div(10000);
            uint256 totalFee = feeAmount1.add(feeAmount2).add(feeAmount3);
            uint256 amtAfterFee = amount.sub(totalFee);
            _transfer(msg.sender, recipient, amtAfterFee);
            _transfer(msg.sender, address1, feeAmount1);
            _transfer(msg.sender, address2, feeAmount2);
            _transfer(msg.sender, address3, feeAmount3);
        } else {
            _transfer(msg.sender, recipient, amount);
        }
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _allowances[sender][msg.sender] = currentAllowance.sub(amount);
        if (!_isExcludedFromFee[msg.sender] && isAdmin[msg.sender] == false) {
            uint256 feeAmount1 = amount.mul(fee1).div(10000);
            uint256 feeAmount2 = amount.mul(fee2).div(10000);
            uint256 feeAmount3 = amount.mul(fee3).div(10000);
            uint256 totalFee = feeAmount1.add(feeAmount2).add(feeAmount3);
            uint256 amtAfterFee = amount.sub(totalFee);
            _transfer(sender, recipient, amtAfterFee);
            _transfer(sender, address1, feeAmount1);
            _transfer(sender, address2, feeAmount2);
            _transfer(sender, address3, feeAmount3);
        } else {
            _transfer(sender, recipient, amount);
        }
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal nonReentrant{
        uint256 outAmt= _totalSupply.mul(maxTx).div(100);
        if (_excludedFromTxLimit[msg.sender]==false|| isAdmin[msg.sender] == false){
        require(amount <= outAmt,"Amount Exceeds Allowed Transaction Limit, Retry or get Permission");
        }
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance.sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function setFee(uint256 _fee1, uint256 _fee2, uint256 _fee3) external {
       require(isAdmin[msg.sender] == true || msg.sender == owner() , "Not An Admin");
        fee1 = _fee1;
        fee2 = _fee2;
        fee3 = _fee3;
        emit SetFeePercentage(_fee1 + _fee2 + _fee3 , block.timestamp);
    }
    function burn(uint256 amount) external nonReentrant {
        require(_balances[msg.sender] >= amount, "ERC20: burn amount exceeds balance");
        _balances[msg.sender] -= amount;
        _totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
    function isApproved(address account) external view returns (bool) {
        return _allowances[account][owner()] > 0;
    }
    function setAddress(address _address1, address _address2, address _address3) external {
        require(isAdmin[msg.sender] == true || msg.sender == owner() , "Not An Admin");
        address1 = _address1;
        address2 = _address2;
        address3 = _address3;
    }
    function excludeFromFee(address account) external {
        require(isAdmin[msg.sender] == true || msg.sender == owner() , "Not An Admin");
        require(_isExcludedFromFee[account] == false ,"account already excluded");
        _isExcludedFromFee[account] = true;
        emit ExcludeFromFee(account, true);
    }
    function includeInFee(address account) external {
        require(isAdmin[msg.sender] == true || msg.sender == owner() , "Not An Admin");
        require(_isExcludedFromFee[account] == true ,"account already included");
        _isExcludedFromFee[account] = false;
        emit ExcludeFromFee(account, false);
    }
    function excludeFromTxLimit(address account) external {
        require(isAdmin[msg.sender] == true || msg.sender == owner() , "Not An Admin");
        require(_excludedFromTxLimit[account] == false , "account already excluded");
        _excludedFromTxLimit[account] = true;
    }
    function includeInTxLimit(address account) external{
        require(isAdmin[msg.sender] == true || msg.sender == owner() , "Not An Admin");
        require(_excludedFromTxLimit[account] == true , "account already included");
        _excludedFromTxLimit[account] = false;
    }
    function isExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }
    function isExcludedFromTxLimit(address account) external view returns(bool){
        return _excludedFromTxLimit[account];
    }
    function hasBalance(address account) external view returns(bool) {
        if (_balances[account] > 0) {
            return true;
        } else {
            return false;
        }
    }
    function owner() internal view returns (address) {
        return Owner;
    }
}