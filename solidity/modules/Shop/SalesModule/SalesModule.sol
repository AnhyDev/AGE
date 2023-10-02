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

// @filepath Repository Location: [solidity/modules/Shop/SalesModule/SalesModule.sol]

pragma solidity ^0.8.19;

import "../../../interfaces/IAGEModule.sol";
import "../../../openzeppelin/contracts/interfaces/IERC165.sol";
import "./SalesProcessing.sol";
import "../../../common/FinanceManager.sol";
import "../../../common/ERC20Receiver.sol";
import "../../../interfaces/IFactory.sol";
import "../../../interfaces/IServer.sol";

/**
 * @title SalesModule Contract
 * @dev This contract handles various sales functionalities.
 */
contract SalesModule is IAGEModule, IERC165, SalesProcessing, FinanceManager, ERC20Receiver {

    string private constant moduleName = "SalesModule";
    ModuleType private constant moduleType = ModuleType.Shop;
    string private constant moduleTypeString = "Shop";

    constructor(address serverContract_, address factoryContractAddress, address sender)
        CashbackManager(serverContract_, factoryContractAddress)
            Ownable(sender) {

        erc1820Registry.setInterfaceImplementer(address(this), keccak256("IAGEModule"), address(this));
    }

    /**
     * @notice This function allows external entities to retrieve the address of the server contract
     * @return The address of the server contract
     */
    function getServerContract() external view override returns (address) {
        return address(_serverContract);
    }

    /**
     * @dev Get the name of the module.
     * @return A string representing the name of the module.
     */
    function getModuleName() external pure override returns (string memory) {
        return moduleName;
    }

    /**
     * @dev Get the type of the module as an enum value.
     * @return A ModuleType enum value representing the type of the module.
     */
    function getModuleType() external pure override returns (ModuleType) {
        return moduleType;
    }

    /**
     * @dev Get the type of the module as a string.
     * @return A string representing the type of the module.
     */
    function getModuleTypeString() external pure override returns (string memory) {
        return moduleTypeString;
    }

    /**
     * @dev Retrieves the address of the factory contract that deployed this contract.
     * This function provides transparency and traceability by allowing users to verify
     * the origin of this contract, enabling them to ensure it was deployed by a legitimate
     * and trusted factory contract.
     * @return The address of the factory contract that deployed this contract.
     */
    function getModuleFactory() external view override returns (address) {
        return moduleFactory;
    }

    /**
     * @dev Performs cleanup and dissociation actions between this contract and the associated server contract.
     * 
     * This method achieves the following:
     * 1. Iterates through all the cashback modules linked to the server contract.
     * 2. For each cashback module, if this contract is approved, it revokes the approval.
     * 3. Deletes the reference to the server contract from this contract.
     * 4. Calls the factory contract to remove the association between the factory and the server contract.
     * 5. Emits a ServerContractRemoved event, specifying the address of the removed server contract and the number of modifications made.
     * 
     * Requirements:
     * - The caller must be the server contract that is associated with this contract.
     * 
     * Emits:
     * - A `ServerContractRemoved` event upon successful execution.
     */
    function dissociateAndCleanUpServerContract() external override {
        require(msg.sender == address(_serverContract), "SalesModule: Only the server contract can call this function");
        
        IServer.StructCashback[] memory cashbacks = _serverContract.getAllCashbacks();
        uint256 modifications = 0;
        for (uint256 i = 0; i < cashbacks.length; i++) {
            IModuleCashback cashbackModule = IModuleCashback(cashbacks[i].contractCashbackAddress);
            if (cashbackModule.isAddressApproved(address(this))) {
                cashbackModule.toggleAddressApproval(address(this), false);
                modifications++;
            }
        }
        IFactory(moduleFactory).removeModule(address(_serverContract));
        emit ServerContractRemoved(address(_serverContract), modifications);
        delete _serverContract;
    }
    
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override(IERC165, ERC20Receiver) returns (bool) {
        return interfaceId == type(IAGEModule).interfaceId ||
            ERC20Receiver.supportsInterface(interfaceId);
    }
}
