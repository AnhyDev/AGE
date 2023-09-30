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

import "../../../openzeppelin/contracts/interfaces/IERC20.sol";
import "../../../openzeppelin/contracts/interfaces/IERC721.sol";
import "../../../common/CashbackManager.sol";

/**
 * @title UtilitySales
 * @dev This contract represents a marketplace where different types of services can be listed and purchased.
 * The contract handles the listing, pricing, and purchasing of services, and includes features for handling ERC20 tokens and NFTs.
 */
abstract contract ServiceManager is CashbackManager {

    /**
     * @dev Enum representing the various types of services that can be listed and purchased in the contract.
     */
    enum ServiceType {
        Permanent,
        OneTime,
        TimeBased,
        NFT,
        ERC20,
        END_OF_LIST // Marker indicating the end of the enum list.
    }

    /**
     * @dev Struct defining the price of a service in terms of a token address and an amount.
     */
    struct Price {
        address tokenAddress;
        uint256 amount;
    }

    /**
     * @dev Struct defining the properties of a service including its name, price, timestamp, duration, tokenAddress, and number.
     */
    struct Service {
        bytes32 hash;
        string name;
        Price price;
        uint256 timestamp;
        uint256 duration;
        address tokenAddress;
        uint256 number;
    }

    // Mapping from a serviceId to an array of Service structs representing the services listed under that id.
    mapping(uint256 => Service[]) internal services;

    // Mapping from a user address to a mapping from a serviceId to an array of Service structs representing the services purchased by that user under that id.
    mapping(address => mapping(uint256 => Service[])) public userPurchasedServices;

    /**
     * @dev Emitted when a service is purchased.
     * @param purchaser The address of the user who purchased the service.
     * @param serviceType The type of the purchased service.
     */
    event ServicePurchased(address indexed purchaser, ServiceType serviceType);
    
    /**
     * @dev Modifier to check whether the provided serviceId is valid.
     */
    modifier validServiceId(uint256 serviceId) {
        require(serviceId < uint(ServiceType.END_OF_LIST), "Invalid service type");
        _;
    }

    /**
     * @dev Internal function to retrieve a service by its name and type (serviceId).
     * @param serviceId The ID representing the type of the service.
     * @param serviceName The name of the service.
     * @return The Service struct representing the found service.
     */
    function _getServiceByNameAndType(uint256 serviceId, string memory serviceName) internal view returns (Service memory) {
        bytes32 serviceNameHash = keccak256(abi.encodePacked(serviceName));
        Service[] memory serviceArray = services[serviceId];
        for(uint i = 0; i < serviceArray.length; i++) {
            if(serviceArray[i].hash == serviceNameHash) {
                return serviceArray[i];
            }
        }
        revert("Service not found");
    }
    
    /**
     * @dev Internal function to handle the purchase of a service, managing the payment and triggering the appropriate events and effects.
     * @param service The Service struct representing the service to be purchased.
     * @param serviceId The ID representing the type of the service to be purchased.
     */
    function _buyService(Service memory service, uint256 serviceId) internal validServiceId(serviceId) {
        uint256 paymentAmount = service.price.amount;
        address paymentToken = service.price.tokenAddress;
        if(paymentToken == address(0)) {
            // If paying with ether
            require(msg.value == paymentAmount, "The amount of ether sent does not match the required amount.");
        } else {
            // If paying with tokens
            IERC20 token = IERC20(paymentToken);
            require(token.balanceOf(msg.sender) >= paymentAmount, "Your token balance is not enough.");
            require(token.allowance(msg.sender, address(_serverContract)) >= paymentAmount, "The contract does not permit the transfer of tokens on behalf of the user.");
            token.transferFrom(msg.sender, address(_serverContract), paymentAmount);
        }

        _purchaseService(msg.sender, service, serviceId);
    }

    /**
     * @dev Internal function to facilitate the purchasing of services listed as ERC20.
     * @param serviceName The name of the service.
     */
    function _buyListedERC20(string memory serviceName) internal {
        uint256 serviceId = uint(ServiceType.ERC20);
        Service memory service = _getServiceByNameAndType(serviceId, serviceName);
        uint256 amount = service.number;
        IERC20 erc20Token = IERC20(service.tokenAddress);
        require(erc20Token.balanceOf(address(this)) >= amount, "Not enough tokens in contract balance");

        _buyService(service, serviceId);
        erc20Token.transfer(msg.sender, amount);
    }
    
    /**
     * @dev Internal function to facilitate the purchasing of services listed as NFT.
     * @param serviceName The name of the service.
     */
    function _buyListedNFT(string memory serviceName) internal {
        uint256 serviceId = uint(ServiceType.NFT);
        Service memory service = _getServiceByNameAndType(serviceId, serviceName);
        uint256 idNft = service.number;
        IERC721 token = _listedNFT(idNft, service);

        _buyService(service, serviceId);
        token.safeTransferFrom(address(this), msg.sender, idNft);
        
        _removeServiceFromList(serviceId, serviceName);
    }
    
    /**
     * @dev Private helper function to ensure the listed NFT is available and valid for purchase.
     * @param idNft The ID of the NFT.
     * @param service The Service struct representing the service to be purchased.
     * @return returnedToken The IERC721 token representing the NFT.
     */
    function _listedNFT(uint256 idNft, Service memory service) private view returns (IERC721 returnedToken) {
        address tokenAddress = service.tokenAddress;
        require(service.price.tokenAddress != address(0), "This service is sold for tokens");
        require(tokenAddress != address(0), "This service has no NFTs for sale");
        require(service.number == idNft, "NFT with such id is not for sale");
        IERC721 tokenInstance = IERC721(tokenAddress);
        require(tokenInstance.ownerOf(idNft) == address(this), "Token is not owned by this contract");
        return tokenInstance;
    }

    /**
     * @dev Private function to handle the logic after a service has been successfully purchased.
     * @param sender The address of the user purchasing the service.
     * @param service The Service struct representing the purchased service.
     * @param serviceId The ID representing the type of the purchased service.
     */
    function _purchaseService(address sender, Service memory service, uint256 serviceId) private {
        userPurchasedServices[sender][serviceId].push(service);

        _giveCashback(sender, service.hash);
        
        emit ServicePurchased(sender, ServiceType(serviceId));
    }

    /**
     * @dev Internal virtual function to remove a service from the listing once it has been purchased.
     * This function is meant to be overridden in derived contracts to implement specific removal logic.
     * @param serviceId The ID representing the type of the purchased service.
     * @param serviceName The name of the service.
     */
    function _removeServiceFromList(uint256 serviceId, string memory serviceName) internal virtual;
}
