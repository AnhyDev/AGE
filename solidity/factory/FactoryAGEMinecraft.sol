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
 
// @filepath Repository Location: [solidity/factory/FactoryAGEMinecraft.sol]

pragma solidity ^0.8.19;

import "../servers/minecraft/AGEMinecraft.sol";
import "../interfaces/IFactory.sol";
import "../common/BaseAnh.sol";


contract FactoryAGEMinecraft is IFactory, BaseAnh {
 /**
     * @dev List of addresses of deployed modules.
     */
    address[] internal deployedModules;

    /**
     * @dev Mapping that links the server contract addresses to the deployed module addresses.
     */
    mapping(address => address) public isDeploy;

    /**
     * @dev Event emitted when a new module is created.
     */
    event AGEMinecraftCreated(address indexed moduleAddress, address indexed owner);

    /**
     * @dev Modifier to restrict the deployment of modules.
     */
    modifier onlyAllowed(address ownerAddress) {
        (address main, address age) = _getMainAndAGE();
        require(!IProvider(main).isStopped(), "FactoryAGEMinecraft: Deploying is stopped");
        require(isDeploy[ownerAddress] == address(0), "FactoryAGEMinecraft: This address has already deployed this server module");
        require(msg.sender == age, "FactoryAGEMinecraft: Only global contract allowed");
        _;
    }

    /**
     * @notice Deploys a new AGEMinecraft module.
     * @dev This function allows to create new instances of AGEMinecraft and keeps track of them.
     * @param name The name of the new AGEMinecraft module.
     * @param symbol The symbol of the new AGEMinecraft module.
     * @param /*serverContractAddress*//* Unused parameter, kept for interface adherence.
     * @param /*ownerAddress*//* Unused parameter, kept for interface adherence.
     * @param info Additional information or settings for the new module.
     * @return The address of the newly deployed AGEMinecraft module.
     */
    function deployModule(string memory name, string memory symbol,
            address /*serverContractAddress*/, address ownerAddress, string memory uri)
                external onlyAllowed(ownerAddress) returns (address) {

        AGEMinecraft newModule = new AGEMinecraft(ownerAddress, name, symbol, uri);
        
        isDeploy[ownerAddress] = address(newModule);
        deployedModules.push(address(newModule));
        
        emit AGEMinecraftCreated(address(newModule), ownerAddress);
        
        return address(newModule);
    }

    /**
     * @notice Returns the addresses of all deployed AGEMinecraft modules.
     * @return An array containing the addresses of all deployed modules.
     */
    function getDeployedModules() external view returns (address[] memory) {
        return deployedModules;
    }

    /**
     * @notice Returns the number of deployed AGEMinecraft modules.
     * @return The number of deployed modules.
     */
    function getNumberOfDeployedModules() external view returns (uint256) {
        return deployedModules.length;
    }
    
    /**
     * @dev Function to retrieve a subset of the deployed modules between given indices.
     * @param startIndex Start index of the subset.
     * @param endIndex End index of the subset.
     * @return Array of addresses of deployed modules in the specified range.
     */
    function getDeployedModules(uint256 startIndex, uint256 endIndex) public view returns (address[] memory) {
        require(startIndex < deployedModules.length, "FactoryAGEMinecraft: Start index out of bounds");
    
        if(endIndex >= deployedModules.length || endIndex < startIndex) {
            endIndex = deployedModules.length - 1;
        }
    
        uint256 length = endIndex - startIndex + 1;
        address[] memory result = new address[](length);
    
        for (uint256 i = 0; i < length; i++) {
            result[i] = deployedModules[startIndex + i];
        }
    
        return result;
    }

    /**
     * @notice A function to receive Ether payments.
     * @dev Transfers received Ether to the implementation of the proxied contract.
     */
    receive() external payable {
        payable(_getAGE()).transfer(msg.value);
    }


    /// @notice Stub function to meet interface requirements. No implementation.
    function removeModule(address /*serverContractAddress*/) external pure {
        revert("Not implemented");
    }
    
    /// @notice Stub function to meet interface requirements. Always returns 0.
    function getAmountOfDeployedModules() external pure returns (uint256) {
        return 0; // Stub: no real implementation
    }

}