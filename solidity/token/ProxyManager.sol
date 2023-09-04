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

abstract contract ProxyManager is TokenManager {

    address internal _proposedProxy;
    VoteResult internal _votesForNewProxy;

    event VotingForNewProxy(address indexed voter, address proposedProxy, bool vote);
    event VotingONewProxyCompleted(address indexed voter, address proposedProxy, bool vote, uint votesFor, uint votesAgainst);


    // Please provide the address of the new owner for the smart contract, override function
    function initiateNewProxy(address proposedNewProxy) public onlyProxyOwner(msg.sender) {
        require(!_isActiveForVoteNewProxy(), "ProxyManager: voting is already activated");

        _proposedProxy = proposedNewProxy;
        _votesForNewProxy = VoteResult(new address[](0), new address[](0), block.timestamp);
        _voteForNewProxy(true);
    }

    function voteForNewProxy(bool vote) external onlyProxyOwner(msg.sender) {
        _voteForNewProxy(vote);
    }

    // Voting for the address of the new owner of the smart contract 
    function _voteForNewProxy(bool vote) internal {
        require(_isActiveForVoteNewProxy(), "ProxyManager: there are no votes at this address");
        require(!_hasOwnerVoted(_votesForNewProxy, msg.sender), "ProxyManager: Already voted");

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

    function closeVoteForNewProxy() public onlyOwner {
        require(_proposedProxy != address(0), "There is no open vote");
        _closeVote(_votesForNewProxy);
        _proposedProxy = address(0);
    }

    // Check if voting is enabled for new contract owner and their address.
    function getActiveForVoteNewProxy() external view returns (bool, address) {
        require(_isActiveForVoteNewProxy(), "OwnableManager: re is no active voting");
        return (_isActiveForVoteNewProxy(), _proposedProxy);
    }

    function _isActiveForVoteNewProxy() internal view returns (bool) {
        return _proposedProxy != address(0) && _proposedProxy !=  address(_proxyContract);
    }
}