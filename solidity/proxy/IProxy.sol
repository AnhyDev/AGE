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
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface IProxy {
    // Returns an ERC20 standard token, which is the main token of the project
    function getToken() external view returns (IERC20);
    // A function for obtaining the address of a global smart contract
    function getImplementation() external view returns (address);
    // A function to obtain information about whether the basic functions of the smart contract are stopped
    function isStopped() external view returns (bool);
    // Function for obtaining information about the total number of owners
    function getTotalOwners() external view returns (uint256);
    // The function for obtaining information whether the address is among the owners and whether it has the right to vote
    function isProxyOwner(address tokenAddress) external view returns (bool);
    // Function for obtaining information whether the address is among the owners
    function isOwner(address account) external view returns (bool);
    // Function for obtaining information about the balance of the owner
    function getBalanceOwner(address owner) external view returns (uint256);
    // A function to obtain information about the number of Master Tokens required on the owner's balance to be eligible to vote
    function getTokensNeededForOwnership() external view returns (uint256);
    // Checks if the address is blacklisted
    function isBlacklisted(address account) external view returns (bool);
    // Function for obtaining information about whether the address is in the black list
    function depositTokens(uint256 amount) external;
    // A function for voluntary resignation of the owner from his position. At the same time, his entire deposit is returned to his balance.
    function voluntarilyExit() external;
    // A function for the owner to withdraw excess tokens from his deposit
    function withdrawExcessTokens() external;
    // Function to transfer tokens from the balance of the proxy smart contract to the balance of the global smart contract.
    // At the same time, it is impossible to transfer the global token
    function rescueTokens(address tokenAddress) external;

    // A Event for voluntary resignation of the owner from his position.
    event VoluntarilyExit(address indexed votingSubject, uint returTokens);
}
