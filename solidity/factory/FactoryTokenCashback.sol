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

import "../interfaces/IFactory.sol";
import "../common/BaseUtility.sol";
import "../modules/Token/TokenCashback.sol";


/**
 * @title FactoryTokenCashback
 * @dev This contract, FactoryTokenCashback, is utilized for the creation and management of 
 *      TokenCashback contracts. It allows for the dynamic deployment of new modules and their 
 *      removal when necessary, coordinating storage and management of the contracts.
 */
contract FactoryTokenCashback is IFactory, BaseUtility {

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
    event TokenCashbackCreated(address indexed moduleAddress, address indexed server, address indexed owner);

    /**
     * @dev Modifier to restrict the deployment of modules.
     */
    modifier onlyAllowed(address serverContractAddress) {
        require(!_proxyContract().isStopped(), "FactoryTokenCashback: Deploying is stopped");
        require(msg.sender == _proxyContract().implementation(), "FactoryTokenCashback: Caller is not the implementation");
        require(isDeploy[serverContractAddress] == address(0), "FactoryTokenCashback: This server has already deployed this module");
        _;
    }

    /**
     * @dev Function to deploy a new CashbackModule.
     * @param serverContractAddress Address of the associated server contract.
     * @param ownerAddress Address of the new owner of the deployed module.
     * @return Address of the deployed CashbackModule.
     */
    function deployModule(string memory, string memory,
            address serverContractAddress, address ownerAddress, string memory /*info*/)
                public onlyAllowed(serverContractAddress) returns (address) {

        TokenCashback newModule = new TokenCashback(serverContractAddress, address(this));
        if (ownerAddress != address(0)) {
            newModule.transferOwnership(ownerAddress);
        }
        
        isDeploy[serverContractAddress] = address(newModule);
        deployedModules.push(serverContractAddress);
        
        emit TokenCashbackCreated(address(newModule), serverContractAddress, ownerAddress);
        
        return address(newModule);
    }

    /**
     * @dev Function to remove a deployed SalesModule associated with a server contract.
     * @param serverContractAddress Address of the associated server contract.
     */
    function removeModule(address serverContractAddress) external {
        require(msg.sender == isDeploy[serverContractAddress], "FactoryTokenCashback: Module not deployed for this server");

        delete isDeploy[serverContractAddress]; 
    }

    /**
     * @dev Function to get the number of deployed modules.
     * @return Number of deployed modules.
     */
    function getAmountOfDeployedModules() public view returns (uint256) {
        return deployedModules.length;
    }

    /**
     * @dev Function to get the list of deployed modules.
     * @return Array of addresses of deployed modules.
     */
    function getDeployedModules() public view returns (address[] memory) {
        return deployedModules;
    }

    /**
     * @dev Function to retrieve a subset of the deployed modules between given indices.
     * @param startIndex Start index of the subset.
     * @param endIndex End index of the subset.
     * @return Array of addresses of deployed modules in the specified range.
     */
    function getDeployedModules(uint256 startIndex, uint256 endIndex) public view returns (address[] memory) {
        require(startIndex < deployedModules.length, "FactoryTokenCashback: Start index out of bounds");
    
        if(endIndex >= deployedModules.length) {
            endIndex = deployedModules.length - 1;
        }
    
        uint256 length = endIndex - startIndex + 1;
        address[] memory result = new address[](length);
    
        for (uint256 i = 0; i < length; i++) {
            result[i] = deployedModules[startIndex + i];
        }
    
        return result;
    }

    receive() external payable {
        payable(_proxyContract().implementation()).transfer(msg.value);
    }
}

