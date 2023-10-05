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

// @filepath Repository Location: [solidity/global/proxy/VotingNewOwner.sol]

pragma solidity ^0.8.19;

import "./BaseMain.sol";
import "../common/VoteUtility.sol";


// This abstract contract is designed for handling the voting process for new owners.
abstract contract VotingNewOwner is VoteUtility, BaseMain {
   
    // Internal state variables 
    address internal _proposedOwner;
    VoteResult internal _votesForNewOwner;
    mapping(address => uint256) internal _initiateOwners;

    // Event on the initiation of voting for the new owner
    event InitiateOwnership(address indexed subject, bool indexed result);
    // Event about the fact of voting, parameters
    event VotingForNewOwner(address indexed addressVoter, address indexed votingObject, bool indexed vote);
    // Event about the fact of making a decision on voting
    event VotingCompletedForNewOwner(address indexed decisiveVote, address indexed votingObject, bool indexed result, uint votesFor, uint votesAgainst);
    // The event of the closing of voting, the period of which has expired
    event CloseVoteForNewOwner(address indexed decisiveVote, address indexed votingObject, uint votesFor, uint votesAgainst);


    // Function to initiate the process to become an owner
    function initiateOwnershipRequest() public {
        require(!_owners[msg.sender], "VotingNewOwner: Already an owner");
        require(!_blackList[msg.sender], "VotingNewOwner: This address is blacklisted");
        require(_proposedOwner == address(0) || block.timestamp >= _votesForNewOwner.timestamp + 7 days, "VotingNewOwner: Voting on this issue is already underway");
        require(block.timestamp >= _initiateOwners[msg.sender] + 30 days, "VotingNewOwner: Voting is still open");
        require(ANHYDRITE.balanceOf(msg.sender) >= _tokensNeededForOwnership, "VotingNewOwner: Not enough Anhydrite to join the owners");

        _initiateOwners[msg.sender] = block.timestamp;

        _proposedOwner = msg.sender;
        _votesForNewOwner = VoteResult(new address[](0), new address[](0), block.timestamp);
        emit InitiateOwnership(msg.sender, true);
    }

    // Function to cast a vote for adding a new owner
    function voteForNewOwner(bool vote) public proxyOwner {
        _checkOwnerVoted(_votesForNewOwner);
        require(_proposedOwner != address(0), "VotingNewOwner: There is no active voting on this issue");

        (uint256 votestrue, uint256 votesfalse, VoteResultType result) = _votes(_votesForNewOwner, vote);

        emit VotingForNewOwner(msg.sender, _proposedOwner, vote);

        if (result == VoteResultType.Approved) {
            _owners[_proposedOwner] = true;
            _totalOwners++;
            _completionVotingNewOwner(vote, votestrue, votesfalse);
        } else if (result == VoteResultType.Rejected) {
            _completionVotingNewOwner(vote, votestrue, votesfalse);
        }
    }

    // Completion of voting
    function _completionVotingNewOwner(bool vote, uint256 votestrue, uint256 votesfalse) internal {
        emit VotingCompletedForNewOwner(msg.sender, _proposedOwner, vote, votestrue, votesfalse);
        _resetVote(_votesForNewOwner);
        _proposedOwner = address(0);
    }
    
    // Function to forcibly close the voting for a new owner if a decision hasn't been made in 3 days
    function closeVoteForNewOwner() public proxyOwner {
        require(_proposedOwner != address(0), "VotingNewOwner: There is no open vote");
        emit CloseVoteForNewOwner(msg.sender, _proposedOwner, _votesForNewOwner.isTrue.length, _votesForNewOwner.isFalse.length);
        _closeVote(_votesForNewOwner);
        _proposedOwner = address(0);
    }

    // Function to get the status of the ongoing vote for the new owner
    function getVoteForNewOwnerStatus() public view returns (address, uint256, uint256, uint256) {
        return (
            _proposedOwner, 
            _votesForNewOwner.isTrue.length, 
            _votesForNewOwner.isFalse.length, 
            _votesForNewOwner.timestamp
        );
    }
}