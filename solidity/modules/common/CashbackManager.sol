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
 
// @filepath Repository Location: [solidity/modules/CashbackManager.sol]

pragma solidity ^0.8.19;

import "../../openzeppelin/contracts/access/Ownable.sol";
import "../../interfaces/IServer.sol";
import "../../interfaces/IFactory.sol";
import "../../interfaces/IModuleCashback.sol";

/**
 * @title CashbackManager
 * @dev This abstract contract manages the retrieval and issuance of cashback tokens
 * in collaboration with an IServer contract. The contract can track the existence of services,
 * obtain cashback details for a specific module, and issue cashback tokens to recipients. 
 * Derived contracts should specify the cashback issuance logic for their specific use case.
 */
abstract contract CashbackManager is Ownable {

    // @notice IServer contract to interact with.
    IServer internal _serverContract;

    address internal _moduleFactory;

    mapping(bytes32 => string) internal _cashbacks;
    bytes32[] internal _cashbackList;

    /**
     * @dev Emitted when cashback is successfully issued.
     * @param cashbackName The unique identifier (bytes32) for the cashback.
     * @param cashbackAddress The contract address issuing the cashback.
     * @param amount The amount of cashback issued.
     * @param recipient The address receiving the cashback.
     */
    event CashbackIssued(bytes32 indexed cashbackName, address indexed cashbackAddress, uint256 amount, address indexed recipient);

    constructor(address serverContract_, address factoryContractAddress) {
        _serverContract = IServer(serverContract_);
        _moduleFactory = factoryContractAddress;
    }

    /**
     * @dev Retrieves the cashback details for this module using a given key.
     * If the service associated with the key doesn't exist or the cashback address is not set, it returns a zero amount.
     * @param cashbackName The key representing a service to use for retrieving the cashback value and address.
     * @return ICashback The ICashback interface of the cashback contract.
     * @return uint256 The amount of cashback, returns 0 if service doesn't exist or cashback address is not set.
     */
    function getCashbackForThisModule(string memory cashbackName) external view returns (IModuleCashback, uint256) {
        bytes32 hash = keccak256(abi.encodePacked(cashbackName));
        (address cashbackAddress, uint256 cashbackAmount) = _getCashback(hash);
        if (cashbackAddress == address(0)) {
            cashbackAmount = 0;
        }
        return (IModuleCashback(cashbackAddress), cashbackAmount);
    }

	/**
	 * @dev Retrieves the full list of cashbacks available in this manager.
	 * @return An array of strings representing the available cashbacks.
	 */
	function getCashbacks() public view returns (string[] memory) {
	    string[] memory cashbackValues = new string[](_cashbackList.length);
	    
	    for (uint i = 0; i < _cashbackList.length; i++) {
	        cashbackValues[i] = _cashbacks[_cashbackList[i]];
	    }

	    return cashbackValues;
	}

	/**
	 * @dev Checks if a given cashback hash is present in the manager.
	 * @param hash The hash to be checked.
	 * @return A boolean indicating the presence of the cashback.
	 */
	function isCashbackPresent(bytes32 hash) external view returns (bool) {
	    return _isCashbackPresent(hash);
	}

	/**
	 * @dev Retrieves the cashback details from the server contract using a given source.
	 * @param source The hash key representing a service.
	 * @return address The contract address responsible for the cashback.
	 * @return uint256 The amount of the cashback to be given.
	 */
    function _getCashback(bytes32 source) internal view returns (address, uint256) {
        return _serverContract.getCashback(source);
    }

	/**
	 * @dev Provides cashback to the recipient using the details associated with a given source.
	 * If valid details are present, it triggers the issuance of cashback tokens to the recipient.
	 * @param recipient The address intended to receive the cashback.
	 * @param source The hash key representing a service to retrieve cashback details.
	 */
    function _giveCashback(address recipient, bytes32 source) internal {
        (address cashbackAddress, uint256 cashbackAmount) = _getCashback(source);
        if (cashbackAddress != address(0) && cashbackAmount > 0) {
            IModuleCashback cashbackModule = IModuleCashback(cashbackAddress);
            cashbackModule.issueTokens(recipient, source);
            
            emit CashbackIssued(source, cashbackAddress, cashbackAmount, recipient);
        }
    }

	/**
	 * @dev Checks internally if a given cashback hash exists.
	 * @param hash The hash to be checked.
	 * @return A boolean indicating the presence of the cashback.
	 */
	function _isCashbackPresent(bytes32 hash) internal view returns (bool) {
	    return bytes(_cashbacks[hash]).length != 0;
	}
	
	/**
	 * @dev Adds a new cashback to the manager using the provided name.
	 * It ensures the cashback doesn't already exist before adding.
	 * @param cashbackName The name of the new cashback to be added.
	 * @return A bytes32 hash representing the added cashback.
	 */
	function _addCashback(string memory cashbackName) internal returns (bytes32) {
	    bytes32 hash = keccak256(abi.encodePacked(cashbackName));
	    
	    require(!_isCashbackPresent(hash), "CashbackManager: Cashback already exists");

	    _cashbacks[hash] = cashbackName;
	    _cashbackList.push(hash);
        return hash;
	}

	/**
	 * @dev Removes a cashback from the manager using a given hash.
	 * It ensures the cashback exists before removing.
	 * @param hash The hash representing the cashback to be removed.
	 */
	function _removeCashback(bytes32 hash) internal {
	    
	    require(_isCashbackPresent(hash), "CashbackManager: Cashback does not exist");

	    // Remove from mapping
	    delete _cashbacks[hash];

	    // Remove from array
	    for (uint256 i = 0; i < _cashbackList.length; i++) {
	        if (_cashbackList[i] == hash) {
	            _cashbackList[i] = _cashbackList[_cashbackList.length - 1];
	            _cashbackList.pop();
	            break;
	        }
	    }
	}
}
