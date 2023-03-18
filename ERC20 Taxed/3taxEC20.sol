// SPDX-Licence-Identifier : MIT
pragma solidity ^0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract MyToken is IERC20 {
    string public constant name = "MyToken";
    string public constant symbol = "MTK";
    uint8 public constant decimals = 18;
    uint256 fee1;
    uint256 fee2;
    uint256 fee3;
    address address1;
    address address2;
    address address3;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event ExcludeFromFee(address indexed account, bool isExcluded);
    event SetFeePercentage(uint256 feePercentage);

    constructor(address _address1 , address _address2 , address _address3) {
        _totalSupply = 1000 * (10**18);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
        _address1 = address1;
        _address2 = address2;
        _address3 = address3;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _allowances[sender][msg.sender] = currentAllowance - amount;
        _transfer(sender, recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
         if (_isExcludedFromFee[sender]) {
            _balances[sender] -= amount;
            _balances[recipient] += amount;
            emit Transfer(sender, recipient, amount);
        } else {
            uint256 feeAmount1 = amount * fee1 / 1000;
            uint256 feeAmount2 = amount * fee2 / 1000;
            uint256 feeAmount3 = amount * fee3 / 1000;
            uint256 transferAmount = amount - feeAmount1 - feeAmount2 - feeAmount3;
            _balances[sender] -= amount;
            _balances[address1] += feeAmount1;
            _balances[address2] += feeAmount2;
            _balances[address3] += feeAmount3;
            _balances[recipient] += transferAmount;
            emit Transfer(sender, address1, feeAmount1);
            emit Transfer(sender, address2, feeAmount2);
            emit Transfer(sender, address3, feeAmount3);
            emit Transfer(sender, recipient, transferAmount);
        }
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
}