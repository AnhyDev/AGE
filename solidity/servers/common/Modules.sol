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
 
// @filepath Repository Location: [solidity/servers/common/Modules.sol]

pragma solidity ^0.8.19;

import "../../openzeppelin/contracts/access/Ownable.sol";
import "../../common/BaseUtility.sol";
import "../../interfaces/IAGEModule.sol";
import "../../interfaces/IAGEMetadata.sol";

abstract contract Modules is Ownable, BaseUtility {

    struct Module {
        string moduleName;
        IModuleType.ModuleType moduleType;
        string moduleTypeString;
        address moduleDeployedAddress;
    }

    bytes32[] internal _moduleList;
    mapping(bytes32 => Module) internal _modules;

    event DeployModule(address indexed sender, address indexed server, address indexed contractAddress, string moduleName, uint256 moduleId);


    // Deploy a module
    function deployModule(string memory name, uint256 moduleId) external onlyOwner {
        IModuleType.ModuleType moduleType = IModuleType.ModuleType(moduleId);
        bytes32 hash = _getModuleHash(name, moduleType);
        require(!_isModuleInstalled(hash), "Modules: Module already installed");
        address contractAddress = _getFullAGEContract().deployModuleOnServer(name, moduleId, msg.sender);

        Module memory module = Module({
            moduleName: name,
            moduleType: moduleType,
            moduleTypeString: IAGEMetadata(_getFullAGEContract().getGameServerMetadata()).getModuleTypeString(moduleType),
            moduleDeployedAddress: contractAddress
        });

        _modules[hash] = module;
        _moduleList.push(hash);
        
        emit DeployModule(msg.sender, address(this), contractAddress, name, moduleId);
    }

    // Remove a module
    function removeModule(string memory moduleName, uint256 moduleId) external  onlyOwner {
        IModuleType.ModuleType moduleType = IModuleType.ModuleType(moduleId);
        bytes32 hash = _getModuleHash(moduleName, moduleType);
        require(_isModuleInstalled(hash), "Modules: Module not installed");

        try IAGEModule(_modules[hash].moduleDeployedAddress).dissociateAndCleanUpServerContract() {
            // якщо виклик пройшов успішно
        } catch (bytes memory) {
	    }
        _modules[hash] = Module("", IModuleType.ModuleType.Voting, "", address(0));
        for (uint i = 0; i < _moduleList.length; i++) {
            if (_moduleList[i] == hash) {
                _moduleList[i] = _moduleList[_moduleList.length - 1];
                _moduleList.pop();
                return;
            }
        }
    }
    
    // Get a module
    function getModuleAddress(string memory name, uint256 moduleId) external view returns (address) {
        return _getModuleAddress(name, moduleId);
    }
    function _getModuleAddress(string memory name, uint256 moduleId) internal view returns (address) {
        bytes32 hash = _getModuleHash(name, IModuleType.ModuleType(moduleId));
        Module memory module = _modules[hash];
        return module.moduleDeployedAddress;
    }

    // Check if a module Installed
    function isModuleInstalled(string memory name, uint256 moduleId) external view returns (bool) {
        bytes32 hash = _getModuleHash(name, IModuleType.ModuleType(moduleId));
        return _isModuleInstalled(hash);
    }
    function _isModuleInstalled(bytes32 hash) internal view returns (bool) {
       return bytes(_modules[hash].moduleName).length != 0;
    }

    // Get a hsah 
    function _getModuleHash(string memory name, IModuleType.ModuleType moduleType) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(name, uint256(moduleType)));
    }

}

