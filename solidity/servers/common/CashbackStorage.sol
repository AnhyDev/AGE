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
 
// @filepath Repository Location: [solidity/servers/common/CashbackStorage.sol]

pragma solidity ^0.8.19;

import "../../openzeppelin/contracts/interfaces/IERC165.sol";
import "../../openzeppelin/contracts/access/Ownable.sol";
import "../../interfaces/IModuleCashback.sol";

/**
 * @title CashbackStorage Contract
 * @dev This contract allows the owner to manage cashback entries,
 * each identified by a name and linked to a contract address and a price.
 * It also provides utility functions to verify and retrieve cashback information.
 */
abstract contract CashbackStorage is Ownable {

    /** 
     * @dev Struct to represent individual Cashback entry with its properties
     */
    struct StructCashback {
        string name;  // Name of the cashback entry
        address contractCashbackAddress;  // Associated contract address
        uint256 price;  // Price linked with the cashback entry
    }
    
    // Mapping to store cashback entries
    mapping(bytes32 => StructCashback) internal _cashback;
    
    // Array to store keys of cashback entries
    bytes32[] internal _cashbackList;

    /**
     * @dev Allows owner to create or update a cashback entry.
     * @param name Name of the cashback entry.
     * @param contractCashbackAddress Address of the linked contract.
     * @param price Price associated with the cashback entry.
     */
    function upsertCashback(string memory name, address contractCashbackAddress, uint256 price) external onlyOwner {
        require(_supportsICashback(contractCashbackAddress), "CashbackStorage: Address does not comply with IModuleCashback interface");
        bytes32 key = keccak256(abi.encodePacked(name));
        
        if (_cashback[key].contractCashbackAddress != address(0)) {
            _cashbackList.push(key);
        }
        
        // додати автоматичне встановлення дозволу модулю отримувати кешбек у контракті кешбеку
        
        StructCashback storage cb = _cashback[key];
        cb.name = name;
        cb.contractCashbackAddress = contractCashbackAddress;
        cb.price = price;
    }

    /**
     * @dev Allows owner to delete a cashback entry.
     * @param key The key associated with the cashback entry to be deleted.
     */
    function deleteCashback(bytes32 key) external {
        require(_cashback[key].contractCashbackAddress != address(0), "CashbackStorage: Key does not exist.");

        if (msg.sender == owner() || (msg.sender == _cashback[key].contractCashbackAddress)) {
            delete _cashback[key];
        
            for (uint256 i = 0; i < _cashbackList.length; i++) {
                if (_cashbackList[i] == key) {
                    _cashbackList[i] = _cashbackList[_cashbackList.length - 1];
                    _cashbackList.pop();
                    break;
                }
            }
        } else {
            revert("CashbackStorage: Caller does not have permission to delete this cashback");
        }
    }

    /**
     * @dev Function to retrieve a cashback entry by name.
     * @param name Name of the cashback entry.
     * @return Address of the linked contract and the associated price.
     */
    function getCashback(string memory name) external view returns (address, uint256) {
        return _getCashback(keccak256(abi.encodePacked(name)));
    }

    /**
     * @dev Function to retrieve a cashback entry by key.
     * @param source The key associated with the cashback entry.
     * @return Address of the linked contract and the associated price.
     */
    function getCashback(bytes32 source) external view returns (address, uint256) {
        return _getCashback(source);
    }

    /**
     * @dev Internal function to retrieve a cashback entry by key.
     * @param source The key associated with the cashback entry.
     * @return Address of the linked contract and the associated price.
     */
    function _getCashback(bytes32 source) internal view returns (address, uint256) {
        return (_cashback[source].contractCashbackAddress, _cashback[source].price);
    }

    /**
     * @dev Function to retrieve all the cashback entries.
     * @return An array of StructCashback representing all cashback entries.
     */
    function getAllCashbacks() external view returns (StructCashback[] memory) {
        uint256 length = _cashbackList.length;
        StructCashback[] memory cashbacksList = new StructCashback[](length);
        
        for (uint256 i = 0; i < length; i++) {
            bytes32 key = _cashbackList[i];
            cashbacksList[i] = _cashback[key];
        }
        
        return cashbacksList;
    }

    /**
     * @dev Utility function to verify if an address supports ICashback interface.
     * @param contractAddress Address to be verified.
     * @return Returns true if the address supports ICashback interface, otherwise false.
     */
    function _supportsICashback(address contractAddress) internal view returns (bool) {
        return IERC165(contractAddress).supportsInterface(type(IModuleCashback).interfaceId);
    }
}
