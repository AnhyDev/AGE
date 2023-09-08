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
            _resetVote(_votesForStopped);
            emit VotingCompletedForStopped(msg.sender, true, votestrue, votesfalse);
            
       } else if (votesfalse * 100 > _totalOwners * 40) {
           _proposedStopped = _stopped;
            _resetVote(_votesForStopped);
            emit VotingCompletedForStopped(msg.sender, false, votestrue, votesfalse);
        }
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