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

import "./ServiceManager.sol";

/**
 * @title UtilityService
 * @dev This contract allows the owner to add and remove services.
 * It inherits from the UtilitySales contract.
 */
abstract contract ServiceManagement is ServiceManager {

    /**
     * @dev Allows the owner to add a Permanent Service payable with Ether.
     * @param serviceName Name of the service.
     * @param payAmount Amount to pay for the service.
     */
    function addServicePermanent(string memory serviceName, uint256 payAmount) public onlyOwner {
        uint256 serviceId = uint(ServiceType.Permanent);
        _addService(serviceId, serviceName, address(0), payAmount, 0, address(0), 0);
    }

    /**
     * @dev Allows the owner to add a Permanent Service payable with Tokens.
     * @param serviceName Name of the service.
     * @param payAmount Amount to pay for the service.
     */
    function addServicePermanentWithTokens(string memory serviceName, address payAddress, uint256 payAmount) public onlyOwner {
        uint256 serviceId = uint(ServiceType.Permanent);
        _addService(serviceId, serviceName, payAddress, payAmount, 0, address(0), 0);
    }

    /**
     * @dev Allows the owner to add a OneTime Service payable with Ether.
     * @param serviceName Name of the service.
     * @param payAmount Amount to pay for the service.
     */
    function addServiceOneTime(string memory serviceName, uint256 payAmount) public onlyOwner {
        uint256 serviceId = uint(ServiceType.OneTime);
        _addService(serviceId, serviceName, address(0), payAmount, 0, address(0), 0);
    }

    /**
     * @dev Allows the owner to add a OneTime Service payable with Tokens.
     * @param serviceName Name of the service.
     * @param payAmount Amount to pay for the service.
     */
    function addServiceOneTimeWithTokens(string memory serviceName, address payAddress, uint256 payAmount) public onlyOwner {
        uint256 serviceId = uint(ServiceType.OneTime);
        _addService(serviceId, serviceName, payAddress, payAmount, 0, address(0), 0);
    }

    /**
     * @dev Allows the owner to add a TimeBased Service payable with Ether.
     * @param serviceName Name of the service.
     * @param payAmount Amount to pay for the service.
     */
    function addServiceTimeBased(string memory serviceName, uint256 payAmount, uint256 duration) public onlyOwner {
        uint256 serviceId = uint(ServiceType.TimeBased);
        _addService(serviceId, serviceName, address(0), payAmount, duration, address(0), 0);
    }

    /**
     * @dev Allows the owner to add a TimeBased Service payable with Tokens.
     * @param serviceName Name of the service.
     * @param payAmount Amount to pay for the service.
     */
    function addServiceTimeBasedWithTokens(string memory serviceName, address payAddress, uint256 payAmount, uint256 duration) public onlyOwner {
        uint256 serviceId = uint(ServiceType.TimeBased);
        _addService(serviceId, serviceName, payAddress, payAmount, duration, address(0), 0);
    }

    /**
     * @dev Allows the owner to add a NFT Service payable with Ether.
     * @param serviceName Name of the service.
     * @param payAmount Amount to pay for the service.
     */
    function addServiceNFT(string memory serviceName, uint256 payAmount, address tokenAddress, uint256 number) public onlyOwner {
        uint256 serviceId = uint(ServiceType.NFT);
        _addService(serviceId, serviceName, address(0), payAmount, 0, tokenAddress, number);
    }

    /**
     * @dev Allows the owner to add a TimNFTeBased Service payable with Tokens.
     * @param serviceName Name of the service.
     * @param payAmount Amount to pay for the service.
     */
    function addServiceNFTWithTokens(string memory serviceName, address payAddress, uint256 payAmount, address tokenAddress, uint256 number) public onlyOwner {
        uint256 serviceId = uint(ServiceType.NFT);
        _addService(serviceId, serviceName, payAddress, payAmount, 0, tokenAddress, number);
    }

    /**
     * @dev Allows the owner to add a ERC20 Service payable with Ether.
     * @param serviceName Name of the service.
     * @param payAmount Amount to pay for the service.
     */
    function addServiceERC20(string memory serviceName, uint256 payAmount, address tokenAddress, uint256 number) public onlyOwner {
        uint256 serviceId = uint(ServiceType.ERC20);
        _addService(serviceId, serviceName, address(0), payAmount, 0, tokenAddress, number);
    }

    /**
     * @dev Allows the owner to add a ERC20 Service payable with Tokens.
     * @param serviceName Name of the service.
     * @param payAmount Amount to pay for the service.
     */
    function addServiceERC20WithTokens(string memory serviceName, address payAddress, uint256 payAmount, address tokenAddress, uint256 number) public onlyOwner {
        uint256 serviceId = uint(ServiceType.ERC20);
        _addService(serviceId, serviceName, payAddress, payAmount, 0, tokenAddress, number);
    }

    /**
     * @dev Removes the specified service from the list of services.
     * @param serviceId The ID of the service type.
     * @param serviceName Name of the service.
     */
    function removeServiceFromList(uint256 serviceId, string memory serviceName) public onlyOwner {
        _removeServiceFromList(serviceId, serviceName);
    }

    /**
     * @dev Internal function to add a service.
     * @param serviceId The ID of the service type.
     * @param moduleName Name of the module.
     * @param payAddress The address to pay to.
     * @param payAmount Amount to pay for the service.
     * @param duration The duration of the service.
     * @param tokenAddress The address of the token contract.
     * @param number The number of tokens.
     */
    function _addService(uint256 serviceId, string memory moduleName, address payAddress, uint256 payAmount, uint256 duration,
      address tokenAddress, uint256 number) private {
        bytes32 hash = keccak256(abi.encodePacked(moduleName));
        services[serviceId].push(Service({
            hash: hash,
            name: moduleName,
            price: Price({
                tokenAddress: payAddress,
                amount: payAmount
            }),
            timestamp: block.timestamp,
            duration: duration,
            tokenAddress: tokenAddress,
            number: number
        }));
        serviceExist[hash] = serviceId++;
    }

    /**
     * @dev Overridden internal function to remove a service from the list.
     * @param serviceId The ID of the service type.
     * @param serviceName Name of the service.
     */
    function _removeServiceFromList(uint256 serviceId, string memory serviceName) internal override {  
        bytes32 hash = keccak256(abi.encodePacked(serviceName));   
        // Find the service index and remove it
        for (uint256 i = 0; i < services[serviceId].length; i++) {
            if (keccak256(abi.encodePacked(services[serviceId][i].name)) == hash) {
                require(i < services[serviceId].length, "Index out of bounds");

                // Move the last element to the spot at index
                services[serviceId][i] = services[serviceId][services[serviceId].length - 1];
        
                // Remove the last element
                services[serviceId].pop();
                serviceExist[hash] = 0;
                break;
            }
        }
    }
}
