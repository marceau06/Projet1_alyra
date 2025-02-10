// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;
import "remix_tests.sol"; // this import is automatically injected by Remix.
import "../contracts/VotingPlus.sol";

contract VotingTest {

    enum WorkflowStatus { RegisteringVoters, ProposalsRegistrationStarted, ProposalsRegistrationEnded, VotingSessionStarted, VotingSessionEnded, VotesTallied }

    address[] votersList = [0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db, 0x617F2E2fD72FD9D5503197092aC168c91465E7f2];

    VotingPlus votingToTest;

    function beforeAll() external {
        votingToTest = new VotingPlus();
    }

    function checkRegisterSession() external {
        for (uint i = 0; i < votersList.length; i++) {
            votingToTest.registerVoter(votersList[i]);
        }
        votingToTest.registerVoter(msg.sender);
        votingToTest.registerVoter(votingToTest.owner());
        votingToTest.startProposalSession();
        Assert.equal(uint(votingToTest.getCurrentStatus()), 1, "Current session status should be 1");
        Assert.equal(votingToTest.checkIfRegistered(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2), true, "Address 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2 should be registered");
        Assert.equal(votingToTest.checkIfRegistered(msg.sender), true, "Address 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2 should be registered");
    }

    function checkProposalSession() external {
        Assert.equal(votingToTest.checkIfRegistered(msg.sender), true, "Address 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2 should be registered");
        votingToTest.transferOwnership(msg.sender);
        votingToTest.propose("Ma proposition 1");
        votingToTest.propose("Ma proposition 2");
        votingToTest.propose("Ma proposition 3");
        Assert.equal(msg.sender, votingToTest.owner(), "address differentes");
    }

}