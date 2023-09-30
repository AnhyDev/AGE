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

import "./VoteUtility.sol";
import "../../openzeppelin/contracts/interfaces/IERC165.sol";
import "../../interfaces/IERC20Receiver.sol";


/*
 * This abstract contract extends the VoteUtility contract to manage a whitelist of smart contract addresses.
 * Key features include:
 * 1. Initiating a proposal to either allow or disallow a smart contract address, done by an owner.
 * 2. Allowing current owners to vote on the proposal to either whitelist or delist the smart contract address.
 * 3. Employing a two-stage vote verification mechanism that checks whether the voter is an owner and hasn't voted before.
 * 4. Voting must reach a 60% threshold for the proposed smart contract address to be whitelisted or delisted.
 * 5. Automatic failure of the proposal if over 40% of the votes are against it.
 * 6. Detailed event logs for each stage of the voting process, enhancing auditing and transparency.
 * 7. Functionality to manually close an open vote if the required threshold isn't met within a predefined time frame.
 * 8. Utility functions to query the status of a proposed contract address, check for an active vote, and verify if an address is whitelisted.
 * 9. Implements an interface check to ensure that the proposed smart contract adheres to the IERC20Receiver interface, but only for addition to the whitelist.
 * 10. Internal helper functions to streamline and modularize code for better maintainability and upgradeability.
 */
abstract contract WhiteListManager is VoteUtility {

    // Stores the whitelist status of each address
    mapping(address => bool) internal _whiteList;

    // Proposed new contract address for whitelist operations (either addition or removal)
    address private _proposedContract;

    // Structure holding the voting details for a proposed contract
    VoteResult private _votesForContract;

    // Indicates whether the operation is an addition (1) or removal (2)
    uint256 private _addOrDelete;

    // Event fired when a vote to allow a contract is initiated
    event VotingForWhiteListContract(address indexed voter, address proposedContract, bool vote);

    // Event fired when a vote to allow a contract is completed
    event VotingAllowContractCompleted(address indexed voter, address addedContract, bool vote, uint votesFor, uint votesAgainst);
    // Event fired when a vote to remove a contract is completed
    event VotingDeleteContractCompleted(address indexed voter, address deleteContract, bool vote, uint votesFor, uint votesAgainst);

    // Event fired to close an expired poll to remove a contract
    event CloseVoteForWhiteList(address indexed decisiveVote, address indexed votingObject, uint votesFor, uint votesAgainst);

    // Function to initiate a new voting round for whitelist changes
    function initiateVoteWhiteList(address proposedContract) public onlyOwner {
        require(_proposedContract == address(0), "WhiteListManager: voting is already activated");
        
        if (!_whiteList[proposedContract]) {
            // Checks if the proposed contract adheres to the IERC20Receiver interface
            require(proposedContract.code.length > 0 &&
                (_or1820RegistryReturnIERC20Received(proposedContract) ||
                    IERC165(proposedContract).supportsInterface(type(IERC20Receiver).interfaceId)), 
                        "WhiteListManager: This address does not represent a contract that implements the IANHReceiver interface.");
            _addOrDelete = 1;
        }

        _proposedContract = proposedContract;
        _votesForContract = VoteResult(new address[](0), new address[](0), block.timestamp);
        
        // Cast an initial vote
        _voteForContract(true);
    }

    // Helper function to check if a contract implements IERC20Received
    function _or1820RegistryReturnIERC20Received(address contractAddress) internal view virtual returns (bool);

    // Public function to allow owners to cast their votes
    function voteForWhiteList(bool vote) external onlyOwner {
        _voteForContract(vote);
    }

    // Internal function to handle the vote casting and evaluation logic
    function _voteForContract(bool vote) private hasNotVoted(_votesForContract) {
        require(_proposedContract != address(0), "WhiteListManager: there are no votes at this address");

        (uint256 votestrue, uint256 votesfalse, VoteResultType result) = _votes(_votesForContract, vote);

        // Emit appropriate voting event
        emit VotingForWhiteListContract(msg.sender, _proposedContract, vote);

        // Evaluate if the voting has met either pass or fail conditions
        if (result == VoteResultType.Approved) {
            _whiteList[_proposedContract] = !_whiteList[_proposedContract];
            _completionVotingWhiteList(vote, votestrue, votesfalse);
        } else if (result == VoteResultType.Rejected) {
            _completionVotingWhiteList(vote, votestrue, votesfalse);
        }
    }
    
    // Internal function to finalize the voting round and apply the changes if applicable
    function _completionVotingWhiteList(bool vote, uint256 votestrue, uint256 votesfalse) internal {
        // Emit appropriate completion event
        if (_addOrDelete == 1) {
            emit VotingAllowContractCompleted(msg.sender, _proposedContract, vote, votestrue, votesfalse);
        } else {
            emit VotingDeleteContractCompleted(msg.sender, _proposedContract, vote, votestrue, votesfalse);
        }

        // Reset voting variables for the next round
        _completionVoting(_votesForContract);
        _proposedContract = address(0);
        _addOrDelete = 0;
    }

    // Public function to manually close a voting round that has expired without a decision
    function closeVoteForWhiteList() public onlyOwner {
        require(_proposedContract != address(0), "WhiteListManager: There is no open vote");

        // Emit appropriate closing event
        emit CloseVoteForWhiteList(
                msg.sender, _proposedContract, _votesForContract.isTrue.length, _votesForContract.isFalse.length
        );

        // Reset voting variables for the next round
        _closeVote(_votesForContract);
        _proposedContract = address(0);
        _addOrDelete = 0;
    }

    // Function to get details of the active vote (if any)
    function getActiveForVoteWhiteList() external view returns (address, bool, string memory) {
        require(_proposedContract != address(0), "WhiteListManager: There is no active voting");
        return (_proposedContract, !_whiteList[_proposedContract], _addOrDelete == 1 ? "Add" : "Delete");
    }

    // Function to check if a given address is whitelisted
    function isinWhitelist(address contractAddress) external view returns (bool) {
        return _whiteList[contractAddress];
    }
}
