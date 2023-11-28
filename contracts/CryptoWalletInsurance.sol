// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract CryptoWalletInsurance {

    /*
     *Main Policies:
     * 1) The insured can only pay for premium once a month
     * 2) The insured can only claim the insurance (compensation) once in 4 months 
     *    regardless of when hack happens    
    */

   uint public premiumAmount; // Premium amount to be paid monthly
    address public insured;    // Address of the person covered by insurance.

    struct Insured {
        uint policyGracePeriod; // Timestamp of the end of the current insurance period
        uint lastInsuranceClaim;  // Timestamp of the last insurance claim
    }

    // Mapping to store insured details based on their address
    mapping(address => Insured) public insuredList;  

    // Constructor to initialize the insurance protocol with premium price and insured address.
    constructor(uint _premiumAmount, address _insured) {
        premiumAmount = _premiumAmount;
        insured = _insured;
    }


    // Function for the insured to pay the monthly insurance premium.
    function payMonthlyPremium() external payable {
        // Check if an active premium is already available
        require(block.timestamp > insuredList[insured].policyGracePeriod, "Policy grace period is still on");

        // Check if the payment amount is sufficient
        require(msg.value == premiumAmount, "Payment amount is not premium amount");

        // Add the premium payment to the contract
        address(this).balance += msg.value;

        // Set the end of the current insurance period to 30 days from now
        insuredList[insured].policyGracePeriod = block.timestamp + 30 days;
    }


    // Function for the wallet owner to claim insurance.
    function claimInsurance(uint _compensation) external {
        // Check if a claim has been made within the last 4 months
        require(block.timestamp > insuredList[insured].lastInsuranceClaim + 120 days,
         "You can only claim insurance in 4 months interval");

        // Check if there are sufficient funds in the contract to send to the insured
        require(address(this).balance > _compensation, "There isn't enough compensation funds");

        // Update the last claimed timestamp and transfer the claimed amount to the insured
        insuredList[insured].lastInsuranceClaim = block.timestamp;
        payable(insured).transfer(_compensation);
    }

    // Function to get the insured's details.
    // which includes the insurance grace period and the last claimed timestamp.
    function viewTheInsuredDetails() external view returns (uint, uint) {
        return (insuredList[insured].policyGracePeriod, insuredList[insured].lastInsuranceClaim);
    }

    //Function to get the current premium price.
    function viewPremiumAmount() external view returns (uint) {
        return premiumAmount;
    }
}