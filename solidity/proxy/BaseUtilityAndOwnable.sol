// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

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

// The IAnhydriteGlobal interface for determining compliance with the smart contract implementation standard when it is installed
interface IAnhydriteGlobal {
    function getVersion() external pure returns (uint256);
    function addPrice(string memory name, uint256 count) external;
    function getPrice(string memory name) external view returns (uint256);
    function getServerFromTokenId(uint256 tokenId) external view returns (address);
    function getTokenIdFromServer(address serverAddress) external view returns (uint256);
}

/*
 * The base abstract smart contract BaseUtilityAndOwnable, in which the main variables are declared, the owner system is implemented,
 * as well as common internal functions and any necessary modifiers.
 */
abstract contract BaseUtilityAndOwnable is IERC721Receiver {

    // The permanent address of the main token of the Anhydrite project (ANH)
    IERC20 internal constant ANHYDRITE = IERC20(0x578b350455932aC3d0e7ce5d7fa62d7785872221);
    // The address of the global smart contract, this address can be changed by voting
    address internal _implement;
    // The number of Anhydrite tokens that the owner must deposit in order to receive voting rights
    uint256 internal _tokensNeededForOwnership;

    // The total number of owners required to be counted during voting
    uint256 internal _totalOwners;
    // Owners
    mapping(address => bool) internal _owners;
    // Owners deposit balance
    mapping(address => uint256) internal _balanceOwner;
    // Owners for whom the exclusion vote is open must be monitored and prohibited from voting
    mapping(address => bool) internal _isOwnerVotedOut;
    // A black list of addresses that compromised former owners
    mapping(address => bool) internal _blackList;

    // Structure for counting votes
    struct VoteResult {
        address[] isTrue;
        address[] isFalse;
        uint256 timestamp;
    }

    // Are services suspended?
    bool internal _stopped = false;
    // Proposal to stop services
    bool internal _proposedStopped = false;
    // Voting structure for stopping services
    VoteResult internal _votesForStopped;

    constructor() {}

    // Returns the address of the global contract
    function _implementation() internal view returns (address){
        return _implement;
    }

    // Adds the voter's address to the corresponding list and also returns the total number of votes, upvotes and downvotes 
    function _votes(VoteResult storage result, bool vote) internal returns (uint256, uint256) {
        if (vote) {
            result.isTrue.push(msg.sender);
        } else {
            result.isFalse.push(msg.sender);
        }
        return (result.isTrue.length, result.isFalse.length);
    }

    // Auxiliary function for receiving information about votes
    function _getVote(VoteResult memory vote, address addresess) internal pure returns (address, uint256, uint256, uint256) {
        return (
            addresess, 
            vote.isTrue.length, 
            vote.isFalse.length, 
            vote.timestamp
        );
    }
    // Clears structure after voting
    function _resetVote(VoteResult storage vote) internal {
        _increaseByPercent(vote.isTrue, vote.isFalse);
        vote.isTrue = new address[](0);
        vote.isFalse = new address[](0);
        vote.timestamp = 0;
    }

    // Calls the poll structure cleanup function if 3 or more days have passed since it started
    function _closeVote(VoteResult storage vote) internal canClose(vote.timestamp) {
        _resetVote(vote);
        _increaseByPercent(msg.sender);
    }

    // Accumulation of voting interest for a specific owner
    function _increaseByPercent(address recepient) internal {
        uint256 percent = _tokensNeededForOwnership * 1 / 100;
        _balanceOwner[recepient] += percent;
    }

    // Calculation of interest for voting on the lists of owners who voted
    function _increaseByPercent(address[] memory addresses1, address[] memory addresses2) internal {
        for (uint256 i = 0; i < addresses1.length; i++) {
            _increaseByPercent(addresses1[i]);
        }

        for (uint256 j = 0; j < addresses2.length; j++) {
            _increaseByPercent(addresses2[j]);
        }
    }
    
    // Checks whether the address has voted
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
    modifier canYouVote(VoteResult memory result) {
        require(!_hasOwnerVoted(result, msg.sender), "BaseUtilityAndOwnable: Already voted");
        require(_balanceOwner[msg.sender] >= _tokensNeededForOwnership, "BaseUtilityAndOwnable: Insufficient tokens in staking balance");
        _;
    }

    // A modifier that checks whether an address is in the list of owners, and whether a vote for exclusion is open for this address
    modifier onlyOwner() {
        require(_owners[msg.sender], "BaseUtilityAndOwnable: Not an owner");
        require(!_isOwnerVotedOut[msg.sender], "BaseUtilityAndOwnable: This owner is being voted out");
        _;
    }

    // Redefined function for automatic transfer of received NFT immediately to global contract address
    function onERC721Received(address, address, uint256 tokenId, bytes calldata) external override returns (bytes4) {
        require(IERC165(msg.sender).supportsInterface(0x80ac58cd), "BaseUtilityAndOwnable: Sender does not support ERC-721");

        IERC721(msg.sender).safeTransferFrom(address(this), _implementation(), tokenId);
        return this.onERC721Received.selector;
    }

    // A function to verify the identity of a global smart contract
    function _checkContract(address contractAddress) internal view returns (bool) {
        return IERC165(contractAddress).supportsInterface(type(IAnhydriteGlobal).interfaceId);
    }
}