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

import "../openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IServer.sol";
import "../interfaces/IFactory.sol";
import "../interfaces/IModuleCashback.sol";

/**
 * @title ModuleCashback
 * @dev This abstract contract provides a template for implementing
 * module-specific cashback logic in collaboration with an IServer contract.
 */
abstract contract CashbackManager is Ownable {

    // @notice IServer contract to interact with.
    IServer internal _serverContract;

    address internal moduleFactory;

    mapping(bytes32 => uint256) internal serviceExist;

    /**
     * @dev Emitted when cashback is successfully issued.
     * @param cashbackName The unique identifier (bytes32) for the cashback.
     * @param cashbackAddress The contract address issuing the cashback.
     * @param amount The amount of cashback issued.
     * @param recipient The address receiving the cashback.
     */
    event CashbackIssued(bytes32 indexed cashbackName, address indexed cashbackAddress, uint256 amount, address indexed recipient);

    /**
     * @dev Emitted when the server contract is removed and address approvals are toggled.
     * @param serverContractAddress Address of the removed server contract.
     * @param numberOfModifications Number of address approvals that were toggled due to the removal of the server contract.
     */
    event ServerContractRemoved(address indexed serverContractAddress, uint256 numberOfModifications);

    constructor(address serverContract_, address factoryContractAddress) {
        _serverContract = IServer(serverContract_);
        moduleFactory = factoryContractAddress;
    }

    /**
     * @dev Retrieves the cashback details for this module using a given key.
     * If the service associated with the key doesn't exist or the cashback address is not set, it returns a zero amount.
     * @param key The key representing a service to use for retrieving the cashback value and address.
     * @return ICashback The ICashback interface of the cashback contract.
     * @return uint256 The amount of cashback, returns 0 if service doesn't exist or cashback address is not set.
     */
    function getCashbackForThisModule(string memory key) external view returns (IModuleCashback, uint256) {
        bytes32 hash = keccak256(abi.encodePacked(key));
        (address cashbackAddress, uint256 cashbackAmount) = _getCashback(hash);
        if (cashbackAddress == address(0) || serviceExist[hash] == 0) {
            cashbackAmount = 0;
        }
        return (IModuleCashback(cashbackAddress), cashbackAmount);
    }

    /**
     * @dev Internal function to get the cashback details from the server contract.
     * @param source The bytes32 key representing a service.
     * @return address The address of the cashback contract.
     * @return uint256 The amount of cashback.
     */
    function _getCashback(bytes32 source) internal view returns (address, uint256) {
        return _serverContract.getCashback(source);
    }

    /**
     * @dev Issues the cashback tokens to a recipient if the cashback details are valid and exist.
     * @param recipient The address of the recipient to receive the cashback tokens.
     * @param source The bytes32 key representing a service.
     */
    function _giveCashback(address recipient, bytes32 source) internal {
        (address cashbackAddress, uint256 cashbackAmount) = _getCashback(source);
        if (cashbackAddress != address(0) && cashbackAmount > 0) {
            IModuleCashback cashbackModule = IModuleCashback(cashbackAddress);
            cashbackModule.issueTokens(recipient, source);
            
            emit CashbackIssued(source, cashbackAddress, cashbackAmount, recipient);
        }
    }
}
