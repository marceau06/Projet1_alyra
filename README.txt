I. Déroulé et Utilisation

1) L'administrateur du vote enregistre une liste blanche d'électeurs identifiés par leur adresse Ethereum.
   registerVoter()
   
2) L'administrateur du vote commence la session d'enregistrement de la proposition.
   startProposalSession()

3) Les électeurs inscrits sont autorisés à enregistrer leurs propositions pendant que la session d'enregistrement est active.
   propose()
   
4) L'administrateur de vote met fin à la session d'enregistrement des propositions.
   endProposalSession()

5) L'administrateur du vote commence la session de vote.
   startVoteSession()
   
6) Les électeurs inscrits votent pour leur proposition préférée.
   Vote()

7) L'administrateur du vote met fin à la session de vote.
   endVoteSession()

8) L'administrateur du vote comptabilise les votes.
   talliedVotes()
   - Si il y a plusieurs gagnant, l'admin doit voter pour choisir le gagnant

9) Tout le monde peut vérifier les derniers détails de la proposition gagnante.
   getWinnerProposal()

II. Ajout dans VotingPlus.sol (non terminé)

Une fonction pour avoir l'adresse qui a fourni la proposition gagnante
Un reset 
Un fichier de test (non terminé) dans /tests/