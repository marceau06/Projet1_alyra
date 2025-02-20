// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";

contract VotingPlus is Ownable {

    //////////////////////////////////////////////// Variables ///////////////////////////////////////////////
    
    // Votant
    struct Voter { bool isRegistered; bool hasVoted; uint votedProposalId; } 
    
    // Proposition
    struct Proposal { string description; uint voteCount; address voter; }

    // Whitelist des votants
    mapping(address => Voter) whitelistVoter;

    // Liste des propositions
    Proposal[] proposals;

    // Liste des addresses des votants
    address[] voterRegisteredAddress;

    // Gère les différents états d’un vote
    enum WorkflowStatus { RegisteringVoters, ProposalsRegistrationStarted, ProposalsRegistrationEnded, VotingSessionStarted, VotingSessionEnded, VotesTallied }

    // Statut de la session actuelle
    WorkflowStatus currentStatus = WorkflowStatus.RegisteringVoters;

    // Id de la proposition gagnante
    uint private winningProposalId; 

    // Nombre de votants
    uint private voterCount; 

    // Nombre de votes
    uint private voteCountTotal;

    // Nombre de gagnants
    uint private winnerCount; 

    // Nombre de votes de la proposition gagnante
    uint private voteWinnerCount = 1; 

    // Evenements
    event VoterRegistered(address voterRegisteredAddress);
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted(address voter, uint proposalId);
    
    //////////////////////////////////////////////// Constructeur ////////////////////////////////////////////////

    constructor() Ownable(msg.sender) {
    }

    
    // Vérifier que l'adresse est dans la whitelist  
    function checkIfRegistered(address _address) public view returns (bool) {
        return whitelistVoter[_address].isRegistered;
    }


    //////////////////////////////////////////////// Fonctions Owner ////////////////////////////////////////////////

    // Enregistrer un votant
    function registerVoter(address _address) external onlyOwner {
        require(currentStatus == WorkflowStatus.RegisteringVoters, "You are not in voter registration period");
        require(checkIfRegistered(_address) == false, "You already have add this adress");

        Voter memory voter = Voter(true, false, 0);
        whitelistVoter[_address] = voter;
        voterRegisteredAddress.push(_address);
        voterCount++;
        emit VoterRegistered(_address);
    }
  

    //////////////////////////////////////////////// Fonctions électeurs ////////////////////////////////////////////////

    // Permet à une adresse de faire une proposition
    function propose(string memory _proposal) external {
        require(currentStatus == WorkflowStatus.ProposalsRegistrationStarted, "The proposal session is not started"); 
        require(owner() != msg.sender, "You are the owner of this contract, you can not propose");
        require(checkIfRegistered(msg.sender) == true, "You are not registered");

        proposals.push(Proposal({
                description: _proposal,
                voteCount: 0,
                voter: msg.sender
        }));
        emit ProposalRegistered(proposals.length);
    }

    // Permet à une adresse de voter
    function vote(uint _proposald) external restrictOwnerToVote {
        require(_proposald < proposals.length, "This proposal ID does not exists");
        whitelistVoter[msg.sender].hasVoted = true;
        whitelistVoter[msg.sender].votedProposalId = _proposald;
        proposals[_proposald].voteCount++;
        voteCountTotal++;
        emit Voted(msg.sender, _proposald);
    } 

    // Restreindre le droit de vote du Owner 
    modifier restrictOwnerToVote(){
        if(owner() == msg.sender) {
            require(winnerCount > 1, "You can only vote if there is more than 1 winner");
            winnerCount = 1;
        } else {
            require(currentStatus == WorkflowStatus.VotingSessionStarted, "The voting session is not started"); 
            require(checkIfRegistered(msg.sender) == true, "You are not registered");
            require(whitelistVoter[msg.sender].hasVoted == false, "You already voted");
        }
        _;
    }


    //////////////////////////////////////////////// Fonctions changement de statut de session ////////////////////////////////////////////////

    function startProposalSession() external onlyOwner {
        require(currentStatus ==  WorkflowStatus.RegisteringVoters, "You can not start again the proposal session");
        require(voterCount > 1, "You must register at least 2 addresses");
        currentStatus = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(WorkflowStatus(uint(currentStatus) - 1), currentStatus);
    }

    function endProposalSession() external onlyOwner {
        require(currentStatus ==  WorkflowStatus.ProposalsRegistrationStarted, "The proposal session has not started or has already been ended");
        require(proposals.length > 0, "There are no proposals registered");
        currentStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus(uint(currentStatus) - 1), currentStatus);
    }


    function startVoteSession() external onlyOwner {
        require(currentStatus ==  WorkflowStatus.ProposalsRegistrationEnded, "The proposal session is not ended or the vote session has already started");
        currentStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus(uint(currentStatus) - 1), currentStatus);
    }


    function endVoteSession() external onlyOwner {
        require(currentStatus ==  WorkflowStatus.VotingSessionStarted, "The vote session has not started or has already ended");
        require(voteCountTotal > 0, "There are no vote registered");
        currentStatus = WorkflowStatus.VotingSessionEnded;
        calculateWinnerProposal(); 
        emit WorkflowStatusChange(WorkflowStatus(uint(currentStatus) - 1), currentStatus);
       
    }

    function votesTallied() external onlyOwner {
        require(currentStatus ==  WorkflowStatus.VotingSessionEnded, "The vote session is not ended");
        require(winnerCount == 1, "There is more than 1 winner, you have to vote");
        currentStatus = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(WorkflowStatus(uint(currentStatus) - 1), currentStatus);
    }

    function reset() external onlyOwner {
        require(currentStatus ==  WorkflowStatus.VotesTallied, "The last vote has not been tallied");
        // Réinitialiser le mapping des votants
        for (uint i = 0; i < voterRegisteredAddress.length; i++) {
            whitelistVoter[voterRegisteredAddress[i]] = Voter({ isRegistered: false, hasVoted: false, votedProposalId: 0 });
        }
        delete proposals;
        delete voterRegisteredAddress;
        winnerCount = 0;        
        winningProposalId = 0; 
        voterCount = 0;
        voteCountTotal = 0;
        voteWinnerCount = 1;
        currentStatus = WorkflowStatus.RegisteringVoters;
    }

    //////////////////////////////////////////////// Fonctions getter et setter ////////////////////////////////////////////////

    function getAddressByProposalId(uint _proposalId) external view returns(address){
        require(currentStatus >=  WorkflowStatus.ProposalsRegistrationStarted, "The proposal session has not started");
        // Vérifier que la proposition existe
        require(_proposalId < proposals.length, "This proposal ID does not exists");
        // Vérifier que l'adresse a été ajoutée à la whitelist
        require(checkIfRegistered(proposals[_proposalId].voter) == true, "This address is not registered");
        
        return proposals[_proposalId].voter;
    }

    function getVoteByAddress(address _address) external view returns(Proposal memory){
        // Vérifier que l'adresse a été ajoutée à la whitelist
        require(checkIfRegistered(_address) == true, "This address is not registered");
        require(whitelistVoter[_address].hasVoted == true, "This address has not voted");

        uint votedProposalId = whitelistVoter[_address].votedProposalId;
        return proposals[votedProposalId];
    }

    // Calculer la proposition gagnante
    function calculateWinnerProposal() private onlyOwner {
        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount >= voteWinnerCount) {
                voteWinnerCount = proposals[i].voteCount;
                winningProposalId = i;
                winnerCount++;
            }      
        } 
    }

     // Retourne la proposition gagnante   
    function getWinnerProposal() external view returns (Proposal memory) {
        require(currentStatus ==  WorkflowStatus.VotesTallied, "The winner have not been choosen yet");
        return proposals[winningProposalId];
    }

    // Retourne la description de la proposition gagnante 
    function getWinnerProposalDescription() external view returns (string memory) {
        require(currentStatus ==  WorkflowStatus.VotesTallied, "The winner have not been choosen yet");
        return proposals[winningProposalId].description;
    }

    // Retourne l'id de la proposition gagnante 
    function getWinnerProposalId() external view returns (uint) {
        require(currentStatus ==  WorkflowStatus.VotesTallied, "The winner have not been choosen yet");
        return winningProposalId;
    }

    // Retourne le statut actuel de la session
    function getCurrentStatus() external view returns (WorkflowStatus) {
        return currentStatus;
    }

    // Retourne le statut précédent de la session actuelle
    function getPreviousStatus() external view returns (WorkflowStatus) {
        return WorkflowStatus(uint(currentStatus) - 1);
    }

    // Retourne le nombre de propositions  
    function getProposalCount() external view returns(uint){
        return proposals.length;
    }

    // Retourne les propositions  
    function getProposals() external view returns(Proposal[] memory){
        return proposals;
    }

    // Retourne le nombre actuel de votant
    function getVoterCount() external view returns(uint){
        return voterCount;
    }

    // Retourne le nombre actuel de votes
    function getVoteCountTotal() external view returns(uint){
        return voteCountTotal;
    }

    // Retourne le nombre actuel de gagnants
    function getWinnerCount() external view returns(uint){
        return winnerCount;
    }

    // Retourne le nombre de vote de la proposition gagnante
    function getVoteWinnerCount() external view returns(uint){
        return voteWinnerCount;
    }

    function isRegistered(address _address) external view returns(bool){
        return checkIfRegistered(_address);
    }

    function getVoterRegisteredAddress() external view returns(address[] memory){
        return voterRegisteredAddress;
    }
}