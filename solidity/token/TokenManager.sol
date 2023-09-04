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

abstract contract TokenManager is OwnableManager {

    address internal _proposedTransferRecepient;
    uint256 internal _proposedTransferAmount;
    VoteResult internal _votesForTransfer;

    event VotingForTransfer(address indexed voter, address recepient, uint256 amount, bool vote);
    event VotingTransferCompleted(address indexed voter, address recepient, uint256 amount, bool vote, uint votesFor, uint votesAgainst);


    // Please provide the address of the new owner for the smart contract, override function
    function initiateTransfer(address recepient, uint256 amount) public onlyProxyOwner(msg.sender) {
        require(amount != 0, "TokenManager: Incorrect amount");
        require(_proposedTransferAmount == 0, "TokenManager: voting is already activated");
        if (address(_proxyContract) != address(0)) {
            require(!_proxyContract.isBlacklisted(recepient), "TokenManager: this address is blacklisted");
        }

        _proposedTransferRecepient = recepient;
        _proposedTransferAmount = amount;
        _votesForTransfer = VoteResult(new address[](0), new address[](0), block.timestamp);
        _voteForTransfer(true);
    }

    function voteForTransfer(bool vote) external onlyProxyOwner(msg.sender) {
        _voteForTransfer(vote);
    }

    // Voting for the address of the new owner of the smart contract 
    function _voteForTransfer(bool vote) internal {
        require(_proposedTransferAmount != 0, "TokenManager: There is no active voting on this issue");
        require(!_hasOwnerVoted(_votesForTransfer, msg.sender), "VotingOwner: Already voted");

        (uint votestrue, uint votesfalse, uint256 _totalOwners) = _votes(_votesForTransfer, vote);

        emit VotingForTransfer(msg.sender, _proposedTransferRecepient, _proposedTransferAmount, vote);

        if (votestrue * 100 >= _totalOwners * 60) {
            _transferFor(_proposedTransferRecepient, _proposedTransferAmount);
            _resetVote(_votesForTransfer);
            emit VotingTransferCompleted(msg.sender, _proposedTransferRecepient, _proposedTransferAmount, vote, votestrue, votesfalse);
            _proposedTransferRecepient = address(0);
            _proposedTransferAmount = 0;
        } else if (votesfalse * 100 > _totalOwners * 40) {
            _resetVote(_votesForTransfer);
            emit VotingTransferCompleted(msg.sender, _proposedTransferRecepient, _proposedTransferAmount, vote, votestrue, votesfalse);
            _proposedTransferRecepient = address(0);
            _proposedTransferAmount = 0;
        }
    }

    function _transferFor(address recepient, uint256 amount) internal virtual;

    function closeVoteForTransfer() public onlyOwner {
        require(_proposedTransferRecepient != address(0), "There is no open vote");
        _closeVote(_votesForTransfer);
        _proposedTransferRecepient = address(0);
            _proposedTransferAmount = 0;
    }

    // Check if voting is enabled for new contract owner and their address.
    function getActiveForVoteTransfer() external view returns (address, uint256) {
        require(_proposedTransferRecepient != address(0), "VotingOwner: re is no active voting");
        return (_proposedTransferRecepient, _proposedTransferAmount);
    }
}