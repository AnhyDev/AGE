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
 
// @filepath Repository Location: [solidity/global/common/MainManager.sol]

pragma solidity ^0.8.19;

import "../common/VoteUtility.sol";
import "./AnhydriteManager.sol";

/*
 * This abstract contract extends the UtilityVotingAndOwnable contract to facilitate governance of smart contract proxies.
 * Key features include:
 * 1. Initiating a proposal for setting a new Main address.
 * 2. Voting on the proposed new Main address by the Main owners.
 * 3. Automatic update of the Main address if a 70% threshold of affirmative votes is reached.
 * 4. Automatic cancellation of the proposal if over 30% of the votes are against it.
 * 5. Functionality to manually close an open vote that has been pending for more than three days without a conclusive decision.
 * 6. Events to log voting actions and outcomes for transparency and auditing purposes.
 * 7. Utility functions to check the status of the active vote and the validity of the proposed Main address.
 */
abstract contract MainManager is VoteUtility, AnhydriteManager {

    // A new smart contract Main address is proposed
    address private _proposedMain;
    // Structure for counting votes
    VoteResult private _votesForNewMain;

    // Event about the fact of voting, parameters: voter, proposedMain, vote
    event VotingForNewMain(address indexed voter, address indexed proposedMain, bool vote);
    // Event about the fact of making a decision on voting, parameters: voter, proposedMain, vote, votesFor, votesAgainst
    event VotingNewMainCompleted(address indexed voter, address indexed oldMain, address indexed newMain, bool vote, uint votesFor, uint votesAgainst);
    // Event to close a poll that has expired
    event CloseVoteForNewMain(address indexed decisiveVote, address indexed votingObject, uint votesFor, uint votesAgainst);

    // Voting start initiation, parameters: proposedNewMain
    function initiateNewMain(address proposedNewMain) public onlyOwner {
        require(_proposedMain == address(0), "MainManager: voting is already activated");
        require(_checkIProviderContract(proposedNewMain), "MainManager: This address does not represent a contract that implements the IMain interface.");

        _proposedMain = proposedNewMain;
        _votesForNewMain = VoteResult(new address[](0), new address[](0), block.timestamp);
        _voteForNewMain(true);
    }

    // Vote to change the owner of a smart contract
    function voteForNewMain(bool vote) external onlyOwner {
        _voteForNewMain(vote);
    }

    // Votes must reach a 60% threshold to pass. If over 40% are downvotes, the measure fails.
    function _voteForNewMain(bool vote) private {
        _checkOwnerVoted(_votesForNewMain);
        require(_proposedMain != address(0), "MainManager: there are no votes at this address");

        (uint256 votestrue, uint256 votesfalse, VoteResultType result) = _votes(_votesForNewMain, vote);

        emit VotingForNewMain(msg.sender, _proposedMain, vote);

        if (result == VoteResultType.Approved) {
            address oldMain = _getMain();
            _setAddressMain(_proposedMain);
            _completionVotingNewMain(oldMain, vote, votestrue, votesfalse);
        } else if (result == VoteResultType.Rejected) {
            _completionVotingNewMain(_getMain(), vote, votestrue, votesfalse);
        }
    }
    
    // Completion of voting
    function _completionVotingNewMain(address oldMain, bool vote, uint256 votestrue, uint256 votesfalse) private {
        emit VotingNewMainCompleted(oldMain, msg.sender, _proposedMain, vote, votestrue, votesfalse);
        _completionVoting(_votesForNewMain);
        _proposedMain = address(0);
    }

    // A function to close a vote on which a decision has not been made for three or more days
    function closeVoteForNewMain() public onlyOwner {
        require(_proposedMain != address(0), "MainManager: There is no open vote");
        emit CloseVoteForNewMain(msg.sender, _proposedMain, _votesForNewMain.isTrue.length, _votesForNewMain.isFalse.length);
        _closeVote(_votesForNewMain);
        _proposedMain = address(0);
    }

    // A function for obtaining information about the status of voting
    function getActiveForVoteNewMain() external view returns (address) {
        require(_proposedMain != address(0), "MainManager: re is no active voting");
        return _proposedMain;
    }
}
