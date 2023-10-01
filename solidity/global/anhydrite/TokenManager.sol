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

import "../common/VoteUtility.sol";


/*
 * An abstract contract extending the UtilityVotingAndOwnable contract to manage token transfers based on a voting mechanism.
 * Features include:
 * 1. Initiating a proposal for transferring a specified amount of tokens to a recipient.
 * 2. Voting on the proposal by eligible owners.
 * 3. Automatic execution of the transfer if at least 60% of the votes are in favor.
 * 4. Automatic cancellation of the proposal if over 40% of the votes are against it.
 * 5. Functionality to manually close a vote if it has been open for three or more days without resolution.
 * 6. Events to log voting actions and outcomes.
 * 7. A virtual internal function that must be overridden to actually perform the token transfer.
 */
abstract contract TokenManager is VoteUtility {

    // Suggested recipient address
    address private _proposedTransferRecepient;
    // Offered number of tokens to send
    uint256 private _proposedTransferAmount;
    // Structure for counting votes
    VoteResult private _votesForTransfer;

    // Event about the fact of voting, parameters: voter, recipient, amount, vote
    event VotingForTransfer(address indexed voter, address recepient, uint256 amount, bool vote);
    // Event about the fact of making a decision on voting, parameters: voter, recipient, amount, vote, votesFor, votesAgainst
    event VotingTransferCompleted(address indexed voter, address recepient, uint256 amount, bool vote, uint votesFor, uint votesAgainst);
    // Event to close a poll that has expired
    event CloseVoteForTransfer(address indexed decisiveVote, uint votesFor, uint votesAgainst);

    // Voting start initiation, parameters: recipient, amount
    function initiateTransfer(address recepient, uint256 amount) public onlyOwner {
        require(amount != 0, "TokenManager: Incorrect amount");
        require(_proposedTransferAmount == 0, "TokenManager: voting is already activated");
        if (address(_proxyContract()) != address(0)) {
            require(!_proxyContract().isBlacklisted(recepient), "TokenManager: this address is blacklisted");
        }

        _proposedTransferRecepient = recepient;
        _proposedTransferAmount = amount;
        _votesForTransfer = VoteResult(new address[](0), new address[](0), block.timestamp);
        _voteForTransfer(true);
    }

    // Vote for transfer
    function voteForTransfer(bool vote) external onlyOwner {
        _voteForTransfer(vote);
    }

    // Votes must reach a 60% threshold to pass. If over 40% are downvotes, the measure fails.
    function _voteForTransfer(bool vote) private {
        _checkOwnerVoted(_votesForTransfer);
        require(_proposedTransferAmount != 0, "TokenManager: There is no active voting on this issue");

        (uint256 votestrue, uint256 votesfalse, VoteResultType result) = _votes(_votesForTransfer, vote);

        emit VotingForTransfer(msg.sender, _proposedTransferRecepient, _proposedTransferAmount, vote);

        if (result == VoteResultType.Approved) {
            _transferFor(_proposedTransferRecepient, _proposedTransferAmount);
            _completionVotingTransfer(vote, votestrue, votesfalse);
        } else if (result == VoteResultType.Rejected) {
            _completionVotingTransfer(vote, votestrue, votesfalse);
        }
    }

    // Completion of voting
    function _completionVotingTransfer(bool vote, uint256 votestrue, uint256 votesfalse) private {
         emit VotingTransferCompleted(msg.sender, _proposedTransferRecepient, _proposedTransferAmount, vote, votestrue, votesfalse);
        _completionVoting(_votesForTransfer);
        _proposedTransferRecepient = address(0);
        _proposedTransferAmount = 0;
    }

    // An abstract internal function for transferring tokens
    function _transferFor(address recepient, uint256 amount) internal virtual;

    // A function to close a vote on which a decision has not been made for three or more days
    function closeVoteForTransfer() public onlyOwner {
        require(_proposedTransferRecepient != address(0), "TokenManager: There is no open vote");
        emit CloseVoteForTransfer(msg.sender, _votesForTransfer.isTrue.length, _votesForTransfer.isFalse.length);
        _closeVote(_votesForTransfer);
        _proposedTransferRecepient = address(0);
        _proposedTransferAmount = 0;
    }

    // A function for obtaining information about the status of voting
    function getActiveForVoteTransfer() external view returns (address, uint256) {
        require(_proposedTransferRecepient != address(0), "TokenManager: re is no active voting");
        return (_proposedTransferRecepient, _proposedTransferAmount);
    }
}
