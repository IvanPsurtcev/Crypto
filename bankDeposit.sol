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
        require(block.timestamp >= time[msg.sender] + stepTime, "Quick withdrawal request");
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
            payable(msg.sender).transfer(payout);
            emit Withdraw(msg.sender, payout);
        }
    }

    function deposit() public payable {
        if (msg.value > 0) {
            if (balance[msg.sender] > 0 && block.timestamp > time[msg.sender] + stepTime) {
                collectPercent();
                percentWithdraw[msg.sender] = 0;
            }
            balance[msg.sender] += msg.value;
            time[msg.sender] = block.timestamp;
            emit Invest(msg.sender, msg.value);
        }
    }

    function percentRate() public view returns (uint256) {
        if (balance[msg.sender] < 10 ether) {
            return 5;
        }
        if (balance[msg.sender] >= 10 ether && balance[msg.sender] < 20 ether) {
            return 7;
        }
        if (balance[msg.sender] >= 20 ether) {
            return 9;
        }
    }
    function payoutAmount() public view returns (uint256) {
        uint percent = percentRate();
        uint different = (block.timestamp - time[msg.sender]) / stepTime;
        uint rate = (balance[msg.sender] / 100) * percent;
        uint withdrawalAmount = (rate * different) - percentWithdraw[msg.sender];
        return withdrawalAmount;
    }

    function returnDeposit() public {
        uint withdrawalAmount = balance[msg.sender];
        balance[msg.sender] = 0;
        time[msg.sender] = 0;
        percentWithdraw[msg.sender] = 0;
        payable(msg.sender).transfer(withdrawalAmount);
    }
}
