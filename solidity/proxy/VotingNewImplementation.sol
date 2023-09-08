/*
 * Copyright (C) 2023 Anhydrite Gaming Ecosystem
 *
 * This code is part of the Anhydrite Gaming Ecosystem.
 *
 * ERC-20 Token: Anhydrite ANH 0x578b350455932aC3d0e7ce5d7fa62d7785872221
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
            _resetVote(_votesForNewImplementation);
            emit VotingCompletedForNewImplementation(msg.sender, vote, votestrue, votesfalse);
            _proposedImplementation = address(0);
        } else if (votesfalse * 100 > _totalOwners * 40) {
            _resetVote(_votesForNewImplementation);
            emit VotingCompletedForNewImplementation(msg.sender, vote, votestrue, votesfalse);
            _proposedImplementation = address(0);
        }
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