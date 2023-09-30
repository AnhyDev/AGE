// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/*
 * Copyright (C) 2023 Anhydrite Gaming Ecosystem
 *
 * This code is part of the Anhydrite Gaming Ecosystem.
 *
 * ERC-20 Token: Anhydrite ANH
 * Network: Binance Smart Chain
 * Website: https://anh.ink
 *
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that explicit attribution to the original code and website
 * is maintained. For detailed terms, please contact the Anhydrite Gaming Ecosystem team.
 *
 * This code is provided as-is, without warranty of any kind, express or implied,
 * including but not limited to the warranties of merchantability, fitness for a 
 * particular purpose, and non-infringement. In no event shall the authors or 
 * copyright holders be liable for any claim, damages, or other liability, whether 
 * in an action of contract, tort, or otherwise, arising from, out of, or in connection 
 * with the software or the use or other dealings in the software.
 */

//An abstract contract for voting on changing the owner of this smart contract
abstract contract OwnableManager is BaseProxyVoting {

 // Proposed new owner
 address internal _proposedOwner;
 // Structure for counting votes
 VoteResult internal _votesForNewOwner;

 // Event about the fact of voting, parameters: voter, proposedOwner, vote
 event VotingForOwner(address indexed voter, address proposedOwner, bool vote);
 // Event about the fact of making a decision on voting, parameters: voter, proposedOwner, vote, votesFor, votesAgainst
 event VotingOwnerCompleted(address indexed voter, address proposedOwner, bool vote, uint votesFor, uint votesAgainst);


 // Overriding the transferOwnership function, which now triggers the start of a vote to change the owner of a smart contract
 function transferOwnership(address proposedOwner) public override virtual onlyProxyOwner(msg.sender) {
     require(!_isActiveForVoteOwner(), "OwnableManager: voting is already activated");
     if (address(_proxyContract) != address(0)) {
         require(!_proxyContract.isBlacklisted(proposedOwner), "OwnableManager: this address is blacklisted");
         require(_isProxyOwner(proposedOwner), "OwnableManager: caller is not the proxy owner");
     }

     _proposedOwner = proposedOwner;
     _votesForNewOwner = VoteResult(new address[](0), new address[](0), block.timestamp);
     _voteForNewOwner(true);
 }

 // Vote For New Owner
 function voteForNewOwner(bool vote) external onlyProxyOwner(msg.sender) {
     _voteForNewOwner(vote);
 }

 // Votes must reach a 60% threshold to pass. If over 40% are downvotes, the measure fails.
 function _voteForNewOwner(bool vote) internal hasNotVoted(_votesForNewOwner) {
     require(_isActiveForVoteOwner(), "OwnableManager: there are no votes at this address");

     (uint votestrue, uint votesfalse, uint256 _totalOwners) = _votes(_votesForNewOwner, vote);

     emit VotingForOwner(msg.sender, _proposedOwner, vote);

     if (votestrue * 100 >= _totalOwners * 60) {
         _transferOwnership(_proposedOwner);
         _resetVote(_votesForNewOwner);
         emit VotingOwnerCompleted(msg.sender, _proposedOwner, vote, votestrue, votesfalse);
         _proposedOwner = address(0);
     } else if (votesfalse * 100 > _totalOwners * 40) {
         _resetVote(_votesForNewOwner);
         emit VotingOwnerCompleted(msg.sender, _proposedOwner, vote, votestrue, votesfalse);
         _proposedOwner = address(0);
     }
 }

 // A function to close a vote on which a decision has not been made for three or more days
 function closeVoteForNewOwner() public onlyOwner {
     require(_proposedOwner != address(0), "There is no open vote");
     _closeVote(_votesForNewOwner);
     _proposedOwner = address(0);
 }

 // Check if voting is enabled for new contract owner and their address.
 function getActiveForVoteOwner() external view returns (address) {
     require(_isActiveForVoteOwner(), "OwnableManager: re is no active voting");
     return _proposedOwner;
 }

 // Function to check if the proposed Owner address is valid
 function _isActiveForVoteOwner() internal view returns (bool) {
     return _proposedOwner != address(0) && _proposedOwner !=  owner();
 }
}