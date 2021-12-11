pragma solidity 0.8.4;

// Interface for ERC20 DAI contract
interface DAI {
    function approve(address, uint256) external returns (bool);

    function transfer(address, uint256) external returns (bool);

    function transferFrom(address, address, uint256) external returns (bool);

    function balanceOf(address) external view returns (uint256);
}

// Interface for Compound's cDAI contract
interface cDAI {
    function mint(uint256) external returns (uint256);

    function redeem(uint256) external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function balanceOf(address) external view returns(uint256);
}

interface aDAI {
    function balanceOf(address) external view returns (uint256);
}

// Interface for Aave's lending pool contract
interface AaveLendingPool {
    function deposit(address asset, uint256 amount, address amount, address onBehalfOf, uint16 referralCode) external;

    function withdraw(address asset, uint256 amount, address to) external;

    function getReserveData(address asset) external returns (
        uint256 configuration,
        uint128 liquidityIndex,
        uint128 variableBorrowIndex,
        uint128 currentLiquidityRate,
        uint128 currentVariableBorrowRate,
        uint128 currentStableBorrowRate,
        uint40 lastUpdateTimestamp,
        address aTokenAddress,
        address stableDebtTokenAddress,
        address variableDebtTokenAddress,
        address interestRateStrategyAddress,
        uint8 id
    );
}

contract Aggregator {

    // Variables
    string public name = "Yield Aggregator";
    address public owner;
    address public locationOfFunds;
    uint256 public amountDeposited;

    DAI dai = DAI(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    cDAI cDai = cDAI(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
    aDAI aDai = aDAI(0x028171bCA77440897B824Ca71D1c56caC55b68A3);
    AaveLendingPool aaveLendingPool =
    AaveLendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);

    // Events
    event Deposit(address owner, uint256 amount, address depositTo);
    event Withdraw(address owner, uint256 amount, address withdrawFrom);
    event Rebalance(address owner, uint256 amount, address depositTo);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function deposit(uint256 _amount, uint256 _compAPY, uint256 _aaveAPY) public onlyOwner {
        require(_amount > 0);

        // Rebalance in the case of a protocol with the higher rate after their initial deposit,
        // is no longer the higher interest rate during this deposit...
        if(amountDeposited > 0) {
            rebalance(_compAPY, _aaveAPY);
        }

        dai.transferFrom(msg.sender, address(this), _amount);
        amountDeposited += _amount;

        // Compare interest rates
        if(_compAPY > _aaveAPY) {
            // Deposit into Compound
            require(_depositToCompound(_amount) == 0);

            // Update location
            locationOfFunds = address(cDai);
        } else {
            // Deposit into Aave
            _depositToAave(_amount);

            // Update location
            locationOfFunds = address(aaveLendingPool);
        }

        emit Deposit(msg.sender, _amount, locationOfFunds);
    }

    function withdraw() public onlyOwner {
        require(amountDeposited > 0);

        // Determine where the user funds are stored
        if (locationOfFunds == address(cDai)) {
            require(_withdrawFromCompound() == 0);
        } else {
            // Withdraw from Aave
            _withdrawFromAave();
        }

        // Once we have the funds, transfer back to owner
        uint256 balance = dai.balanceOf(address(this));
        dai.transfer(msg.sender, balance);

        emit Withdraw(msg.sender, amountDeposited, locationOfFunds);

        // Reset user balance
        amountDeposited = 0;
    }

}
