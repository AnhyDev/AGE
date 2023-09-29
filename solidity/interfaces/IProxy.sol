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
pragma solidity ^0.8.19;

//IProxy interface defines the methods a Proxy contract should implement.
interface IProxy {
	
 // Returns the core ERC20 token of the project
 function getCoreToken() external view returns (IERC20);

 // Returns the address of the current implementation (logic contract)
 function implementation() external view returns (address);

 // Returns the number of tokens needed to become an owner
 function getTokensNeededForOwnership() external view returns (uint256);

 // Returns the total number of owners
 function getTotalOwners() external view returns (uint256);

 // Checks if an address is a proxy owner (has voting rights)
 function isProxyOwner(address tokenAddress) external view returns (bool);

 // Checks if an address is an owner
 function isOwner(address account) external view returns (bool);

 // Returns the balance of an owner
 function getBalanceOwner(address owner) external view returns (uint256);

 // Checks if an address is blacklisted
 function isBlacklisted(address account) external view returns (bool);

 // Checks if the contract is stopped
 function isStopped() external view returns (bool);
 
 // Increases interest for voting participants
 function increase(address[] memory addresses) external;
 
}

