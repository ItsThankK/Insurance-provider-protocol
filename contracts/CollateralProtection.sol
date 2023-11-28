// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CollateralProtection {

    /*
     *Main Policies:
     * 1) Collateral value can only be checked once per month
     * 2) Liquidate loan if Collateral is devalued by 30%   
    */

    address public owner;
    address factoryAddress;
    address loanToken;
    uint256 public collateralAmount;
    uint256 public loanAmount;
    uint256 public lastCollateralCheckTimestamp;
    bool loanLiquidated;
    bool loanRepayed;

    event CollateralCheck(
        address indexed owner,
        uint256 currentCollateralValue
    );

    // CUSTOM ERROS 
    error OnlyOwner();
    error CheckedOncePerWeek();

    constructor(
        uint256 _collateralAmount,
        uint256 _loanAmount,
        address _client,
        address _factoryAddress,
        address _loanToken
    ) {
        owner = _client;
        collateralAmount = _collateralAmount;
        loanAmount = _loanAmount;
        lastCollateralCheckTimestamp = block.timestamp;
        factoryAddress = _factoryAddress;
        loanToken = _loanToken;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    function checkCollateralValue() external {
        // Collateral value is checked at most once per week
        if (block.timestamp < lastCollateralCheckTimestamp + 7 days) {
            revert CheckedOncePerWeek();
        }
        // Liquidate if the collateral is devalued at 30% or more
        bool liquidate = isDevalued(
            (getEthPrice() * collateralAmount)
        );

        if (liquidate == true) {
            loanLiquidated = true;
        }

        // Update the timestamp of the last collateral check
        lastCollateralCheckTimestamp = block.timestamp;

        // Emit an event to record the collateral check
        emit CollateralCheck(owner, getEthPrice());
    }

    function repayLoan(uint _repaymentAmount) external {
        require(loanAmount == _repaymentAmount, "Incorrect amount");

        require(loanLiquidated != true, "Loan already liquidated");

        IERC20(loanToken).transferFrom(msg.sender, factoryAddress, _repaymentAmount);
        loanAmount -= _repaymentAmount;
        if (loanAmount == 0) {
            loanRepayed = true;
            payable(owner).transfer(collateralAmount);
        }
    }

    function getEthPrice() internal pure returns (uint) {
        // Current ETH price according to coinmarket cap
        return 2000;
    }

    function viewLoanAmount() external view returns (uint256) {
        return loanAmount;
    }

    function isDevalued(
        uint256 currentPrice
    ) public view returns (bool) {
        uint initialCollateralPrice = (loanAmount * 2000) / (1000 * 10 ** 18);
        // Calculate the price drop percentage
        uint256 priceDropPercentage = ((initialCollateralPrice - currentPrice) *
            100) / initialCollateralPrice;

        // Check if the price has dropped by 30% or more
        return priceDropPercentage >= 30;
    }
}