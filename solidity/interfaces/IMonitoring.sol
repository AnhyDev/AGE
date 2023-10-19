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
 
// @filepath Repository Location: [solidity/interfaces/IMonitoring.sol]

pragma solidity ^0.8.19;

interface IMonitoring {

    // Enum declaration for server status
    enum ServerStatus {
        NotFound,
        Monitored,
        Blocked
    }

    // Add a new address to the monitoring list.
    function addMonitoring(address newAddress) external;

    // Get the last non-zero monitoring address and its index.
    function getMonitoring() external view returns (Monitoring memory);

    // Get the list of non-zero monitoring addresses.
    function getMonitoringAddresses() external view returns (Monitoring[] memory);

    // Remove an address from the monitoring list by replacing it with the zero address.
    function removeMonitoringAddress(address addressToRemove) external;

    // Check whether the specified address is monitored and not blocked or not found
    function getServerMonitoringStatus(address serverAddress) external view returns (string memory);

    // Get the number of votes on monitorings for the specified address
    function getTotalServerVotes(address serverAddress) external view returns (uint256);

    // Structs used in the functions above
    struct Monitoring {
        uint256 version;
        address addr;
    }
}
