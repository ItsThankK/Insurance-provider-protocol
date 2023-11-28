// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./CryptoWalletInsurance.sol";
import "./CollateralProtection.sol";

contract InsuranceProtocolFactory {

    address loanToken;
    address Admin;

    mapping(address => CryptoWalletInsurance) public insurancePools;
    mapping(address => CollateralProtection) public collateralPools;


    address[] public insurancePoolAddresses;
    address[] public collateralPoolAddresses;

    modifier isValidPool(CryptoWalletInsurance pool) {
        require(address(pool) != address(0), "Invalid pool address");
        _;
    }

    constructor(address _loanToken, address _admin) {
        Admin = _admin;
        loanToken = _loanToken;
    }

    function createCryptoWalletInsurancePool(uint _premiumAmount) external {
        CryptoWalletInsurance newPool = new CryptoWalletInsurance(_premiumAmount, msg.sender);
        insurancePools[msg.sender] = newPool;
        insurancePoolAddresses.push(address(newPool));
    }

    // Collateral price must be worth more than loan tokens in ETH
    function createCollateralProtectionPool() external payable {
        uint ethValue = (msg.value * getEthPrice()) / 10 ** 18;
        uint _LoanAmount = (ethValue * (1000 * 10 ** 18)) / 2000;
        CollateralProtection newPool = new CollateralProtection(
            msg.value, // Collateral amount or worth
            _LoanAmount,
            msg.sender, //client
            address(this), // Current Factory address
            loanToken
        );
        collateralPools[msg.sender] = newPool;
        collateralPoolAddresses.push(address(newPool));
        IERC20(loanToken).transfer(msg.sender, _LoanAmount);
        payable(address(newPool)).transfer(msg.value);
    }

    function viewInsurancePools() external view returns (address[] memory) {
        return insurancePoolAddresses;
    }

    function viewcollateralPools() external view returns (address[] memory) {
        return collateralPoolAddresses;
    }

    function getEthPrice() internal pure returns (uint) {
        // Current ETH price according to coinmarket cap
        return 2000;
    }
}