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

// @filepath Repository Location: [solidity/global/main/VotingNewAGE.sol]

pragma solidity ^0.8.19;

import "./BaseMain.sol";
import "../common/VoteUtility.sol";

// This contract extends BaseUtilityAndOwnable and is responsible for voting on new AGEs
abstract contract VotingNewAGE is VoteUtility, BaseMain {


    // Internal state variables to store proposed AGE and voting results
    address internal _proposedAGE;
    VoteResult internal _votesForNewAGE;

    // Event about the fact of voting, parameters
    event VotingForNewAGE(address indexed addressVoter, bool indexed vote);
    // Event about the fact of making a decision on voting,
    event VotingCompletedForNewAGE(address indexed decisiveVote, bool indexed result, uint votesFor, uint votesAgainst);
    // The event of the closing of voting, the period of which has expired
    event CloseVoteForNewAGE(address indexed decisiveVote, uint votesFor, uint votesAgainst);


    // Function to initiate the voting process for a new AGE.
    function initiateVotingForNewAGE(address _proposed) public proxyOwner {
        require(_proposed != address(0), "VotingNewAGE: Cannot set null address");
        require(_getAGE() != _proposed, "VotingNewAGE: This vote will not change the AGE address");
        require(_proposedAGE == address(0), "VotingNewAGE: Voting has already started");
        require(_checkContract(_proposed), "VotingNewAGE: The contract does not meet the standard");
        _proposedAGE = _proposed;
        _votesForNewAGE.timestamp = block.timestamp;
        _voteForNewAGE(true);
    }

    // Function for owners to vote for the proposed new AGE
    function voteForNewAGE(bool vote) public proxyOwner {
        _voteForNewAGE(vote);
    }
    // Internal function to handle the logic for voting for the proposed new AGE
    function _voteForNewAGE(bool vote) internal {
        _checkOwnerVoted(_votesForNewAGE);
        require(_proposedAGE != address(0), "VotingNewAGE: There is no active voting on this issue");

        (uint256 votestrue, uint256 votesfalse, VoteResultType result) = _votes(_votesForNewAGE, vote);

        emit VotingForNewAGE(msg.sender, vote);

        if (result == VoteResultType.Approved) {
            _setAddressAge(_proposedAGE);
            _completionVotingAGE(vote, votestrue, votesfalse);
        } else if (result == VoteResultType.Rejected) {
            _completionVotingAGE(vote, votestrue, votesfalse);
        }
    }

    // Completion of voting
    function _completionVotingAGE(bool vote, uint256 votestrue, uint256 votesfalse) internal {
        emit VotingCompletedForNewAGE(msg.sender, vote, votestrue, votesfalse);
        _increaseByPercent(_votesForNewAGE.isTrue, _votesForNewAGE.isFalse);
        _resetVote(_votesForNewAGE);
        _proposedAGE = address(0);
    }

    // Function to close the voting for a new AGE
    function closeVoteForNewAGE() public proxyOwner {
        require(_proposedAGE != address(0), "VotingNewAGE: There is no open vote");
        emit CloseVoteForNewAGE(msg.sender, _votesForNewAGE.isTrue.length, _votesForNewAGE.isFalse.length);
        _closeVote(_votesForNewAGE);
        _proposedAGE = address(0);
    }

    // Function to get the status of voting for the proposed new AGE
    function getVoteForNewAGEStatus() public view returns (address, uint256, uint256, uint256) {
        return (
            _proposedAGE, 
            _votesForNewAGE.isTrue.length, 
            _votesForNewAGE.isFalse.length, 
            _votesForNewAGE.timestamp
        );
    }
}
