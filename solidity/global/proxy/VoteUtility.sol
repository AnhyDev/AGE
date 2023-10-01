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


//Base contract for utility and ownership	functionalities
abstract contract VoteUtility is BaseProxy {


    // Enum for vote result clarity
    enum VoteResultType { None, Approved, Rejected }

    // Voting outcome structure
    struct VoteResult {
        address[] isTrue;
        address[] isFalse;
        uint256 timestamp;
    }

    /*
     * Internal Function: _votes
     * - Purpose: Records an individual vote, updates the overall vote counts, and evaluates the current voting outcome.
     * - Arguments:
     *   - result: The VoteResult storage object that tracks the current state of both favorable ("true") and opposing ("false") votes.
     *   - vote: A Boolean value representing the stance of the vote (true for in favor, false for against).
     * - Returns:
     *   - The number of favorable votes.
     *   - The number of opposing votes.
     *   - An enum (VoteResultType) that represents the current status of the voting round based on the accumulated favorable and opposing votes.
     */
    function _votes(VoteResult storage result, bool vote) internal returns (uint256, uint256, VoteResultType) {
        if (vote) {
            result.isTrue.push(msg.sender);
        } else {
            result.isFalse.push(msg.sender);
        }
        uint256 votestrue = result.isTrue.length;
        uint256 votesfalse = result.isFalse.length;
        return (votestrue, votesfalse, _voteResult(votestrue, votesfalse));
    }

    /*
     * Internal Function: _voteResult
     * - Purpose: Evaluates the outcome of a voting round based on the current numbers of favorable and opposing votes.
     * - Arguments:
     *   - votestrue: The number of favorable votes.
     *   - votesfalse: The number of opposing votes.
     * - Returns:
     *   - An enum (VoteResultType) representing the voting outcome: None if the vote is still inconclusive, Approved if the vote meets or exceeds a 60% approval rate, and Rejected if the opposing votes exceed a 40% threshold.
     */
    function _voteResult(uint256 votestrue, uint256 votesfalse) private view returns (VoteResultType) {
        VoteResultType result = VoteResultType.None;
        uint256 VOTE_THRESHOLD_FOR = 60;
        uint256 VOTE_THRESHOLD_AGAINST = 40;
        if (votestrue * 100 >= _totalOwners * VOTE_THRESHOLD_FOR) {
            result = VoteResultType.Approved;
        } else if (votesfalse * 100 > _totalOwners * VOTE_THRESHOLD_AGAINST) {
            result = VoteResultType.Rejected;
        }
        return result;
    }

    // Returns vote details
    function _getVote(VoteResult memory vote, address addresess) internal pure returns (address, uint256, uint256, uint256) {
        return (
            addresess, 
            vote.isTrue.length, 
            vote.isFalse.length, 
            vote.timestamp
        );
    }
    
    // Resets vote counts after voting
    function _resetVote(VoteResult storage vote) internal {
        _increaseByPercent(vote.isTrue, vote.isFalse);
        vote.isTrue = new address[](0);
        vote.isFalse = new address[](0);
        vote.timestamp = 0;
    }

    // Closes voting after 3 days
    function _closeVote(VoteResult storage vote) internal canClose(vote.timestamp) {
        _resetVote(vote);
        _increaseByPercent(msg.sender);
    }

    // Increases interest for specific owner
    function _increaseByPercent(address recepient) internal virtual override {
        if (address(0) != recepient) {
            uint256 percent = _tokensNeededForOwnership * 1 / 100;
            _balanceOwner[recepient] += percent;
        }
    }

    // Increases interest for voting participants
    function _increaseByPercent(address[] memory addresses1, address[] memory addresses2) internal {
        for (uint256 i = 0; i < addresses1.length; i++) {
            _increaseByPercent(addresses1[i]);
        }

        for (uint256 j = 0; j < addresses2.length; j++) {
            _increaseByPercent(addresses2[j]);
        }
    }
    
    // Checks if the owner has voted
    function _hasOwnerVoted(VoteResult memory addresses, address targetAddress) internal pure returns (bool) {
        for (uint256 i = 0; i < addresses.isTrue.length; i++) {
            if (addresses.isTrue[i] == targetAddress) {
                return true;
            }
        }
        for (uint256 i = 0; i < addresses.isFalse.length; i++) {
            if (addresses.isFalse[i] == targetAddress) {
                return true;
            }
        }
        return false;
    }

    // Modifier for checking whether 3 days have passed since the start of voting and whether it can be closed
    modifier canClose(uint256 timestamp) {
        require(block.timestamp >= timestamp + 3 days, "BaseUtilityAndOwnable: Voting is still open");
        _;
    }

    // Modifier to check if the owner has the right to vote on this issue,
    // that is, whether he has not voted before, and whether his deposit corresponds to the amount required for the right to vote
    modifier hasNotVoted(VoteResult memory result) {
        require(!_hasOwnerVoted(result, msg.sender), "BaseUtilityAndOwnable: Already voted");
        _;
    }
}
