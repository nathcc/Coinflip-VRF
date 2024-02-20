// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {VRFv2DirectFundingConsumer} from "./VRFv2DirectFundingConsumer.sol";

contract Coinflip is Ownable {
    // A map of the player and their corresponding random number request
    mapping(address => uint256) public playerRequestID;
    // A map that stores the users coinflip guess
    mapping(addrss => uint8) public bets;
    // An instance of the random number requester, client interface
    VRFv2DirectFundingConsumer private vrfRequestor;

    ///@dev we no longer use the seed, instead each coinflip should spawn its own VRF instance
    ///@notice This programming pattern is a factory model - a contract creating other contracts 
    constructor(address _vrfRequestor) Ownable(msg.sender) {
        vrfRequestor = VRFv2DirectFundingConsumer(_vrfRequestor);
    }

    ///@notice Fund the VRF instance with **2** LINK tokens.
    ///@return A boolean of whether funding the VRF instance with link tokens was successful or not
    ///@dev use the address of LINK token contract provided. Do not change the address!
    ///@custom:attention In order for this contract to fund another contract, which tokens does it require to have before calling this function?
    ///                  What **additional** functions does this contract need to receive these tokens itself?
    function fundOracle() external returns(bool){
        address linkAddr = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
        uint256 amount = 2 * 10**18; // 2 LINK tokens in wei
        // Implement logic to transfer 2 LINK tokens to the VRF instance
        // Return true if the funding is successful
        require(linkAddr.balance >= amount, "Insufficient LINK balance");
        payable(address(vrfRequestor)).transfer(amount);
        return true;
    }


    ///@notice user guess only ONE flip either a 1 or a 0.
    ///@param Guess uint8 which is required to be 1 or 0
    ///@dev After validating the user input, store the user input in global mapping and fire off a request to the VRF instance
    ///@dev Then, store the requestid in global mapping
    function userInput(uint8 Guess) external {
        require(Guess == 0 || Guess == 1, "Invalid guess. It should be either 0 or 1");
        bets[msg.sender] = Guess;
        uint256 requestId = vrfRequestor.requestRandomness();
        playerRequestID[msg.sender] = requestId;
    }

    ///@notice due to the fact that a blockchain does not deliver data instantaneously, in fact quite slowly under congestion, allow
    ///        users to check the status of their request.
    ///@return a boolean of whether the request has been fulfilled or not
    function checkStatus() external view returns(bool){
        uint256 requestId = playerRequestID[msg.sender];
        return vrfRequestor.isRequestFulfilled(requestId);
    }

    ///@notice once the request is fulfilled, return the random result and check if user won
    ///@return a boolean of whether the user won or not based on their input
    ///@dev request the randomWord that is returned.
    ///@dev compare the user guess with the generated flip and return if these two inputs match.
    function determineFlip() external view returns(bool){
        uint256 requestId = playerRequestID[msg.sender];
        require(vrfRequestor.isRequestFulfilled(requestId), "Request not fulfilled yet");
        uint256 randomNumber = vrfRequestor.getRandomNumber(requestId);
        uint8 flip = uint8(randomNumber) % 2;
        return flip == bets[msg.sender];
    }
}
