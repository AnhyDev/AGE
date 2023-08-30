abstract contract Votes is IVotes, Proxy {
    


    // A function for opening a vote on stopping or resuming the operation of a smart contract
    function startVotingForStopped(bool _proposed) public onlyOwner canYouVote(_votesForStopped) {
        require(_stopped != _proposed, "Votes: This vote will not change the Stop status");
        require(_proposed != _proposedStopped, "Votes: Voting has already started");
        _proposedStopped = _proposed;
        _votesForStopped.timestamp = block.timestamp;
        _voteForStopped(true);
    }

    // The function of voting for stopping and resuming the work of a smart contract
    function voteForStopped(bool vote) public onlyOwner canYouVote(_votesForStopped) {
        _voteForStopped(vote);
    }

    function _voteForStopped(bool vote) internal {
        require(_stopped != _proposedStopped, "Votes: There is no active voting on this issue");

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

    // A function for opening a vote on changing the number of tokens required for the right to vote
    function startVotingForNeededForOwnership(uint256 _proposed) public onlyOwner canYouVote(_votesForStopped) {
        require(_proposed != 0, "Votes: The supply of need for ownership tokens cannot be zero");
        require(_tokensNeededForOwnership != _proposed, "Votes: This vote will not change the need for ownership tokens");
        require(_proposedTokensNeeded == 0, "Votes: Voting has already started");
        _proposedTokensNeeded = _proposed;
        _votesForTokensNeeded.timestamp = block.timestamp;
        _voteForNeededForOwnership(true);
    }

    // Voting function for changing the number of tokens on the balance required for the right to vote
    function voteForNeededForOwnership(bool vote) public onlyOwner canYouVote(_votesForTokensNeeded) {
        _voteForNeededForOwnership(vote);
    }

    // Voting function for changing the number of tokens on the balance required for the right to vote
    function _voteForNeededForOwnership(bool vote) internal {
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

    // A function to open voting on the replacement of the address of the global smart contract
    function startVotingForNewImplementation(address _proposed) public onlyOwner canYouVote(_votesForStopped) {
        require(_proposed != address(0), "Votes: Cannot set null address");
        require(_implementation != _proposed, "Votes: This vote will not change the implementation address");
        require(_proposedImplementation == address(0), "Votes: Voting has already started");
        require(_checkContract(_proposed), "Votes: The contract does not meet the standard");
        _proposedImplementation = _proposed;
        _votesForNewImplementation.timestamp = block.timestamp;
        _voteForNewImplementation(true);
    }

    // Global smart contract address change voting function
    function voteForNewImplementation(bool vote) public onlyOwner canYouVote(_votesForNewImplementation) {
        _voteForNewImplementation(vote);
    }
    function _voteForNewImplementation(bool vote) internal {
        require(_proposedImplementation != address(0), "Votes: There is no active voting on this issue");

        (uint votestrue, uint votesfalse) = _votes(_votesForNewImplementation, vote);

        emit VotingForNewImplementation(msg.sender, vote);

        if (votestrue * 100 >= _totalOwners * 60) {
            _implementation = _proposedImplementation;
            _resetVote(_votesForNewImplementation);
            emit VotingCompletedForNewImplementation(msg.sender, vote, votestrue, votesfalse);
            _proposedImplementation = address(0);
        } else if (votesfalse * 100 > _totalOwners * 40) {
            _resetVote(_votesForNewImplementation);
            emit VotingCompletedForNewImplementation(msg.sender, vote, votestrue, votesfalse);
            _proposedImplementation = address(0);
        }
    }

    // Function for submitting an application for admission to owners
    function initiateOwnershipRequest() public {
        require(!_owners[msg.sender], "Votes: Already an owner");
        require(!_blackList[msg.sender], "Votes: This address is blacklisted");
        require(block.timestamp >= _initiateOwners[msg.sender] + 30 days, "Votes: Voting is still open");
        require(_token.allowance(msg.sender, address(this)) >= _tokensNeededForOwnership, "Votes: Not enough tokens allowed for transfer");
        require(_token.balanceOf(msg.sender) >= _tokensNeededForOwnership, "Votes: Not enough tokens for transfer");

        _initiateOwners[msg.sender] = block.timestamp;
        _token.transferFrom(msg.sender, address(this), _tokensNeededForOwnership);
        _balanceOwner[msg.sender] += _tokensNeededForOwnership;

        _proposedOwner = msg.sender;
        _votesForNewOwner = VoteResult(new address[](0), new address[](0), block.timestamp);
        emit InitiateOwnership(msg.sender, true);
    }

    // Voting function for accepting a new owner
    function voteForNewOwner(address _owner, bool vote) public onlyOwner canYouVote(_votesForNewOwner) {
        require(_proposedOwner != address(0) && _proposedOwner ==  _owner, "Votes: There is no active voting on this issue");

        (uint votestrue, uint votesfalse) = _votes(_votesForNewOwner, vote);

        emit VotingForNewOwner(msg.sender, _proposedOwner, vote);

        if (votestrue * 100 >= _totalOwners * 60) {
            _owners[_proposedOwner] = true;
            _totalOwners++;
            _resetVote(_votesForNewOwner);
            emit VotingCompletedForNewOwner(msg.sender, _proposedOwner, vote, votestrue, votesfalse);
            _proposedOwner = address(0);
        } else if (votesfalse * 100 > _totalOwners * 40) {
            _token.transfer(_proposedOwner, _balanceOwner[msg.sender]);
            _resetVote(_votesForNewOwner);
            emit VotingCompletedForNewOwner(msg.sender, _proposedOwner, vote, votestrue, votesfalse);
            _proposedOwner = address(0);
        }
    }

    // A function to open a vote on the exclusion of the owner
    function startVotingForRemoveOwner(address _proposed) public onlyOwner canYouVote(_votesForStopped) {
        require(_proposed != address(0), "Votes: Cannot set null address");
        require(_owners[_proposed], "Votes: This address is not included in the list of owners");
        require(_proposedRemoveOwner == address(0), "Votes: Voting has already started");
        _proposedRemoveOwner = _proposed;
        _votesForRemoveOwner.timestamp = block.timestamp;
        _isOwnerVotedOut[_proposed] = true;
        _totalOwners--;
        _voteForRemoveOwner(true);
    }

    // The function of voting for the exclusion of the owner, while his deposit is confiscated
    function voteForRemoveOwner(bool vote) public onlyOwner canYouVote(_votesForRemoveOwner) {
        _voteForRemoveOwner(vote);
    }

    function _voteForRemoveOwner(bool vote) internal {
        require(_proposedRemoveOwner != msg.sender, "You cannot vote for yourself");
        require(_proposedRemoveOwner != address(0), "Votes: There is no active voting on this issue");

        (uint votestrue, uint votesfalse) = _votes(_votesForRemoveOwner, vote);

        emit VotingForRemoveOwner(msg.sender, _proposedOwner, vote);

        if (votestrue * 100 >= _totalOwners * 60) {
            _owners[_proposedRemoveOwner] = false;
            _resetVote(_votesForRemoveOwner);
            _balanceOwner[msg.sender] = 0;
            _isOwnerVotedOut[_proposedRemoveOwner] = false;
            _blackList[_proposedRemoveOwner] = true;
            emit VotingCompletedForRemoveOwner(msg.sender, _proposedOwner, vote, votestrue, votesfalse);
            _proposedRemoveOwner = address(0);
        } else if (votesfalse * 100 > _totalOwners * 40) {
            _owners[_proposedRemoveOwner] = false;
            _totalOwners++;
            _resetVote(_votesForRemoveOwner);
            _isOwnerVotedOut[_proposedRemoveOwner] = false;
            emit VotingCompletedForRemoveOwner(msg.sender, _proposedOwner, vote, votestrue, votesfalse);
            _proposedRemoveOwner = address(0);
        }
    }


    // Internal functions

    function _votes(VoteResult storage result, bool vote) internal returns (uint256, uint256) {
        if (vote) {
            result.isTrue.push(msg.sender);
        } else {
            result.isFalse.push(msg.sender);
        }
        return (result.isTrue.length, result.isFalse.length);
    }

    function _getVote(VoteResult memory vote, address addresess) private pure returns (address, uint256, uint256, uint256) {
        return (
            addresess, 
            vote.isTrue.length, 
            vote.isFalse.length, 
            vote.timestamp
        );
    }

    function _resetVote(VoteResult storage vote) internal {
        _increaseByPercent(vote.isTrue, vote.isFalse);
        vote.isTrue = new address[](0);
        vote.isFalse = new address[](0);
        vote.timestamp = 0;
    }

    function _increaseByPercent(address recepient) private {
        uint256 percent = _tokensNeededForOwnership * 1 / 100;
        _balanceOwner[recepient] += percent;
    }

    function _increaseByPercent(address[] memory addresses1, address[] memory addresses2) private {
        for (uint256 i = 0; i < addresses1.length; i++) {
            _increaseByPercent(addresses1[i]);
        }

        for (uint256 j = 0; j < addresses2.length; j++) {
            _increaseByPercent(addresses2[j]);
        }
    }
}
