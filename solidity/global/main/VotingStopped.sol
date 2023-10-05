// SPDX-License-Identifier: Apache License 2.0
/*
 * Copyright (C) 2023 Anhydrite Gaming Ecosystem
 *
 * This code is part of the Anhydrite Gaming Ecosystem.
 *
 * ERC-20 Token: Anhydrite ANH
 * Network: Binance Smart Chain
 * Website: https://anh.ink
 * GitHub: https://github.com/Anhydr1te/AnhydriteGamingEcosystem
 *
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that explicit attribution to the original code and website
 * is maintained. For detailed terms, please contact the Anhydrite Gaming Ecosystem team.
 *
 * Portions of this code are derived from OpenZeppelin contracts, which are licensed
 * under the MIT License. Those portions are not subject to this license. For details,
 * see https://github.com/OpenZeppelin/openzeppelin-contracts
 *
 * This code is provided as-is, without warranty of any kind, express or implied,
 * including but not limited to the warranties of merchantability, fitness for a 
 * particular purpose, and non-infringement. In no event shall the authors or 
 * copyright holders be liable for any claim, damages, or other liability, whether 
 * in an action of contract, tort, or otherwise, arising from, out of, or in connection 
 * with the software or the use or other dealings in the software.
 */

// @filepath Repository Location: [solidity/global/proxy/VotingStopped.sol]

pragma solidity ^0.8.19;

import "./BaseMain.sol";
import "../common/VoteUtility.sol";

//This contract extends BaseUtilityAndOwnable and is responsible for voting to stop/resume services
abstract contract VotingStopped is VoteUtility, BaseMain {


    VoteResult internal _votesForStopped;
    bool internal _proposedStopped = false;

    // Event about the fact of voting, parameters
    event VotingForStopped(address indexed addressVoter, bool indexed vote);
    // Event about the fact of making a decision on voting,
    event VotingCompletedForStopped(address indexed decisiveVote, bool indexed result, uint votesFor, uint votesAgainst);
    // The event of the closing of voting, the period of which has expired
    event CloseVoteForStopped(address indexed decisiveVote, uint votesFor, uint votesAgainst);


    // Initiates vote for stopping/resuming services
    function initiateVotingForStopped(bool _proposed) public proxyOwner {
        require(_stopped != _proposed, "VotingStopped: This vote will not change the Stop status");
        require(_proposed != _proposedStopped, "VotingStopped: Voting has already started");
        _proposedStopped = _proposed;
        _votesForStopped.timestamp = block.timestamp;
        _voteForStopped(true);
    }

    // Vote for stopping/resuming services
    function voteForStopped(bool vote) public proxyOwner {
        _voteForStopped(vote);
    }
    // Internal function to handle the vote logic
    function _voteForStopped(bool vote) internal {
        _checkOwnerVoted(_votesForStopped);
        require(_stopped != _proposedStopped, "VotingStopped: There is no active voting on this issue");

        (uint256 votestrue, uint256 votesfalse, VoteResultType result) = _votes(_votesForStopped, vote);

        emit VotingForStopped(msg.sender, vote);

        if (result == VoteResultType.Approved) {
            _stopped = _proposedStopped;
           _completionVotingStopped(vote, votestrue, votesfalse);
            
       } else if (result == VoteResultType.Rejected) {
           _proposedStopped = _stopped;
           _completionVotingStopped(vote, votestrue, votesfalse);
        }
    }

    // Completion of voting
    function _completionVotingStopped(bool vote, uint256 votestrue, uint256 votesfalse) internal {
         emit VotingCompletedForStopped(msg.sender, vote, votestrue, votesfalse);
        _resetVote(_votesForStopped);
    }

    // Close the vote manually
    function closeVoteForStopped() public proxyOwner {
        require(_stopped != _proposedStopped, "VotingStopped: There is no open vote");
        emit CloseVoteForStopped(msg.sender, _votesForStopped.isTrue.length, _votesForStopped.isFalse.length);
        _closeVote(_votesForStopped);
        _proposedStopped = _stopped;
    }

    // Get current vote status
    function getVoteForStopped() public view returns (bool, uint256, uint256, uint256) {
            return (
            _proposedStopped != _stopped,
            _votesForStopped.isTrue.length, 
            _votesForStopped.isFalse.length, 
            _votesForStopped.timestamp
        );
    }
}

