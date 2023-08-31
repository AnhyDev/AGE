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

interface IVotesInfo {
    // Function to get the status of voting for new Tokens Needed
    function getVoteForNewTokensNeeded() external view returns (uint256, uint256, uint256, uint256);
    // Function to get the status of voting for new implementation
    function getVoteForNewImplementationStatus() external view returns (address, uint256, uint256, uint256);
    // Function to get the status of voting for new owner
    function getVoteForNewOwnerStatus() external view returns (address, uint256, uint256, uint256);
    // Function to get the status of voting for remove owner
    function getVoteForRemoveOwnerStatus() external view returns (address, uint256, uint256, uint256);
    // Function to get the status of voting for Stopped
    function getVoteForStopped() external view returns (bool, uint256, uint256, uint256);

    function closeVoteForStopped() external;
    function closeVoteForTokensNeeded() external;
    function closeVoteForNewImplementation() external;
    function closeVoteForNewOwner() external;
    function closeVoteForRemoveOwner() external;

    // Events
    event CloseVoteForStopped(address indexed decisiveVote, uint votesFor, uint votesAgainst);
    event CloseVoteForTokensNeeded(address indexed decisiveVote, uint votesFor, uint votesAgainst);
    event CloseVoteForNewImplementation(address indexed decisiveVote, uint votesFor, uint votesAgainst);
    event CloseVoteForNewOwner(address indexed decisiveVote, address indexed votingObject, uint votesFor, uint votesAgainst);
    event CloseVoteForRemoveOwner(address indexed decisiveVote, address indexed votingObject, uint votesFor, uint votesAgainst);

}