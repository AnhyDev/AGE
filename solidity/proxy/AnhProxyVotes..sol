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

contract AnhydriteProxyVotes is IVotesInfo, Votes {
    

    // Function to get the status of voting for new Tokens Needed
    function getVoteForNewTokensNeeded() public view returns (uint256, uint256, uint256, uint256) {
        return (
            _proposedTokensNeeded, 
            _votesForNewOwner.isTrue.length, 
            _votesForNewOwner.isFalse.length, 
            _votesForNewOwner.timestamp
        );
    }

    // Function to get the status of voting for new implementation
    function getVoteForNewImplementationStatus() public view returns (address, uint256, uint256, uint256) {
        return _getVote(_votesForNewImplementation, _proposedImplementation);
    }

    // Function to get the status of voting for new owner
    function getVoteForNewOwnerStatus() public view returns (address, uint256, uint256, uint256) {
        return _getVote(_votesForNewOwner, _proposedOwner);
    }

    // Function to get the status of voting for remove owner
    function getVoteForRemoveOwnerStatus() public view returns (address, uint256, uint256, uint256) {
        return _getVote(_votesForRemoveOwner, _proposedRemoveOwner);
    }

    // Function to get the status of voting for Stopped
    function getVoteForStopped() public view returns (bool, uint256, uint256, uint256) {
            return (
            _proposedStopped != _stopped,
            _votesForStopped.isTrue.length, 
            _votesForStopped.isFalse.length, 
            _votesForStopped.timestamp
        );
    }
    
    // The following functions are designed to close the vote if more than 3 days have passed and no decision has been made

    function closeVoteForStopped() public onlyOwner {
        require(_stopped != _proposedStopped, "There is no open vote");
        emit CloseVoteForStopped(msg.sender, _votesForStopped.isTrue.length, _votesForStopped.isFalse.length);
        _closeVote(_votesForStopped);
        _proposedStopped = _stopped;
    }

    function closeVoteForTokensNeeded() public onlyOwner {
        require(_proposedTokensNeeded != 0, "There is no open vote");
        emit CloseVoteForTokensNeeded(msg.sender, _votesForTokensNeeded.isTrue.length, _votesForTokensNeeded.isFalse.length);
        _closeVote(_votesForTokensNeeded);
        _proposedTokensNeeded = 0;
    }

    function closeVoteForNewImplementation() public onlyOwner {
        require(_proposedImplementation != address(0), "There is no open vote");
        emit CloseVoteForNewImplementation(msg.sender, _votesForNewImplementation.isTrue.length, _votesForNewImplementation.isFalse.length);
        _closeVote(_votesForNewImplementation);
        _proposedImplementation = address(0);
    }

    function closeVoteForNewOwner() public onlyOwner {
        require(_proposedOwner != address(0), "There is no open vote");
        _token.transfer(_proposedOwner, _balanceOwner[msg.sender]);
        emit CloseVoteForNewOwner(msg.sender, _proposedOwner, _votesForNewOwner.isTrue.length, _votesForNewOwner.isFalse.length);
        _closeVote(_votesForNewOwner);
        _proposedOwner = address(0);
    }

    function closeVoteForRemoveOwner() public onlyOwner {
        require(_proposedRemoveOwner != address(0), "There is no open vote");
        _isOwnerVotedOut[_proposedRemoveOwner] = false;
        emit CloseVoteForRemoveOwner(msg.sender, _proposedRemoveOwner, _votesForRemoveOwner.isTrue.length, _votesForRemoveOwner.isFalse.length);
        _closeVote(_votesForRemoveOwner);
        _proposedRemoveOwner = address(0);
        _totalOwners++;
    }

    function _closeVote(VoteResult storage vote) private canClose(vote.timestamp) {
        _resetVote(vote);
        _increaseByPercent(msg.sender);
    }
}

