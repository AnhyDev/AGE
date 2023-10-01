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
import "./UtilityAnh.sol";

/*
 * This abstract contract extends the UtilityVotingAndOwnable contract to facilitate governance of smart contract proxies.
 * Key features include:
 * 1. Initiating a proposal for setting a new proxy address.
 * 2. Voting on the proposed new proxy address by the proxy owners.
 * 3. Automatic update of the proxy address if a 70% threshold of affirmative votes is reached.
 * 4. Automatic cancellation of the proposal if over 30% of the votes are against it.
 * 5. Functionality to manually close an open vote that has been pending for more than three days without a conclusive decision.
 * 6. Events to log voting actions and outcomes for transparency and auditing purposes.
 * 7. Utility functions to check the status of the active vote and the validity of the proposed proxy address.
 */
abstract contract ProxyManager is VoteUtility, UtilityAnh {

    // A new smart contract proxy address is proposed
    address private _proposedProxy;
    // Structure for counting votes
    VoteResult private _votesForNewProxy;

    // Event about the fact of voting, parameters: voter, proposedProxy, vote
    event VotingForNewProxy(address indexed voter, address indexed proposedProxy, bool vote);
    // Event about the fact of making a decision on voting, parameters: voter, proposedProxy, vote, votesFor, votesAgainst
    event VotingNewProxyCompleted(address indexed voter, address indexed oldProxy, address indexed newProxy, bool vote, uint votesFor, uint votesAgainst);
    // Event to close a poll that has expired
    event CloseVoteForNewProxy(address indexed decisiveVote, address indexed votingObject, uint votesFor, uint votesAgainst);

    // Voting start initiation, parameters: proposedNewProxy
    function initiateNewProxy(address proposedNewProxy) public onlyOwner {
        require(_proposedProxy == address(0), "ProxyManager: voting is already activated");
        require(_checkIProxyContract(proposedNewProxy), "ProxyManager: This address does not represent a contract that implements the IProxy interface.");

        _proposedProxy = proposedNewProxy;
        _votesForNewProxy = VoteResult(new address[](0), new address[](0), block.timestamp);
        _voteForNewProxy(true);
    }

    // Vote to change the owner of a smart contract
    function voteForNewProxy(bool vote) external onlyOwner {
        _voteForNewProxy(vote);
    }

    // Votes must reach a 60% threshold to pass. If over 40% are downvotes, the measure fails.
    function _voteForNewProxy(bool vote) private {
        _checkOwnerVoted(_votesForNewProxy);
        require(_proposedProxy != address(0), "ProxyManager: there are no votes at this address");

        (uint256 votestrue, uint256 votesfalse, VoteResultType result) = _votes(_votesForNewProxy, vote);

        emit VotingForNewProxy(msg.sender, _proposedProxy, vote);

        if (result == VoteResultType.Approved) {
            address oldProxy = address(_proxyContract());
            _setProxyContract(_proposedProxy);
            _completionVotingNewProxy(oldProxy, vote, votestrue, votesfalse);
        } else if (result == VoteResultType.Rejected) {
            _completionVotingNewProxy(address(_proxyContract()), vote, votestrue, votesfalse);
        }
    }
    
    // Completion of voting
    function _completionVotingNewProxy(address oldProxy, bool vote, uint256 votestrue, uint256 votesfalse) private {
        emit VotingNewProxyCompleted(oldProxy, msg.sender, _proposedProxy, vote, votestrue, votesfalse);
        _completionVoting(_votesForNewProxy);
        _proposedProxy = address(0);
    }

    // A function to close a vote on which a decision has not been made for three or more days
    function closeVoteForNewProxy() public onlyOwner {
        require(_proposedProxy != address(0), "ProxyManager: There is no open vote");
        emit CloseVoteForNewProxy(msg.sender, _proposedProxy, _votesForNewProxy.isTrue.length, _votesForNewProxy.isFalse.length);
        _closeVote(_votesForNewProxy);
        _proposedProxy = address(0);
    }

    // A function for obtaining information about the status of voting
    function getActiveForVoteNewProxy() external view returns (address) {
        require(_proposedProxy != address(0), "ProxyManager: re is no active voting");
        return _proposedProxy;
    }
}
