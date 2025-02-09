// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";

// Si vote n'a pas de max ex
// Empecher de register deux fois le meme votant OK
// Empecher de proposer deux fois le meme votant ou limiter à une seule proposition
// Empecher de lancer la proposal season si pas de votants enregistrés

contract Voting is Ownable {

    //////////////////////////////////////////////// Variables ////////////////////////////////////////////////

    // Whitelist des votants
    mapping(address => Voter) whitelistVoter;

    // Propositions
    Proposal[] proposals;

    // Proposal[] private proposalWinners;


    // Id de la proposition gagnante
    uint256 winningProposalId; 

    // Nombre de votants
    uint256 numberVoter; 

    // Nombre de propositions
    uint numberProposal;

    // Nombdre de gagnants
    uint numberWinners; 

    uint numberWinnersVote;   

    // Evenements
    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted(address voter, uint proposalId);

    // Votant
    struct Voter { bool isRegistered; bool hasVoted; uint votedProposalId; } 
    
    // Proposition
    struct Proposal { string description; uint voteCount; }
    
    // Gère les différents états d’un vote
    enum WorkflowStatus { RegisteringVoters, ProposalsRegistrationStarted, ProposalsRegistrationEnded, VotingSessionStarted, VotingSessionEnded, VotesTallied }

     // Statut de la session précédente
    // WorkflowStatus public previousStatus;

    // Statut de la session actuelle
    WorkflowStatus currentStatus = WorkflowStatus.RegisteringVoters;



    //////////////////////////////////////////////// Constructeur ////////////////////////////////////////////////

    constructor() Ownable(msg.sender) {
        proposals.push(Proposal({
                description: "The winner has not been choosen yet",
                voteCount: 0
        }));
    }


    //////////////////////////////////////////////// Fonctions Owner ////////////////////////////////////////////////

    function registerVoter(address _voterAddress) external onlyOwner {
        require(currentStatus == WorkflowStatus.RegisteringVoters, "You are not in voter registration period");
        require(whitelistVoter[_voterAddress].isRegistered == false, "You already have add this adress");

        Voter memory voter = Voter(true, false, 0);
        whitelistVoter[_voterAddress] = voter;
        numberVoter++;
        emit VoterRegistered(_voterAddress);
    }
  

    //////////////////////////////////////////////// Fonctions électeurs ////////////////////////////////////////////////

    function getProposalsString() external view returns (string memory){
        // Remplir le tableau avec les valeurs de balance correspondant à chaque adresse
        string memory proposalList;
        for (uint256 i = 0; i < proposals.length; i++) {
            bytes memory concatenatedBytes = abi.encodePacked(proposalList, proposals[i].description);
            proposalList = string(concatenatedBytes);
        }
        return proposalList;
    }

    function propose(string memory _proposal) external returns (string memory){
        require(currentStatus == WorkflowStatus.ProposalsRegistrationStarted, "The registration period is not started"); 
        require(owner() != msg.sender, "You are the owner of this contract, you can not propose");
        require(whitelistVoter[msg.sender].isRegistered == true, "You are not registered");

        proposals.push(Proposal({
                description: _proposal,
                voteCount: 0
        }));
        numberProposal++;
        emit ProposalRegistered(numberProposal);

        return "Ok proposal registered";
    }

    function vote(uint256 _vote) external {
        require(currentStatus == WorkflowStatus.VotingSessionStarted, "The voting session is not started"); 
        require(owner() != msg.sender, "You are the owner of this contract, you can not vote");
        require(whitelistVoter[msg.sender].isRegistered == true, "You are not registered");
        require(_vote < proposals.length + 1, "This proposal ID does not exists");
        
        whitelistVoter[msg.sender].hasVoted = true;
        whitelistVoter[msg.sender].votedProposalId = _vote;
        proposals[_vote].voteCount++;

    } 

    modifier check(){
        if(owner() == msg.sender) {
            require(currentStatus == WorkflowStatus.VotingSessionEnded, "You can only vote if there is more than 1 winner");
            _;
        }
    }


    //////////////////////////////////////////////// Fonctions changement de statut de session ////////////////////////////////////////////////

    function startProposalSession() external onlyOwner {
        require(currentStatus ==  WorkflowStatus.RegisteringVoters, "You can not start again the proposal session");
        require(numberVoter > 1, "You must register at least 2 addresses");
        currentStatus = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(WorkflowStatus(uint(currentStatus) + 1), currentStatus);
    }

    function endProposalSession() external onlyOwner {
        require(currentStatus ==  WorkflowStatus.ProposalsRegistrationStarted, "The proposal session has not started or has already been ended");
        currentStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus(uint(currentStatus) + 1), currentStatus);
    }


    function startVoteSession() external onlyOwner {
        require(currentStatus ==  WorkflowStatus.ProposalsRegistrationEnded, "The proposal session is not ended or the vote session has already started");
        currentStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus(uint(currentStatus) + 1), currentStatus);
    }


    function endVoteSession() external onlyOwner {
        require(currentStatus ==  WorkflowStatus.VotingSessionStarted, "The vote session has not started or has already ended");
        currentStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus(uint(currentStatus) + 1), currentStatus);
       
    }


    function votesTallied() external onlyOwner {
        require(currentStatus ==  WorkflowStatus.VotingSessionEnded, "The vote session is not ended");
        setWinnerProposal();
        require(winningProposalId > 0 && numberWinners == 1, "There is more than 1 winner, you have to vote");
        currentStatus = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(WorkflowStatus(uint(currentStatus) + 1), currentStatus);
    }

    //////////////////////////////////////////////// Fonctions getter et setter ////////////////////////////////////////////////

    function setWinnerProposal() private onlyOwner {
        require(currentStatus ==  WorkflowStatus.VotingSessionEnded, "Vote session did not take place or is not ended");
        for (uint256 i = 1; i < proposals.length; i++) {
            if (proposals[i].voteCount > numberWinnersVote) {
                numberWinnersVote = proposals[i].voteCount;
                winningProposalId = i;
                numberWinners++;
                // proposalWinners.push(proposals[i]);
            }      
        } 
    }

    // // Retourne la description de la proposition gagnante
    // function getWinnerProposalString() external view returns (string memory) {
    //     string memory winnersList ;
    //     for (uint256 i = 1; i < proposals.length; i++) {
    //         if (proposals[i].voteCount == winningProposalId) {
    //             concatenateStrings(" Description: ", proposals[i].description);
    //         }      
    //     } 
    // }
    
    function getWinnerProposals() external view returns (Proposal memory) {
        require(currentStatus ==  WorkflowStatus.VotesTallied, "The winner have not been choosen yet");
        return proposals[winningProposalId];
    }


    // Retourne le statut actuel de la session
    function getCurrentStatus() external view returns (WorkflowStatus) {
        return currentStatus;
    }

    // Retourne le nombre de propositions  
    function getProposalLength() external view returns(uint){
        return proposals.length;
    }

    // Retourne le nombre actuel d'électeurs
    function getnumberVoter() external view returns(uint){
        return numberVoter;
    }
    
    // Retourne l'ID de la proposition pour laquelle un électeur a voté
    function getVotedProposalIdByAddress(address _address) external view returns(uint){
        return whitelistVoter[_address].votedProposalId;
    }

    // Retourne la proposition pour laquelle un électeur a voté
    function getVoterVote(address _address) external view returns (string memory) {
        // Vérifier que l'adresse a été ajoutée à la whitelist
        require(whitelistVoter[_address].isRegistered == true, "This address is not registered to the vote");

        uint votedProposalId = whitelistVoter[_address].votedProposalId;
        string memory proposalChoosen = proposals[votedProposalId].description;
        // Vérifier que l'adresse a déjà voté
        if( keccak256(abi.encodePacked(proposalChoosen)) == keccak256(abi.encodePacked(""))) {
            proposalChoosen = "This address has not voted yet";
        }
        return proposalChoosen;
    }

    //////////////////////////////////////////////// Fonctions utiles ////////////////////////////////////////////////

    function concatenateStrings(string memory a, string memory b) public pure returns (string memory) {
        bytes memory concatenatedBytes = abi.encodePacked(a, b);
        return string(concatenatedBytes);
    }


}