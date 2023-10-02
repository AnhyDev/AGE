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

// @filepath Repository Location: [solidity/modules/Shop/SalesModule/SalesProcessing.sol]

pragma solidity ^0.8.19;

import "./ServiceManagement.sol";

/**
 * @title SalesProcessing Contract
 * @dev This contract is responsible for handling services' sales, allowing users to purchase services using either Ether or ERC20 tokens.
 * It extends functionalities from ServiceManagement.
 */
abstract contract SalesProcessing is ServiceManagement {

    /**
     * @dev Returns the list of services by ID.
     * @param serviceId The ID of the services.
     * @return An array of services corresponding to the serviceId.
     */
    function getServicesById(uint256 serviceId) public view returns (Service[] memory) {
        return services[serviceId];
    }

    /**
     * @dev Fetches a service based on the serviceId and serviceName.
     * @param serviceId The ID of the service.
     * @param serviceName The name of the service.
     * @return A Service struct representing the found service.
     */
    function getServiceByIdAndName(uint256 serviceId, string memory serviceName) public view returns (Service memory) {
        return _getServiceByNameAndType(serviceId, serviceName);
    }

    /**
     * @dev Allows users to buy a service with Ether.
     * @param serviceId The ID of the service.
     * @param serviceName The name of the service.
     * @notice The function reverts if the service is not sold for Ether.
     */
    function buyService(uint256 serviceId, string memory serviceName) public payable validServiceId(serviceId) {
        _checkBuyServiceId(serviceId, false);
        Service memory service = _getServiceByNameAndType(serviceId, serviceName);
        require(service.price.tokenAddress == address(0), "This service is sold for tokens");
        _buyService(service, serviceId);
    }

    /**
     * @dev Allows users to buy a service with tokens.
     * @param serviceId The ID of the service.
     * @param serviceName The name of the service.
     */
    function buyServiceWithTokens(uint256 serviceId, string memory serviceName) public validServiceId(serviceId) {
        _checkBuyServiceId(serviceId, false);
        Service memory service = _getServiceByNameAndType(serviceId, serviceName);
        _buyService(service, serviceId);
    }
    
    /** 
     * @dev Enables users to buy listed NFT services with Ether.
     * @param serviceName The name of the service.
     */
    function buyListedNFT(string memory serviceName) public payable {
        _buyListedNFT(serviceName);
    }
    
    /**
     * @dev Enables users to buy listed NFT services with tokens.
     * @param serviceName The name of the service.
     */
    function buyListedNFTWithTokens(string memory serviceName) public {
        _buyListedNFT(serviceName);
    }
    
    /**
     * @dev Allows users to purchase listed ERC20 services with Ether.
     * @param serviceName The name of the ERC20 service.
     */
    function buyListedERC20(string memory serviceName) public payable {
        _buyListedERC20(serviceName);
    }

    /**
     * @dev Allows users to purchase listed ERC20 services with tokens.
     * @param serviceName The name of the ERC20 service.
     */
    function buyListedERC20WithTokens(string memory serviceName) public {
        _buyListedERC20(serviceName);
    }

    /**
     * @dev Provides a way to get the service type name by the service ID.
     * @param serviceId The ID of the service type.
     * @return A string representing the name of the service type.
     */
    function getServiceTypeNameById(uint256 serviceId) public pure returns (string memory) {
        string[6] memory serviceTypeNames = [
            "Permanent",
            "OneTime",
            "TimeBased",
            "NFT",
            "ERC20",
            "END_OF_LIST"
        ];
    
        if(serviceId >= uint(ServiceType.END_OF_LIST)) {
            return "Invalid serviceId: Such type does not exist";
        }
    
        return serviceTypeNames[serviceId];
    }

    /**
     * @dev Internal function that validates the provided serviceId depending.
     * @param serviceId The ID of the service to be checked.
     * @param isTokens A boolean value.
     * - If isTokens is false:
     * - It checks whether the serviceId is valid and less than ServiceType.NFT. If not, it reverts with a message indicating that such a service type does not exist for purchases made without tokens.
     * - If isTokens is true:
     * - It checks whether the serviceId is valid, greater than or equal to ServiceType.NFT, and less than ServiceType.END_OF_LIST. If not, it reverts with a message indicating that such a service type does not exist for purchases made with tokens.
     * This function ensures that only valid service IDs are processed, providing an additional layer of security and data integrity for service purchases.
      */
    function _checkBuyServiceId(uint256 serviceId, bool isTokens) private pure {
        if (!isTokens) {
            if(serviceId >= uint(ServiceType.NFT)) {
                revert("Invalid serviceId: Such type does not exist");
            }
        } else {
            if(serviceId >= uint(ServiceType.END_OF_LIST) || serviceId < uint(ServiceType.NFT)) {
                revert("Invalid serviceId: Such type does not exist");
            }
        }
    }
}

