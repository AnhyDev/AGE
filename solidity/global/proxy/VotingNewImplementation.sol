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

import "./VoteUtility.sol";

// This contract extends BaseUtilityAndOwnable and is responsible for voting on new implementations
abstract contract VotingNewImplementation is VoteUtility {

    // Internal state variables to store proposed implementation and voting results
    address internal _proposedImplementation;
    VoteResult internal _votesForNewImplementation;

    // Event about the fact of voting, parameters
    event VotingForNewImplementation(address indexed addressVoter, bool indexed vote);
    // Event about the fact of making a decision on voting,
    event VotingCompletedForNewImplementation(address indexed decisiveVote, bool indexed result, uint votesFor, uint votesAgainst);
    // The event of the closing of voting, the period of which has expired
    event CloseVoteForNewImplementation(address indexed decisiveVote, uint votesFor, uint votesAgainst);


    // Function to initiate the voting process for a new implementation.
    function initiateVotingForNewImplementation(address _proposed) public proxyOwner {
        require(_proposed != address(0), "VotingNewImplementation: Cannot set null address");
        require(_implementation() != _proposed, "VotingNewImplementation: This vote will not change the implementation address");
        require(_proposedImplementation == address(0), "VotingNewImplementation: Voting has already started");
        require(_checkContract(_proposed), "VotingNewImplementation: The contract does not meet the standard");
        _proposedImplementation = _proposed;
        _votesForNewImplementation.timestamp = block.timestamp;
        _voteForNewImplementation(true);
    }

    // Function for owners to vote for the proposed new implementation
    function voteForNewImplementation(bool vote) public proxyOwner {
        _voteForNewImplementation(vote);
    }
    // Internal function to handle the logic for voting for the proposed new implementation
    function _voteForNewImplementation(bool vote) internal hasNotVoted(_votesForNewImplementation) {
        require(_proposedImplementation != address(0), "VotingNewImplementation: There is no active voting on this issue");

        (uint256 votestrue, uint256 votesfalse, VoteResultType result) = _votes(_votesForNewImplementation, vote);

        emit VotingForNewImplementation(msg.sender, vote);

        if (result == VoteResultType.Approved) {
            _implementationAGE = _proposedImplementation;
            _completionVotingImplementation(vote, votestrue, votesfalse);
        } else if (result == VoteResultType.Rejected) {
            _completionVotingImplementation(vote, votestrue, votesfalse);
        }
    }

    // Completion of voting
    function _completionVotingImplementation(bool vote, uint256 votestrue, uint256 votesfalse) internal {
        emit VotingCompletedForNewImplementation(msg.sender, vote, votestrue, votesfalse);
        _resetVote(_votesForNewImplementation);
        _proposedImplementation = address(0);
    }

    // Function to close the voting for a new implementation
    function closeVoteForNewImplementation() public proxyOwner {
        require(_proposedImplementation != address(0), "VotingNewImplementation: There is no open vote");
        emit CloseVoteForNewImplementation(msg.sender, _votesForNewImplementation.isTrue.length, _votesForNewImplementation.isFalse.length);
        _closeVote(_votesForNewImplementation);
        _proposedImplementation = address(0);
    }

    // Function to get the status of voting for the proposed new implementation
    function getVoteForNewImplementationStatus() public view returns (address, uint256, uint256, uint256) {
        return _getVote(_votesForNewImplementation, _proposedImplementation);
    }
}
