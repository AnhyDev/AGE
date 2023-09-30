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

import "./GameData.sol";
import "./MonitoringManager.sol";
import "../../interfaces/IFactory.sol";


/*
 * This smart contract handles a modular system for managing various modules that can be added, updated, and removed.
 * It is an extension of a "Monitorings" contract and provides functionality to add new types of modules,
 * update existing ones, and query the state of these modules.
 */
abstract contract ModuleManager is MonitoringManager, GameData {
    
    // Structure defining a Module with a name, type, type as a string, and the address of its factory contract.
    struct Module {
        string moduleName;
        IAGEMetadata.ModuleType moduleType;
        string moduleTypeString;
        address moduleFactory;
    }

    // Store hashes of all modules.
    bytes32[] private _moduleList;
    // Mapping to store Module structs.
    mapping(bytes32 => Module) private _modules;

    // Adds a new module or updates an existing module
    function addOrUpdateModule(string memory moduleName, uint256 uintType,  address contractAddress, bool update) external onlyOwner {
        _addModule(moduleName, uintType, contractAddress, update);
    }

    // Adds a new Game Server module or pdates an existing Game Server module.
    function addOrUpdateGameServerModule(uint256 gameId, address contractAddress, bool update) external onlyOwner {
        (string memory moduleName,) = _getServerData(gameId);
        uint256 uintType = uint256(IModuleType.ModuleType.Server);
        _addModule(moduleName, uintType, contractAddress, update);
    }

    // Internal function to add or update a module.
    function _addModule(string memory moduleName, uint256 uintType, address contractAddress, bool update) private {
        bytes32 hash = _getModuleHash(moduleName, uintType);
        bool exist = _modules[hash].moduleFactory != address(0);
        bool isRevert = true;
        IAGEMetadata.ModuleType moduleType = IModuleType.ModuleType(uintType);
        Module memory module  = Module({
            moduleName: moduleName,
            moduleType: moduleType,
            moduleTypeString: _getModuleTypeString(moduleType),
            moduleFactory: contractAddress
        });

        if (update) {
            if (exist) {
                _modules[hash] = module;
                delete isRevert;
            }
        } else {
            if (!exist) {
                _modules[hash] = module;
                _moduleList.push(hash);
                delete isRevert;
            }
        }
        if (isRevert) {
            revert("Modules: Such a module already exists");
        }
    }

    // Removes an existing module.
    function removeModule(string memory moduleName, uint256 uintType) external  onlyOwner {
        bytes32 hash = _getModuleHash(moduleName, uintType);
        if (_modules[hash].moduleFactory != address(0)) {
            _modules[hash] = Module("", IModuleType.ModuleType.Server, "", address(0));
            for (uint256 i = 0; i < _moduleList.length; i++) {
                if (_moduleList[i] == hash) {
                    _moduleList[i] = _moduleList[_moduleList.length - 1];
                    _moduleList.pop();
                    return;
                }
            }
        } else {
                revert("Modules: Such a module does not exist");
        }
    }

    // Retrieves all modules without any filtering.
    function getAllModules() external view returns (Module[] memory) {
        return _getFilteredModules(0xFFFFFFFF);
    }

    // Retrieves modules filtered by a specific type.
    function getModulesByType(IAGEMetadata.ModuleType moduleType) external view returns (Module[] memory) {
        return _getFilteredModules(uint256(moduleType));
    }

    // Internal function to get modules filtered by type.
    function _getFilteredModules(uint256 filterType) private view returns (Module[] memory) {
        uint256 count = 0;
        IAGEMetadata.ModuleType filteredType = IModuleType.ModuleType(filterType);

        for (uint256 i = 0; i < _moduleList.length; i++) {
            bytes32 hash = _moduleList[i];
            if (filterType == 0xFFFFFFFF || _modules[hash].moduleType == filteredType) {
                count++;
            }
        }

        Module[] memory filteredModules = new Module[](count);

        uint256 j = 0;
        for (uint256 i = 0; i < _moduleList.length; i++) {
            bytes32 hash = _moduleList[i];
            if (filterType == 0xFFFFFFFF || _modules[hash].moduleType == filteredType) {
                filteredModules[j] = _modules[hash];
                j++;
            }
        }

        return filteredModules;
    }

    // Internal function to check if a module exists.
    function _isModuleExists(bytes32 hash) private view returns (bool) {
        bool existModule = _modules[hash].moduleFactory != address(0);
        return existModule;
    }

    // Deploys a module on a server. 
    // Checks if the server is authorized to deploy the module.
    function deployModuleOnServer(string memory factoryName, uint256 uintType, address ownerAddress)
      external onlyServerAutorised(msg.sender) returns (address) {
        uint256 END_OF_LIST = 1000;
        return _deploy(END_OF_LIST, factoryName, uintType, ownerAddress, "");
    }

    // Deploys a new game server contract and adds it to monitoring.
    function deployServerContract(uint256 gameId, string memory info) external returns (address) {
        uint256 uintType = uint256(IModuleType.ModuleType.Server);
        (string memory contractName,) = _getServerData(gameId);

        address minecraftServerAddress = _deploy(gameId, contractName, uintType, address(0), info);

        _mintTokenForServer(minecraftServerAddress);
        _addServerToMonitoring(gameId, minecraftServerAddress);

        return minecraftServerAddress;
    }

    // Abstract function to mint a token for a server.
    // Implementation is supposed to be provided by a derived contract.
    function _mintTokenForServer(address serverAddress) internal virtual;

    // Internal function to handle the actual deployment of modules or servers.
    function _deploy(uint256 gameId, string memory factoryName, uint256 uintType, address ownerAddress, string memory info) private returns (address) {
        bytes32 hash = _getModuleHash(factoryName, uintType);

        (string memory name, string memory symbol) = _getServerData(gameId);
        return IFactory(_getModule(hash).moduleFactory).deployModule(name, symbol, msg.sender, ownerAddress, info);
    }

    // Internal utility function to fetch a module's data.
    function _getModule(bytes32 hash) private view returns (Module memory) {
        require(_isModuleExists(hash), "Modules: The module with this name and type does not exist");
        return _modules[hash];
    }

    // Internal utility function to calculate hash for a module.
    function _getModuleHash(string memory name, uint256 uintType) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(name, uintType));
    }

    // Modifier to check if the address is an authorized server.
    modifier onlyServerAutorised(address contractAddress) {
        require(_isServerMonitored(contractAddress), "Modules: This address is not monitored or blocked");
        _;
    }
}
