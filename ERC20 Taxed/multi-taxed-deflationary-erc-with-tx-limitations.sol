// SPDX-Licence-Identifier : MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DToken is IERC20 {
    using SafeMath for uint256;
    string public constant name = "D-Token";
    string public constant symbol = "DTKN";
    string private tokenLogo;
    uint256 public constant decimals = 18;
    uint256 public fee1;
    uint256 public fee2;
    uint256 public fee3;
    address private add = 0x0000000000000000000000000000000000000000;
    address public address1;
    address public address2;
    address public address3;
    uint256 private maxTransactionAmount;
    uint256 private maxHoldingAmount;
    uint256 public _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    event ExcludeFromFee(address indexed account, bool isExcluded);
    event SetFeePercentage(uint256 feePercentage);

    constructor(address _feereceiever1 , address _feereceiever2 , uint256 feea , uint256 feeb, uint256 feec) {
        _totalSupply = 500000000 * (10**18);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
        address1 = _feereceiever1; // fee recieving wallets ... Ecosystem MultiSig Wallet for the Ecosystem Revenue and Run Costs
        address2 = _feereceiever2; // Ecosystem Multisig Reward and Incentive Pool
        address3 = add; // burn this amount
        fee1 = feea;  // 1 = 0.01%
        fee2 = feeb;
        fee3 = feec;
        maxTransactionAmount = _totalSupply / 200;
        maxHoldingAmount = _totalSupply / 25;
    }
    function setLogo(string calldata hash) external{
        require(msg.sender == owner(), "Only the owner can set the Logo");
        tokenLogo = hash;
    }

    function getLogo() external view returns(string memory){
        return tokenLogo;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     function totalUnburntSupply() public view returns (uint256) {
        uint256 totSupply = _totalSupply - _balances[address3];
        return totSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
     function approveFrom(address from,address spender, uint256 amount) public returns (bool) {
        _allowances[from][spender] = amount;
        emit Approval(from, spender, amount);
        return true;
    }
    function transfer(address recipient, uint256 amount) public returns (bool) {
        if (!_isExcludedFromFee[msg.sender]) {
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

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _allowances[sender][msg.sender] = currentAllowance.sub(amount);
        if (!_isExcludedFromFee[msg.sender]) {
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

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(amount <= maxTransactionAmount, "Transfer amount exceeds the max transaction amount");
        uint256 senderBalance = _balances[sender];
        require(_balances[recipient] + amount <= maxHoldingAmount, "Receiver already holds the maximum allowed amount");
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance.sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function setFee(uint256 _fee1, uint256 _fee2, uint256 _fee3) public {
        require(msg.sender == owner(), "Only the owner can set the fee");
        fee1 = _fee1;
        fee2 = _fee2;
        fee3 = _fee3;
        emit SetFeePercentage(_fee1 + _fee2 + _fee3);
    }
    function burn(uint256 amount) public {
        require(_balances[msg.sender] >= amount, "ERC20: burn amount exceeds balance");
        _balances[msg.sender] -= amount;
        _totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }

    function isApproved(address account) public view returns (bool) {
        return _allowances[account][owner()] > 0;
    }
    function setAddress(address _address1, address _address2, address _address3) public {
        require(msg.sender == owner(), "Only the owner can set the address");
        address1 = _address1;
        address2 = _address2;
        address3 = _address3;
    }

    function excludeFromFee(address account, bool isExcluded) public {
        require(msg.sender == owner(), "Only the owner can exclude addresses from fees");
        _isExcludedFromFee[account] = isExcluded;
        emit ExcludeFromFee(account, isExcluded);
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function owner() public view returns (address) {
        return msg.sender;
    }
    receive() external payable {}
}