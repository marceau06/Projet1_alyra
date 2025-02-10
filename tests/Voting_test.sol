// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
import "remix_tests.sol"; // this import is automatically injected by Remix.
import "hardhat/console.sol";
import "../contracts/Voting.sol";

contract VotingTest {

    // bytes32[] proposalNames;

    address[] votersList = [0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db, 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB, 0x617F2E2fD72FD9D5503197092aC168c91465E7f2];

    Voting votingToTest;

    function beforeAll () public {
        votingToTest = new Voting();
        for (uint i = 0; i < votersList.length; i++) {
            votingToTest.registerVoter(votersList[i]);
        }
    }

    // function checkWinningProposal () public {
    //     console.log("Running checkWinningProposal");
    //     ballotToTest.vote(0);
    //     Assert.equal(ballotToTest.winningProposal(), uint(0), "proposal at index 0 should be the winning proposal");
    //     Assert.equal(ballotToTest.winnerName(), bytes32("candidate1"), "candidate1 should be the winner name");
    // }

    // function checkWinninProposalWithReturnValue () public view returns (bool) {
    //     return ballotToTest.winningProposal() == 0;
    // }
}