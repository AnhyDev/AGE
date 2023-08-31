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

interface IVotes {
    // A function for opening a vote on stopping or resuming the operation of a smart contract
    function startVotingForStopped(bool _proposed) external;
    // The function of voting for stopping and resuming the work of a smart contract
    function voteForStopped(bool vote) external;
    function startVotingForNeededForOwnership(uint256 _proposed) external;
    function voteForNeededForOwnership(bool vote) external;
    function startVotingForNewImplementation(address _proposed) external;
    function voteForNewImplementation(bool vote) external;
    function initiateOwnershipRequest() external;
    function voteForNewOwner(address _owner, bool vote) external;
    function startVotingForRemoveOwner(address _proposed) external;
    function voteForRemoveOwner(bool vote) external;

    // Events
    event VotingForStopped(address indexed addressVoter, bool indexed vote);
    event VotingCompletedForStopped(address indexed decisiveVote, bool indexed result, uint votesFor, uint votesAgainst);

    event VotingForTokensNeeded(address indexed addressVoter, bool indexed vote);
    event VotingCompletedForTokensNeeded(address indexed decisiveVote, bool indexed result, uint votesFor, uint votesAgainst);

    event VotingForNewImplementation(address indexed addressVoter, bool indexed vote);
    event VotingCompletedForNewImplementation(address indexed decisiveVote, bool indexed result, uint votesFor, uint votesAgainst);

    event VotingForNewOwner(address indexed addressVoter, address indexed votingObject, bool indexed vote);
    event VotingCompletedForNewOwner(address indexed decisiveVote, address indexed votingObject, bool indexed result, uint votesFor, uint votesAgainst);

    event VotingForRemoveOwner(address indexed addressVoter, address indexed votingObject, bool indexed vote);
    event VotingCompletedForRemoveOwner(address indexed decisiveVote, address indexed votingObject, bool indexed result, uint votesFor, uint votesAgainst);

    event InitiateOwnership(address indexed subject, bool indexed result);
}