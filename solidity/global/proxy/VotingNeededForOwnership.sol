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
pragma solidity ^0.8.19;

import "./BaseProxy.sol";
import "../common/VoteUtility.sol";


// This contract extends BaseUtilityAndOwnable and is responsible for voting to tokens required for ownership rights
abstract contract VotingNeededForOwnership is VoteUtility, BaseProxy {


    // Holds the proposed new token count needed for voting rights
    uint256 internal _proposedTokensNeeded;
    // Holds the vote results for the proposed token count
    VoteResult internal _votesForTokensNeeded;

    // Event triggered when a vote is cast
    event VotingForTokensNeeded(address indexed addressVoter, bool indexed vote);
    // Event triggered when a voting round ends
    event VotingCompletedForTokensNeeded(address indexed decisiveVote, bool indexed result, uint votesFor, uint votesAgainst);
    // Event triggered when a vote is manually closed
    event CloseVoteForTokensNeeded(address indexed decisiveVote, uint votesFor, uint votesAgainst);


    // Initialize voting to change required token count for voting rights
    function initiateVotingForNeededForOwnership(uint256 _proposed) public proxyOwner {
        require(_proposed != 0, "VotingNeededForOwnership: The supply of need for ownership tokens cannot be zero");
        require(_tokensNeededForOwnership != _proposed, "VotingNeededForOwnership: This vote will not change the need for ownership tokens");
        require(_proposedTokensNeeded == 0, "VotingNeededForOwnership: Voting has already started");
        _proposedTokensNeeded = _proposed;
        _votesForTokensNeeded.timestamp = block.timestamp;
        _voteForNeededForOwnership(true);
    }

    // Cast a vote for changing required token count
    function voteForNeededForOwnership(bool vote) public proxyOwner {
        _voteForNeededForOwnership(vote);
    }
    // Internal function to handle the vote logic
    function _voteForNeededForOwnership(bool vote) internal {
        _checkOwnerVoted(_votesForTokensNeeded);
        require(_proposedTokensNeeded != 0, "VotingNeededForOwnership: There is no active voting on this issue");

        (uint256 votestrue, uint256 votesfalse, VoteResultType result) = _votes(_votesForTokensNeeded, vote);

        emit VotingForTokensNeeded(msg.sender, vote);

        if (result == VoteResultType.Approved) {
            _tokensNeededForOwnership = _proposedTokensNeeded;
            _completionVotingNeededOwnership(vote, votestrue, votesfalse);
       } else if (result == VoteResultType.Rejected) {
            _completionVotingNeededOwnership(vote, votestrue, votesfalse);
        }
    }

    // Completion of voting
    function _completionVotingNeededOwnership(bool vote, uint256 votestrue, uint256 votesfalse) internal {
        emit VotingCompletedForTokensNeeded(msg.sender, vote, votestrue, votesfalse);
        _resetVote(_votesForTokensNeeded);
        _proposedTokensNeeded = 0;
    }

    // Close the vote manually
    function closeVoteForTokensNeeded() public proxyOwner {
        require(_proposedTokensNeeded != 0, "VotingNeededForOwnership: There is no open vote");
        emit CloseVoteForTokensNeeded(msg.sender, _votesForTokensNeeded.isTrue.length, _votesForTokensNeeded.isFalse.length);
        _closeVote(_votesForTokensNeeded);
        _proposedTokensNeeded = 0;
    }
    
    // Get current vote status
    function getVoteForNewTokensNeeded() public view returns (uint256, uint256, uint256, uint256) {
        return (
            _proposedTokensNeeded, 
            _votesForTokensNeeded.isTrue.length, 
            _votesForTokensNeeded.isFalse.length, 
            _votesForTokensNeeded.timestamp
        );
    }
}