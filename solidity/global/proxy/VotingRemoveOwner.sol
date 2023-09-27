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
            _resetVote(_votesForRemoveOwner);
            _balanceOwner[msg.sender] = 0;
            _isOwnerVotedOut[_proposedRemoveOwner] = false;
            _blackList[_proposedRemoveOwner] = true;
            emit VotingCompletedForRemoveOwner(msg.sender, _proposedRemoveOwner, vote, votestrue, votesfalse);
            _proposedRemoveOwner = address(0);
        } else if (votesfalse * 100 > _totalOwners * 40) {
            _totalOwners++;
            _resetVote(_votesForRemoveOwner);
            _isOwnerVotedOut[_proposedRemoveOwner] = false;
            emit VotingCompletedForRemoveOwner(msg.sender, _proposedRemoveOwner, vote, votestrue, votesfalse);
            _proposedRemoveOwner = address(0);
        }
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
