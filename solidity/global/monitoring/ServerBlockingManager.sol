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

// @filepath Repository Location: [solidity/global/monitoring/ServerBlockingManager.sol]

pragma solidity ^0.8.19;

import "../common/VoteUtility.sol";

abstract contract ServerBlockingManager is VoteUtility {

    // Proposed new owner
    address internal _proposedBlocking;
    // Structure for counting votes
    VoteResult internal _votesForServerBlocking;

    // Event about the fact of voting, 
    event VotingForServerBlocking(address indexed voter, address proposedOwner, bool vote);
    // Event about the fact of making a decision on voting, 
    event ServerBlockingCompleted(address indexed voter, address proposedOwner,  bool vote, uint256 votesFor, uint256 votesAgainst);
    // Event to close a poll that has expired
    event CloseVoteForServerBlocking(address indexed decisiveVote, address indexed votingObject, uint256 votesFor, uint256 votesAgainst);

    function _isServer(address serverAddress) internal view virtual returns (bool);
    function _isBlocked(address serverAddress) internal view virtual returns (bool);
    function _setBlocked(address serverAddress) internal virtual;

    function blockServer(address proposedBlocking) external {
        _checkProxyOwner();
        require(_isServer(proposedBlocking), "Server address not found");
        require(_isBlocked(proposedBlocking), "Server is already blocked");
        require(proposedBlocking == address(0), "ServerBlockingManager: voting is already activated");
        require(!_proxyContract().isBlacklisted(proposedBlocking),"ServerBlockingManager: this address is blacklisted");

        _proposedBlocking = proposedBlocking;
        _votesForServerBlocking = VoteResult(
            new address[](0),
            new address[](0),
            block.timestamp
        );
        _voteForServerBlocking(true);
    }

    // Vote to change the owner of a smart contract
    function voteForServerBlocking(bool vote) external {
        _checkProxyOwner();
        _voteForServerBlocking(vote);
    }

    // Votes must reach a 60% threshold to pass. If over 40% are downvotes, the measure fails.
    function _voteForServerBlocking(bool vote) internal {
        _checkOwnerVoted(_votesForServerBlocking);
        require(_proposedBlocking != address(0), "ServerBlockingManager: there are no votes at this address");

        (uint256 votestrue, uint256 votesfalse, VoteResultType result) = _votes(_votesForServerBlocking, vote);

        emit VotingForServerBlocking(msg.sender, _proposedBlocking, vote);

        if (result == VoteResultType.Approved) {
            _setBlocked(_proposedBlocking);
            _completionVotingServerBlocking(vote, votestrue, votesfalse);
        } else if (result == VoteResultType.Rejected) {
            _completionVotingServerBlocking(vote, votestrue, votesfalse);
        }
    }

    // Completion of voting
    function _completionVotingServerBlocking(bool vote, uint256 votestrue, uint256 votesfalse) private {
        emit ServerBlockingCompleted(msg.sender, _proposedBlocking, vote, votestrue, votesfalse);
        _completionVoting(_votesForServerBlocking);
        _proposedBlocking = address(0);
    }

    // A function to close a vote on which a decision has not been made for three or more days
    function closeVoteForServerBlockingr() external {
        _checkProxyOwner();
        require(_proposedBlocking != address(0), "ServerBlockingManager: There is no open vote" );
        require(block.timestamp >= _votesForServerBlocking.timestamp + 3 days, "BaseUtility: Voting is still open");
        emit CloseVoteForServerBlocking( msg.sender, _proposedBlocking, _votesForServerBlocking.isTrue.length, _votesForServerBlocking.isFalse.length );
        _resetVote(_votesForServerBlocking);
        _proposedBlocking = address(0);
    }

    // Check if voting is enabled for new contract owner and their address.
    function getActiveForVoteBlocking() external view returns (address) {
        require(_proposedBlocking != address(0), "ServerBlockingManager: re is no active voting" );
        return _proposedBlocking;
    }
}

