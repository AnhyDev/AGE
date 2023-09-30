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

import "./Ownable.sol";


/*
 * A smart contract serving as a utility layer for voting and ownership management.
 * It extends Ownable contract and interfaces with an external Proxy contract.
 * The contract provides:
 * 1. Vote management with upvotes and downvotes, along with vote expiration checks.
 * 2. Owner checks that allow both the contract owner and proxy contract owners to execute privileged operations.
 * 3. Interface compatibility checks for connected proxy contracts.
 * 4. Renunciation of ownership is explicitly disabled.
 */
abstract contract VoteUtility is Ownable {

    // Enum for vote result clarity
    enum VoteResultType { None, Approved, Rejected }

    // Voting structure
    struct VoteResult {
        address[] isTrue;
        address[] isFalse;
        uint256 timestamp;
    }

    // Internal function to increases interest for VoteResult participants
    function _increaseArrays(VoteResult memory result) internal {
        address[] memory isTrue = result.isTrue;
        address[] memory isFalse = result.isFalse;

        uint256 length1 = isTrue.length;
        uint256 length2 = isFalse.length;
        uint256 totalLength = length1 + length2;

        address[] memory merged = new address[](totalLength);
        for (uint256 i = 0; i < length1; i++) {
            merged[i] = isTrue[i];
        }

        for (uint256 j = 0; j < length2; j++) {
            merged[length1 + j] = isFalse[j];
        }

        _increase(merged);
    }

    // Calls the 'increase' method on the proxy contract to handle voting participants
    function _increase(address[] memory owners) internal {
        if (address(_proxyContract()) != address(0)) {
            _proxyContract().increase(owners);
        }
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
        if (votestrue * 100 >= _totalOwners() * VOTE_THRESHOLD_FOR) {
            result = VoteResultType.Approved;
        } else if (votesfalse * 100 > _totalOwners() * VOTE_THRESHOLD_AGAINST) {
            result = VoteResultType.Rejected;
        }
        return result;
    }

    /*
     * Internal Function: _totalOwners
     * - Purpose: Calculates the total number of owners, taking into account any proxy owners if present.
     * - Arguments: None
     * - Returns:
     *   - An unsigned integer representing the total number of owners.
     */
    function _totalOwners() private view returns (uint256) {
        uint256 _tOwners = 1;
        if (address(_proxyContract()) != address(0)) {
            _tOwners = _proxyContract().getTotalOwners();
        }
        return _tOwners;
    }

    // Internal function to reset the voting result to its initial state
    function _resetVote(VoteResult storage vote) internal {
        vote.isTrue = new address[](0);
        vote.isFalse = new address[](0);
        vote.timestamp = 0;
    }
    
    /*
     * Internal Function: _completionVoting
     * - Purpose: Marks the end of a voting process by increasing vote counts and resetting the VoteResult.
     * - Arguments:
     *   - result: The voting result to complete.
     */
    function _completionVoting(VoteResult storage result) internal {
        _increaseArrays(result);
        _resetVote(result);
    }

    /*
     * Internal Function: _closeVote
     * - Purpose: Closes the voting process after a set period and resets the voting structure.
     * - Arguments:
     *   - vote: The voting result to close.
     */
    function _closeVote(VoteResult storage vote) internal canClose(vote.timestamp) {
        if (address(_proxyContract()) != address(0)) {
            address[] memory newArray = new address[](1);
            newArray[0] = msg.sender;
            _increase(newArray);
        }
        _resetVote(vote);
    }
    
    // Internal function to check if an address has already voted in a given VoteResult
    function _checkOwnerVoted(VoteResult memory result) internal view {
        bool voted;
        for (uint256 i = 0; i < result.isTrue.length; i++) {
            if (result.isTrue[i] == msg.sender) {
                voted = true;
            }
        }
        for (uint256 i = 0; i < result.isFalse.length; i++) {
            if (result.isFalse[i] == msg.sender) {
                voted = true;
            }
        }
        if (voted) {
            revert("VoteUtility: Already voted");
        }
    }

    // Modifier to check if enough time has passed to close the voting
    modifier canClose(uint256 timestamp) {
        require(block.timestamp >= timestamp + 3 days, "VoteUtility: Voting is still open");
        _;
    }
}
