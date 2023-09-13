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

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// Base contract for utility and ownership functionalities
abstract contract BaseUtilityAndOwnable is IERC721Receiver, IERC165 {

    // Main project token (ANH) address
    IANH internal constant ANHYDRITE = IANH(0x869c859A01935Fa5f0fc24a92C1c3C69f9b9ff6a);
    // Global contract (AGE) address
    address internal _implementAGE;
    // Tokens required for ownership rights
    uint256 internal _tokensNeededForOwnership;

    // The total number of owners
    uint256 internal _totalOwners;
    // Owner status mapping
    mapping(address => bool) internal _owners;
    // Owner token balance mapping
    mapping(address => uint256) internal _balanceOwner;
    // Owners under exclusion vote
    mapping(address => bool) internal _isOwnerVotedOut;
    // Blacklisted addresses
    mapping(address => bool) internal _blackList;

    // Voting outcome structure
    struct VoteResult {
        address[] isTrue;
        address[] isFalse;
        uint256 timestamp;
    }

    // Service status flags
    bool internal _stopped = false;
    bool internal _proposedStopped = false;
    VoteResult internal _votesForStopped;

    mapping(bytes4 => bool) internal supportedInterfaces;

    constructor() {
        supportedInterfaces[0x01ffc9a7] = true;
        supportedInterfaces[type(IProxy).interfaceId] = true;
    }


    // Realization ERC165
    function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
        return supportedInterfaces[interfaceId];
    }

    // Returns global contract (AGE) address
    function _implementation() internal view returns (address){
        return _implementAGE;
    }

    // Adds vote and returns vote counts 
    function _votes(VoteResult storage result, bool vote) internal returns (uint256, uint256) {
        if (vote) {
            result.isTrue.push(msg.sender);
        } else {
            result.isFalse.push(msg.sender);
        }
        return (result.isTrue.length, result.isFalse.length);
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
    function _increaseByPercent(address recepient) internal {
        uint256 percent = _tokensNeededForOwnership * 1 / 100;
        _balanceOwner[recepient] += percent;
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

    // Validates owner's voting rights
    function _isProxyOwner(address ownerAddress) internal view returns (bool) {
        return _owners[ownerAddress] 
        && !_isOwnerVotedOut[ownerAddress]
        && _balanceOwner[ownerAddress] >= _tokensNeededForOwnership;
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

    // A modifier that checks whether an address is in the list of owners, and whether a vote for exclusion is open for this address
    modifier onlyOwner() {
        require(_isProxyOwner(msg.sender), "BaseUtilityAndOwnable: Not an owner");
        _;
    }

    // Handles received NFTs and forwards them
    function onERC721Received(address, address, uint256 tokenId, bytes calldata) external override returns (bytes4) {
        require(IERC165(msg.sender).supportsInterface(0x80ac58cd), "BaseUtilityAndOwnable: Sender does not support ERC-721");

        IERC721(msg.sender).safeTransferFrom(address(this), _implementation(), tokenId);
        return this.onERC721Received.selector;
    }

    // Checks if a contract implements a specific IAGE interface
    function _checkContract(address contractAddress) internal view returns (bool) {
        return IERC165(contractAddress).supportsInterface(type(IAGE).interfaceId);
    }
}

// This contract extends BaseUtilityAndOwnable and is responsible for voting to stop/resume services
abstract contract VotingStopped is BaseUtilityAndOwnable {

    // Event about the fact of voting, parameters
    event VotingForStopped(address indexed addressVoter, bool indexed vote);
    // Event about the fact of making a decision on voting,
    event VotingCompletedForStopped(address indexed decisiveVote, bool indexed result, uint votesFor, uint votesAgainst);
    // The event of the closing of voting, the period of which has expired
    event CloseVoteForStopped(address indexed decisiveVote, uint votesFor, uint votesAgainst);


    // Initiates vote for stopping/resuming services
    function initiateVotingForStopped(bool _proposed) public onlyOwner {
        require(_stopped != _proposed, "VotingStopped: This vote will not change the Stop status");
        require(_proposed != _proposedStopped, "VotingStopped: Voting has already started");
        _proposedStopped = _proposed;
        _votesForStopped.timestamp = block.timestamp;
        _voteForStopped(true);
    }

    // Vote for stopping/resuming services
    function voteForStopped(bool vote) public onlyOwner {
        _voteForStopped(vote);
    }
    // Internal function to handle the vote logic
    function _voteForStopped(bool vote) internal hasNotVoted(_votesForStopped) {
        require(_stopped != _proposedStopped, "VotingStopped: There is no active voting on this issue");

        (uint votestrue, uint votesfalse) = _votes(_votesForStopped, vote);

        emit VotingForStopped(msg.sender, vote);

        if (votestrue * 100 >= _totalOwners * 60) {
            _stopped = _proposedStopped;
           _completionVotingStopped(vote, votestrue, votesfalse);
            
       } else if (votesfalse * 100 > _totalOwners * 40) {
           _proposedStopped = _stopped;
           _completionVotingStopped(vote, votestrue, votesfalse);
        }
    }

    // Completion of voting
    function _completionVotingStopped(bool vote, uint256 votestrue, uint256 votesfalse) internal {
         emit VotingCompletedForStopped(msg.sender, vote, votestrue, votesfalse);
        _resetVote(_votesForStopped);
    }

    // Close the vote manually
    function closeVoteForStopped() public onlyOwner {
        require(_stopped != _proposedStopped, "There is no open vote");
        emit CloseVoteForStopped(msg.sender, _votesForStopped.isTrue.length, _votesForStopped.isFalse.length);
        _closeVote(_votesForStopped);
        _proposedStopped = _stopped;
    }

    // Get current vote status
    function getVoteForStopped() public view returns (bool, uint256, uint256, uint256) {
            return (
            _proposedStopped != _stopped,
            _votesForStopped.isTrue.length, 
            _votesForStopped.isFalse.length, 
            _votesForStopped.timestamp
        );
    }
}

// This contract extends BaseUtilityAndOwnable and is responsible for voting to tokens required for ownership rights
abstract contract VotingNeededForOwnership is BaseUtilityAndOwnable {

    // Holds the proposed new token count needed for voting rights
    uint256 internal _proposedTokensNeeded;
    // Holds the vote results for the proposed token count
    VoteResult internal _votesForTokensNeeded;

    // Event triggered when a vote is cast
    event VotingForTokensNeeded(address indexed addressVoter, bool indexed vote);
    // Event triggered when a voting round ends
    event VotingCompletedForTokensNeeded(address indexed decisiveVote, bool indexed result, uint votesFor, uint votesAgainst);
    // Event triggered when a vote is manually closed
    event CloseVoteForTokensNeeded(address indexed decisiveVote, uint votesFor, uint votesAgainst);


    // Initialize voting to change required token count for voting rights
    function initiateVotingForNeededForOwnership(uint256 _proposed) public onlyOwner {
        require(_proposed != 0, "Votes: The supply of need for ownership tokens cannot be zero");
        require(_tokensNeededForOwnership != _proposed, "Votes: This vote will not change the need for ownership tokens");
        require(_proposedTokensNeeded == 0, "Votes: Voting has already started");
        _proposedTokensNeeded = _proposed;
        _votesForTokensNeeded.timestamp = block.timestamp;
        _voteForNeededForOwnership(true);
    }

    // Cast a vote for changing required token count
    function voteForNeededForOwnership(bool vote) public onlyOwner {
        _voteForNeededForOwnership(vote);
    }
    // Internal function to handle the vote logic
    function _voteForNeededForOwnership(bool vote) internal hasNotVoted(_votesForTokensNeeded) {
        require(_proposedTokensNeeded != 0, "Votes: There is no active voting on this issue");

        (uint votestrue, uint votesfalse) = _votes(_votesForTokensNeeded, vote);

        emit VotingForTokensNeeded(msg.sender, vote);

        if (votestrue * 100 >= _totalOwners * 60) {
            _tokensNeededForOwnership = _proposedTokensNeeded;
            _completionVotingNeededOwnership(vote, votestrue, votesfalse);
       } else if (votesfalse * 100 > _totalOwners * 40) {
            _completionVotingNeededOwnership(vote, votestrue, votesfalse);
        }
    }

    // Completion of voting
    function _completionVotingNeededOwnership(bool vote, uint256 votestrue, uint256 votesfalse) internal {
        emit VotingCompletedForTokensNeeded(msg.sender, vote, votestrue, votesfalse);
        _resetVote(_votesForTokensNeeded);
        _proposedTokensNeeded = 0;
    }

    // Close the vote manually
    function closeVoteForTokensNeeded() public onlyOwner {
        require(_proposedTokensNeeded != 0, "There is no open vote");
        emit CloseVoteForTokensNeeded(msg.sender, _votesForTokensNeeded.isTrue.length, _votesForTokensNeeded.isFalse.length);
        _closeVote(_votesForTokensNeeded);
        _proposedTokensNeeded = 0;
    }
    
    // Get current vote status
    function getVoteForNewTokensNeeded() public view returns (uint256, uint256, uint256, uint256) {
        return (
            _proposedTokensNeeded, 
            _votesForTokensNeeded.isTrue.length, 
            _votesForTokensNeeded.isFalse.length, 
            _votesForTokensNeeded.timestamp
        );
    }
}

// This contract extends BaseUtilityAndOwnable and is responsible for voting on new implementations
abstract contract VotingNewImplementation is BaseUtilityAndOwnable {

    // Internal state variables to store proposed implementation and voting results
    address internal _proposedImplementation;
    VoteResult internal _votesForNewImplementation;

    // Event about the fact of voting, parameters
    event VotingForNewImplementation(address indexed addressVoter, bool indexed vote);
    // Event about the fact of making a decision on voting,
    event VotingCompletedForNewImplementation(address indexed decisiveVote, bool indexed result, uint votesFor, uint votesAgainst);
    // The event of the closing of voting, the period of which has expired
    event CloseVoteForNewImplementation(address indexed decisiveVote, uint votesFor, uint votesAgainst);


    // Function to initiate the voting process for a new implementation.
    function initiateVotingForNewImplementation(address _proposed) public onlyOwner {
        require(_proposed != address(0), "Votes: Cannot set null address");
        require(_implementation() != _proposed, "Votes: This vote will not change the implementation address");
        require(_proposedImplementation == address(0), "Votes: Voting has already started");
        require(_checkContract(_proposed), "Votes: The contract does not meet the standard");
        _proposedImplementation = _proposed;
        _votesForNewImplementation.timestamp = block.timestamp;
        _voteForNewImplementation(true);
    }

    // Function for owners to vote for the proposed new implementation
    function voteForNewImplementation(bool vote) public onlyOwner {
        _voteForNewImplementation(vote);
    }
    // Internal function to handle the logic for voting for the proposed new implementation
    function _voteForNewImplementation(bool vote) internal hasNotVoted(_votesForNewImplementation) {
        require(_proposedImplementation != address(0), "Votes: There is no active voting on this issue");

        (uint votestrue, uint votesfalse) = _votes(_votesForNewImplementation, vote);

        emit VotingForNewImplementation(msg.sender, vote);

        if (votestrue * 100 >= _totalOwners * 60) {
            _implementAGE = _proposedImplementation;
            _completionVotingImplementation(vote, votestrue, votesfalse);
        } else if (votesfalse * 100 > _totalOwners * 40) {
            _completionVotingImplementation(vote, votestrue, votesfalse);
        }
    }

    // Completion of voting
    function _completionVotingImplementation(bool vote, uint256 votestrue, uint256 votesfalse) internal {
        emit VotingCompletedForNewImplementation(msg.sender, vote, votestrue, votesfalse);
        _resetVote(_votesForNewImplementation);
        _proposedImplementation = address(0);
    }

    // Function to close the voting for a new implementation
    function closeVoteForNewImplementation() public onlyOwner {
        require(_proposedImplementation != address(0), "There is no open vote");
        emit CloseVoteForNewImplementation(msg.sender, _votesForNewImplementation.isTrue.length, _votesForNewImplementation.isFalse.length);
        _closeVote(_votesForNewImplementation);
        _proposedImplementation = address(0);
    }

    // Function to get the status of voting for the proposed new implementation
    function getVoteForNewImplementationStatus() public view returns (address, uint256, uint256, uint256) {
        return _getVote(_votesForNewImplementation, _proposedImplementation);
    }
}

// This abstract contract is designed for handling the voting process for new owners.
abstract contract VotingNewOwner is BaseUtilityAndOwnable {
   
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
        require(!_owners[msg.sender], "Votes: Already an owner");
        require(!_blackList[msg.sender], "Votes: This address is blacklisted");
        require(_proposedOwner == address(0) || block.timestamp >= _votesForNewOwner.timestamp + 7 days, "Votes: Voting on this issue is already underway");
        require(block.timestamp >= _initiateOwners[msg.sender] + 30 days, "Votes: Voting is still open");
        require(_balanceOwner[msg.sender] >= _tokensNeededForOwnership, "Votes: Not enough Anhydrite to join the owners");

        _initiateOwners[msg.sender] = block.timestamp;

        _proposedOwner = msg.sender;
        _votesForNewOwner = VoteResult(new address[](0), new address[](0), block.timestamp);
        emit InitiateOwnership(msg.sender, true);
    }

    // Function to cast a vote for adding a new owner
    function voteForNewOwner(bool vote) public onlyOwner hasNotVoted(_votesForNewOwner) {
        require(_proposedOwner != address(0), "Votes: There is no active voting on this issue");

        (uint votestrue, uint votesfalse) = _votes(_votesForNewOwner, vote);

        emit VotingForNewOwner(msg.sender, _proposedOwner, vote);

        if (votestrue * 100 >= _totalOwners * 60) {
            _owners[_proposedOwner] = true;
            _totalOwners++;
            _completionVotingNewOwner(vote, votestrue, votesfalse);
        } else if (votesfalse * 100 > _totalOwners * 40) {
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
    function closeVoteForNewOwner() public onlyOwner {
        require(_proposedOwner != address(0), "There is no open vote");
        emit CloseVoteForNewOwner(msg.sender, _proposedOwner, _votesForNewOwner.isTrue.length, _votesForNewOwner.isFalse.length);
        _closeVote(_votesForNewOwner);
        _proposedOwner = address(0);
    }

    // Function to get the status of the ongoing vote for the new owner
    function getVoteForNewOwnerStatus() public view returns (address, uint256, uint256, uint256) {
        return _getVote(_votesForNewOwner, _proposedOwner);
    }
}

// Abstract contract for voting to remove an owner.
abstract contract VotingRemoveOwner is BaseUtilityAndOwnable {
    
    // Holds the proposed to remove an owner
    address internal _proposedRemoveOwner;
    // Holds the vote results for the remove an owner
    VoteResult internal _votesForRemoveOwner;

    // Event triggered when a vote is cast
    event VotingForRemoveOwner(address indexed addressVoter, address indexed votingObject, bool indexed vote);
    // Event triggered when a voting round ends
    event VotingCompletedForRemoveOwner(address indexed decisiveVote, address indexed votingObject, bool indexed result, uint votesFor, uint votesAgainst);
    // Event triggered when a vote is manually closed
    event CloseVoteForRemoveOwner(address indexed decisiveVote, address indexed votingObject, uint votesFor, uint votesAgainst);


    // Function to initiate the voting process to remove an owner
    function initiateVotingForRemoveOwner(address _proposed) public onlyOwner {
        require(_proposed != address(0), "Votes: Cannot set null address");
        require(_owners[_proposed], "Votes: This address is not included in the list of owners");
        require(_proposedRemoveOwner == address(0), "Votes: Voting has already started");
        _proposedRemoveOwner = _proposed;
        _votesForRemoveOwner.timestamp = block.timestamp;
        _isOwnerVotedOut[_proposed] = true;
        _totalOwners--;
        _voteForRemoveOwner(true);
    }

    // Function to cast a vote to remove an owner
    function voteForRemoveOwner(bool vote) public onlyOwner {
        _voteForRemoveOwner(vote);
    }
    // Internal function handling the voting logic
    function _voteForRemoveOwner(bool vote) internal hasNotVoted(_votesForRemoveOwner) {
        require(_proposedRemoveOwner != msg.sender, "You cannot vote for yourself");
        require(_proposedRemoveOwner != address(0), "Votes: There is no active voting on this issue");

        (uint votestrue, uint votesfalse) = _votes(_votesForRemoveOwner, vote);

        emit VotingForRemoveOwner(msg.sender, _proposedRemoveOwner, vote);

        if (votestrue * 100 >= _totalOwners * 60) {
            _owners[_proposedRemoveOwner] = false;
            _balanceOwner[msg.sender] = 0;
            _blackList[_proposedRemoveOwner] = true;
            _completionVotingRemoveOwner(vote, votestrue, votesfalse);
        } else if (votesfalse * 100 > _totalOwners * 40) {
            _totalOwners++;
            _completionVotingRemoveOwner(vote, votestrue, votesfalse);
        }
    }

    // Completion of voting
    function _completionVotingRemoveOwner(bool vote, uint256 votestrue, uint256 votesfalse) internal {
        emit VotingCompletedForRemoveOwner(msg.sender, _proposedRemoveOwner, vote, votestrue, votesfalse);
        _resetVote(_votesForRemoveOwner);
        _isOwnerVotedOut[_proposedRemoveOwner] = false;
        _proposedRemoveOwner = address(0);
    }

    // Function to forcibly close the vote to remove an owner
    function closeVoteForRemoveOwner() public onlyOwner {
        require(_proposedRemoveOwner != address(0), "There is no open vote");
        _isOwnerVotedOut[_proposedRemoveOwner] = false;
        emit CloseVoteForRemoveOwner(msg.sender, _proposedRemoveOwner, _votesForRemoveOwner.isTrue.length, _votesForRemoveOwner.isFalse.length);
        _closeVote(_votesForRemoveOwner);
        _proposedRemoveOwner = address(0);
        _totalOwners++;
    }

    // Function to get the current status of the vote to remove an owner
    function getVoteForRemoveOwnerStatus() public view returns (address, uint256, uint256, uint256) {
        return _getVote(_votesForRemoveOwner, _proposedRemoveOwner);
    }
}

// IProxy interface defines the methods a Proxy contract should implement.
interface IProxy {
    // Returns the core ERC20 token of the project
    function getCoreToken() external view returns (IERC20);

    // Returns the address of the current implementation (logic contract)
    function implementation() external view returns (address);

    // Returns the number of tokens needed to become an owner
    function getTokensNeededForOwnership() external view returns (uint256);

    // Returns the total number of owners
    function getTotalOwners() external view returns (uint256);

    // Checks if an address is a proxy owner (has voting rights)
    function isProxyOwner(address tokenAddress) external view returns (bool);

    // Checks if an address is an owner
    function isOwner(address account) external view returns (bool);

    // Returns the balance of an owner
    function getBalanceOwner(address owner) external view returns (uint256);

    // Checks if an address is blacklisted
    function isBlacklisted(address account) external view returns (bool);

    // Checks if the contract is stopped
    function isStopped() external view returns (bool);
    
    // Increases interest for voting participants
    function increase(address[] memory addresses) external;
}

// Proxy is an abstract contract that implements the IProxy interface and adds utility and ownership functionality.
abstract contract Proxy is IProxy, BaseUtilityAndOwnable {

    // Internal function that delegates calls to the implementation contract
    function _delegate() internal virtual {
        require(!_stopped, "Proxy: Contract is currently _stopped.");
        address _impl = _implementation();
        require(_impl != address(0), "Proxy: Implementation == address(0)");

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    // Internal fallback function that delegates the call
    function _fallback() internal virtual {
        _delegate();
    }

    // Fallback function to handle incoming calls
    fallback() external payable virtual {
        _fallback();
    }

    // Function to forward Ether received to the implementation contract
    receive() external payable {
        Address.sendValue(payable(address(_implementation())), msg.value);
    }

    // Returns the main ERC20 token of the project
    function getCoreToken() external override pure returns (IERC20) {
        return ANHYDRITE;
    }

    // Returns the address of the implementation contract
    function implementation() external override view returns (address) {
        return _implementation();
    }

    // Checks if the contract's basic functions are stopped
    function isStopped() external override view returns (bool) {
        return _stopped;
    }

    // Returns the total number of owners
    function getTotalOwners() external override view returns (uint256) {
        return _totalOwners;
    }

    // Checks if an address is a proxy owner (has voting rights)
    function isProxyOwner(address ownerAddress) external override view returns (bool) {
        return _isProxyOwner(ownerAddress);
    }

    // Checks if an address is an owner
    function isOwner(address account) external override view returns (bool) {
        return _owners[account];
    }

    // Returns the balance of an owner
    function getBalanceOwner(address owner) external override view returns (uint256) {
        return _balanceOwner[owner];
    }

    // Returns the number of tokens needed to become an owner
    function getTokensNeededForOwnership() external override view returns (uint256) {
        return _tokensNeededForOwnership;
    }

    // Checks if an address is blacklisted
    function isBlacklisted(address account) external override view returns (bool) {
        return _blackList[account];
    }

    // Increases interest for voting participants
    function increase(address[] memory addresses) external {
        require(msg.sender == address(ANHYDRITE), "BaseUtilityAndOwnable: This is a disabled feature for you");
        for (uint256 i = 0; i < addresses.length; i++) {
            _increaseByPercent(addresses[i]);
        }
    }
}

// Interface for contracts that are capable of receiving ERC20 (ANH) tokens.
interface IERC20Receiver {
    // Function that is triggered when ERC20 (ANH) tokens are received.
    function onERC20Received(address _from, address _who, uint256 _amount) external returns (bytes4);

    // An event to track from which address the tokens were transferred, who transferred, to which address and the number of tokens
    event ChallengeIERC20Receiver(address indexed from, address indexed who, address indexed token, uint256 amount);
}

// AnhydriteProxyOwners is an extension of several contracts and interfaces, designed to manage ownership, voting, and token interaction.
contract AnhydriteProxyOwners
 is Proxy, VotingStopped, VotingNeededForOwnership, VotingNewImplementation, VotingNewOwner, VotingRemoveOwner, IERC20Receiver {

    // Event emitted when an owner voluntarily exits.
    event VoluntarilyExit(address indexed votingSubject, uint returnTokens);
    // Event emitted when Anhydrite tokens are deposited.
    event DepositAnhydrite(address indexed from, address indexed who, uint256 amount);
    
    // Constructor initializes basic contract variables.
    constructor() {
        _implementAGE = address(0);
        _owners[msg.sender] = true;
        _totalOwners++;
        _tokensNeededForOwnership = 100000 * 10 **18;
        IERC1820Registry iERC1820Registry = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
        iERC1820Registry.setInterfaceImplementer(address(this), keccak256("IERC20Receiver"), address(this));
        iERC1820Registry.setInterfaceImplementer(address(this), keccak256("IProxy"), address(this));
    }

    // Allows an owner to voluntarily exit and withdraw their tokens.
    function voluntarilyExit() external onlyOwner {
        require(!_isOwnerVotedOut[msg.sender], "Proxy: You have been voted out");
        
        uint256 balance = _balanceOwner[msg.sender];
        if (balance > 0) {
            _transferTokens(msg.sender, balance);
        }

        _owners[msg.sender] = false;
        _totalOwners--;

        emit VoluntarilyExit(msg.sender, balance);

        if (_totalOwners == 0) {
            uint256 remainingBalance = ANHYDRITE.balanceOf(address(this));
            if (remainingBalance > 0) {
                require(ANHYDRITE.transfer(address(ANHYDRITE), remainingBalance), "Proxy: Failed to return remaining tokens to ANHYDRITE contract");
            }
        }
    }
    
    // Allows an owner to withdraw excess tokens from their deposit.
    function withdrawExcessTokens() external onlyOwner {
        require(!_isOwnerVotedOut[msg.sender], "Proxy: You have been voted out");
        uint256 ownerBalance = _balanceOwner[msg.sender];
        uint256 excess = 0;

        if (ownerBalance > _tokensNeededForOwnership) {
            excess = ownerBalance - _tokensNeededForOwnership;
            _transferTokens(msg.sender, excess);
        }
    }

    // Internal function to handle token transfers.
    function _transferTokens(address recepient, uint256 amount) private {
            _balanceOwner[recepient] -= amount;

            if(ANHYDRITE.balanceOf(address(this)) < amount) {
                ANHYDRITE.transferForProxy(amount);
            }
            require(ANHYDRITE.transfer(recepient, amount), "Proxy: Failed to transfer tokens");
    }

    // Allows the contract to rescue any accidentally sent tokens, except for its native Anhydrite token.
    function rescueTokens(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(ANHYDRITE), "Proxy: Cannot rescue the main token");
    
        IERC20 rescueToken = IERC20(tokenAddress);
        uint256 balance = rescueToken.balanceOf(address(this));
    
        require(balance > 0, "Proxy: No tokens to rescue");
    
        require(rescueToken.transfer(_implementation(), balance), "Proxy: Transfer failed");
    }

    // Implementation of IERC20Receiver, for receiving ERC20 tokens.
    function onERC20Received(address _from, address _who, uint256 _amount) external override returns (bytes4) {
        bytes4 fakeID = bytes4(keccak256("anything_else"));
        bytes4 validID = this.onERC20Received.selector;
        bytes4 returnValue = fakeID;  // Default value
        if (Address.isContract(msg.sender)) {
            if (msg.sender == address(ANHYDRITE)) {
                if (_owners[_who]) {
                    _balanceOwner[_who] += _amount;
                    emit DepositAnhydrite(_from, _who, _amount);
                    returnValue = validID;
                }
            } else {
                try IERC20(msg.sender).balanceOf(address(this)) returns (uint256 balance) {
                    if (balance >= _amount) {
                        emit ChallengeIERC20Receiver(_from, _who, msg.sender, _amount);
                        returnValue = validID;
                    }
                } catch {
                    // No need to change returnValue, it's already set to fakeID
                }
            }
        }
        return returnValue;
    }
}

// Interface to ensure that the global contract follows certain standards.
interface IAGE {
    // Gets the version of the global contract.
    function getVersion() external pure returns (uint256);
    // Adds a price.
    function addPrice(string memory name, uint256 count) external;
    // Gets a price.
    function getPrice(string memory name) external view returns (uint256);
    // Gets the server address from a token ID.
    function getServerFromTokenId(uint256 tokenId) external view returns (address);
    // Gets a token ID from a server address.
    function getTokenIdFromServer(address serverAddress) external view returns (uint256);
}

// Interface for interacting with the Anhydrite contract.
interface IANH is IERC20 {
    // Gets the max supply of the token.
    function getMaxSupply() external pure returns (uint256);
    // Transfers tokens for the proxy.
    function transferForProxy(uint256 amount) external;
}

interface IERC1820Registry {
    function setInterfaceImplementer(address account, bytes32 interfaceHash, address implementer) external;
    function getInterfaceImplementer(address account, bytes32 interfaceHash) external view returns (address);
}
