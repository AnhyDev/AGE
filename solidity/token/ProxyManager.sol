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

//Abstract contract to vote on smart contract proxy replacement
abstract contract ProxyManager is BaseProxyVoting {

 // A new smart contract proxy address is proposed
 address internal _proposedProxy;
 // Structure for counting votes
 VoteResult internal _votesForNewProxy;

 // Event about the fact of voting, parameters: voter, proposedProxy, vote
 event VotingForNewProxy(address indexed voter, address proposedProxy, bool vote);
 // Event about the fact of making a decision on voting, parameters: voter, proposedProxy, vote, votesFor, votesAgainst
 event VotingONewProxyCompleted(address indexed voter, address proposedProxy, bool vote, uint votesFor, uint votesAgainst);


 // Voting start initiation, parameters: proposedNewProxy
 function initiateNewProxy(address proposedNewProxy) public onlyProxyOwner(msg.sender) {
     require(!_isActiveForVoteNewProxy(), "ProxyManager: voting is already activated");
     require(_checkIProxyContract(proposedNewProxy), "ProxyManager: This address does not represent a contract that implements the IProxy interface.");

     _proposedProxy = proposedNewProxy;
     _votesForNewProxy = VoteResult(new address[](0), new address[](0), block.timestamp);
     _voteForNewProxy(true);
 }

 // Vote
 function voteForNewProxy(bool vote) external onlyProxyOwner(msg.sender) {
     _voteForNewProxy(vote);
 }

 // Votes must reach a 70% threshold to pass. If over 30% are downvotes, the measure fails.
 function _voteForNewProxy(bool vote) internal hasNotVoted(_votesForNewProxy) {
     require(_isActiveForVoteNewProxy(), "ProxyManager: there are no votes at this address");

     (uint votestrue, uint votesfalse, uint256 _totalOwners) = _votes(_votesForNewProxy, vote);

     emit VotingForNewProxy(msg.sender, _proposedProxy, vote);

     if (votestrue * 100 >= _totalOwners * 70) {
         _proxyContract = IProxy(_proposedProxy);
         _resetVote(_votesForNewProxy);
         emit VotingONewProxyCompleted(msg.sender, _proposedProxy, vote, votestrue, votesfalse);
         _proposedProxy = address(0);
     } else if (votesfalse * 100 > _totalOwners * 30) {
         _resetVote(_votesForNewProxy);
         emit VotingONewProxyCompleted(msg.sender, _proposedProxy, vote, votestrue, votesfalse);
         _proposedProxy = address(0);
     }
 }

 // A function to close a vote on which a decision has not been made for three or more days
 function closeVoteForNewProxy() public onlyOwner {
     require(_proposedProxy != address(0), "There is no open vote");
     _closeVote(_votesForNewProxy);
     _proposedProxy = address(0);
 }

 // A function for obtaining information about the status of voting
 function getActiveForVoteNewProxy() external view returns (address) {
     require(_isActiveForVoteNewProxy(), "OwnableManager: re is no active voting");
     return _proposedProxy;
 }

 // Function to check if the proposed address is valid
 function _isActiveForVoteNewProxy() internal view returns (bool) {
     return _proposedProxy != address(0) && _proposedProxy !=  address(_proxyContract);
 }
}