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

import "./IModuleType.sol";

interface IModuleManager {
    
    struct Module {
        string moduleName;
        IModuleType.ModuleType moduleType;
        string moduleTypeString;
        address moduleFactory;
    }

    function addOrUpdateModule(string memory moduleName, uint256 uintType, address contractAddress, bool update) external;
    
    function addOrUpdateGameServerModule(uint256 gameId, address contractAddress, bool update) external;
    
    function removeModule(string memory moduleName, uint256 uintType) external;
    
    function getAllModules() external view returns (Module[] memory);
    
    function getModulesByType(IModuleType.ModuleType moduleType) external view returns (Module[] memory);
    
    function deployModuleOnServer(string memory factoryName, uint256 uintType, address ownerAddress) external returns (address);
    
    function deployServerContract(uint256 gameId, string memory info) external returns (address);
    
}
