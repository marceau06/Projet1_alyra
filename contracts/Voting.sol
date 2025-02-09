// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";


contract Voting is Ownable {


    // mapping(address => Proposal) proposalAddress; // 
    
    mapping(address => Voter) votersAddresses; //  

    // Tableau pour afficher les propositions
    // mapping(address => Proposal)[] public proposals;
    Proposal[] public proposals;


    // id du gagnant
    uint256 winningProposalId; 

    // Numéro du votant
    uint256 voterNumber = 1; 

    // Numéro de la proposition
    uint proposalNumber;

    // Evenements
    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted(address voter, uint proposalId);

    // STRUCTURE VOTER
    struct Voter { bool isRegistered; bool hasVoted; uint votedProposalId; } 
    
    // STRUCTURE PROPOSAL
    struct Proposal { string description; uint voteCount; }
    
    // gère les différents états d’un vote
    enum WorkflowStatus { RegisteringVoters, ProposalsRegistrationStarted, ProposalsRegistrationEnded, VotingSessionStarted, VotingSessionEnded, VotesTallied }

     // Statut de la session précédente
    WorkflowStatus public previousStatus;

    // Statut de la session
    WorkflowStatus public currentStatus = WorkflowStatus.RegisteringVoters;



    // Constructeur
    constructor() Ownable(msg.sender) {
            proposals.push(Proposal({
                description: "_proposal",
                voteCount: 0
            }));

    }

    

    function getWinner() external {

    }

    function getWinnerProposal() external view returns (string memory) {
        uint max = proposals[0].voteCount;
        string memory winner = proposals[0].description;
        for (uint256 i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > max) {
                max = proposals[i].voteCount;
                winner = proposals[i].description;
            }      
        } 
        return winner;
    }
    
    function showProposals() external view returns (string memory){
        // Remplir le tableau avec les valeurs de balance correspondant à chaque adresse
        string memory proposalList;
        for (uint256 i = 0; i < proposals.length; i++) {
            // concatenateStrings(proposalList, proposals[i].description);
            bytes memory concatenatedBytes = abi.encodePacked(proposalList, proposals[i].description);

            proposalList = string(concatenatedBytes);
        }
        return proposalList;
    } 

    function registerVoter(address _voterAddress) external onlyOwner {
        require(currentStatus == WorkflowStatus.RegisteringVoters, "You are not in voter registration period");
        
        Voter memory voter = Voter(true, false, voterNumber);
        voterNumber++;

        votersAddresses[_voterAddress] = voter;
        
    }

    function propose(string memory _proposal) external returns (string memory){
        require(currentStatus == WorkflowStatus.ProposalsRegistrationStarted, "The registration period is not started"); 
        require(votersAddresses[msg.sender].isRegistered == true, "You are not registered");

        // proposals[0] = Proposal(_proposal, 0);
        // proposals[proposalNumber].description = _proposal;
        // proposals[0].description = _proposal;

        // proposals[proposalNumber][msg.sender].voteCount++;

        proposals.push(Proposal({
                description: _proposal,
                voteCount: 0
            }));
        
        proposalNumber++;

        return "Ok proposal registered";
    }

    function vote(uint256 _vote) external {
        // require(currentStatus == WorkflowStatus.VotingSessionStarted, "The voting session is not started"); //
        // require(votersAddresses[msg.sender].isRegistered != true, "You are not registered");
        // require(_vote > proposals.length, "Le numero de proposition n'existe pas");
        
        votersAddresses[msg.sender].hasVoted = true;
        votersAddresses[msg.sender].votedProposalId = _vote;
        proposals[_vote].voteCount++;

    }   

    function getProposalLength() external view returns(uint){
        return proposals.length;
    }

    function getVoterIDByAddress(address _address) external view returns(uint){
        return votersAddresses[_address].votedProposalId;
    }


    function startProposalSession() external onlyOwner {
        require(currentStatus ==  WorkflowStatus.RegisteringVoters, "You can not start again the proposal session");
        currentStatus = WorkflowStatus.ProposalsRegistrationStarted;
    }


    function endProposalSession() external onlyOwner {
        require(currentStatus ==  WorkflowStatus.ProposalsRegistrationStarted, "The proposal session is not started");
        currentStatus = WorkflowStatus.ProposalsRegistrationEnded;
    }


    function startVoteSession() external onlyOwner {
        require(currentStatus ==  WorkflowStatus.ProposalsRegistrationEnded, "The proposal session did not take place or is not ended");
        currentStatus = WorkflowStatus.VotingSessionStarted;
    }


    function endVoteSession() external onlyOwner {
        require(currentStatus ==  WorkflowStatus.VotingSessionStarted, "The proposal session did not take place or is not ended");
        currentStatus = WorkflowStatus.VotingSessionEnded;
    }


    function votesTallied() external onlyOwner {
        require(currentStatus ==  WorkflowStatus.VotingSessionEnded, "Vote session has not ended");
        currentStatus = WorkflowStatus.VotesTallied;
    }


    function getCurrentStatus() external view returns (WorkflowStatus) {
        return currentStatus;
    }

    function concatenateStrings(string memory a, string memory b) public pure returns (string memory) {
        bytes memory concatenatedBytes = abi.encodePacked(a, b);
        return string(concatenatedBytes);
    }


    // function deposit() external payable onlyOwner {
    //     require(msg.value > 0, "Not enough funds provided");
    //     deposits[depositNumber] = msg.value;
    //     depositNumber=depositNumber+1;
    //     if(time == 0) {
    //         time = block.timestamp + 90 days;
    //     }
    // }

    // function withdraw() external onlyOwner {
    //     require(block.timestamp >= time, "Wait 3 months after the first deposit to withdraw");
    //     require(address(this).balance > 0, "No Ethers on the contract");
    //     (bool sent,) = payable(msg.sender).call{value: address(this).balance}("");
    //     require(sent, "An error occured");
    // }



}