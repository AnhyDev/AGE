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

//Interface defining the essential functions for the AnhydriteMonitoring smart contract.
interface IAGEMonitoring {
 // Functions to add or remove server addresses.
 function addServerAddress(uint256 gameId, address serverAddress) external;
 function removeServerAddress(address serverAddress) external;
 
 // Voting mechanism handlers
 function voteForServer(address voterAddress, address serverAddress) external;
 function voteForServerWith10(address voterAddress, address serverAddress) external;
 function voteForServerWith100(address voterAddress, address serverAddress) external;
 function voteForServerWith1000(address voterAddress, address serverAddress) external;
 function voteForServerWith10000(address voterAddress, address serverAddress) external;
 function voteForServerWith100000(address voterAddress, address serverAddress) external;
 function voteForServerWith1000000(address voterAddress, address serverAddress) external;
 
 // Transaction burn fee calculators
 function getBurnFeeFor1Vote() external view returns (uint256);
 function getBurnFeeFor10Votes() external view returns (uint256);
 function getBurnFeeFor100Votes() external view returns (uint256);
 function getBurnFeeFor1000Votes() external view returns (uint256);
 function getBurnFeeFor10000Votes() external view returns (uint256);
 function getBurnFeeFor100000Votes() external view returns (uint256);
 function getBurnFeeFor1000000Votes() external view returns (uint256);
 
 // Functions to get information about servers.
 function getServerVotes(address serverAddress) external view returns (uint256);
 function getGameServerAddresses(uint256 gameId, uint256 startIndex, uint256 endIndex) external view returns (address[] memory);
 function isServerExist(address serverAddress) external view returns (bool);
 function getServerBlocked(address serverAddress) external view returns (bool, uint256);
}
