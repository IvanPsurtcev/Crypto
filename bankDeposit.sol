pragma solidity 0.8.0;

contract BankDeposit {
    mapping(address => uint) public userDeposit;
    mapping(address => uint) public balance;
    mapping(address => uint) public time;
    mapping(address => uint) public percentWithdraw;
    mapping(address => uint) public allPercentWithdraw;

    uint public stepTime = 0.05 hours;

    event Invest(address investor, uint256 amount);
    event Withdraw(address investor, uint256 amount);

    modifier userExist() {
        require(balance[msg.sender] > 0, "Client don't found");
        _;
    }

    modifier checkTime() {
        require(now >= time[msg.sender] + stepTime, "Quick withdrawal request");
        _;
    }

    function bankAccount() public payable {
        require(msg.value >= 0.001 ether);
    }

    function collectPercent() userExist checkTime public {
        if((balance[msg.sender] * 2) <= allPercentWithdraw[msg.sender]) {
            balance[msg.sender] = 0;
            time[msg.sender] = 0;
            percentWithdraw[msg.sender] = 0;
        } else {
            uint payout = payoutAmount();
            percentWithdraw[msg.sender] += payout;
            allPercentWithdraw[msg.sender] += payout;
            msg.sender.transfer(payout);
            emit Withdraw(msg.sender, payout);
        }
    }
}