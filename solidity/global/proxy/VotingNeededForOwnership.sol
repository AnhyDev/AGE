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
            emit VotingCompletedForTokensNeeded(msg.sender, vote, votestrue, votesfalse);
            _resetVote(_votesForTokensNeeded);
            _proposedTokensNeeded = 0;
       } else if (votesfalse * 100 > _totalOwners * 40) {
            emit VotingCompletedForTokensNeeded(msg.sender, vote, votestrue, votesfalse);
            _resetVote(_votesForTokensNeeded);
            _proposedTokensNeeded = 0;
        }
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