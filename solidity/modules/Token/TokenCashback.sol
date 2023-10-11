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

// @filepath Repository Location: [solidity/modules/Token/TokenCashback.sol]

pragma solidity ^0.8.19;

import "../../interfaces/IAGEModule.sol";
import "../../common/BaseAnh.sol";
import "../../common/ModuleCashbackTokens.sol";
import "../../common/FinanceManager.sol";
import "../../interfaces/IServer.sol";
import "../../interfaces/IFactory.sol";
import "../../openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";


contract TokenCashback is IAGEModule, BaseAnh, FinanceManager, ModuleCashbackTokens {

    string private constant moduleName = "TokenCashback";
    ModuleType private constant moduleType = ModuleType.Token;
    string private constant moduleTypeString = "Token";

    /**
     * @dev Emitted when the server contract is removed and address approvals are toggled.
     * @param serverContractAddress Address of the removed server contract.
     * @param numberOfModifications Number of address approvals that were toggled due to the removal of the server contract.
     * @param numberRemoveCashbacs Number of cashbacks removed.
     */
    event ServerContractRemoved(address indexed serverContractAddress, uint256 numberOfModifications, uint256 numberRemoveCashbacs);
   
    constructor(string memory name_, string memory symbol_, address serverAddress, address factoryContractAddress, address sender)
        ModuleCashbackTokens(serverAddress, factoryContractAddress)
            ERC20ReceiverToken(string(abi.encodePacked(name_, " TokenCashback")),
                string(abi.encodePacked(symbol_, "TC")))
                    Ownable(sender) {
        
        erc1820Registry.setInterfaceImplementer(address(this), keccak256("IAGEModule"), address(this));

        _mint(owner(), 365 * 10 ** decimals());
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
     * @dev Implements the _giveTokens function to mint tokens to the specified recipient.
     * @param recipient The recipient of the tokens.
     * @param amount The amount of tokens to mint.
     */
    function _giveTokens(address recipient, uint256 amount) internal override virtual {
        _mint(recipient, amount);
    }
    
    /**
     * @dev Implements a whitelist check for handling trusted contracts with specific logic.
     * @param checked The address to check against the whitelist.
     * @return bool True if the address is in the whitelist, false otherwise.
     */
    function _checkWhitelist(address checked) internal view override virtual returns (bool) {
        return ANHYDRITE.checkWhitelist(checked);
    }

    /**
     * @dev Dissociates this contract from its associated server contract and performs necessary cleanup.
     * This function is restricted to be invoked only by the associated server contract.
     *
     * It proceeds in the following steps:
     * 1. Iterates over all the modules linked to the server contract, revoking approvals if this contract is approved in any.
     * 2. Iterates over all the cashbacks in the server contract and deletes the ones associated with this contract's address.
     * 3. Removes this module from the associated factory contract.
     * 4. Deletes the reference to the server contract in this contract.
     *
     * Events:
     * - Emits a ServerContractRemoved event detailing the address of the server contract and counts of modifications and deletions performed.
     *
     * Requirements:
     * - The caller must be the associated server contract.
     */
    function dissociateAndCleanUpServerContract() external override {
        require(msg.sender == address(_serverContract), "TokenCashback: Only the server contract can call this function");
        
        address[] memory modules = _serverContract.getModuleAddresses();
        uint256 modifications = 0;
        for (uint256 i = 0; i < modules.length; i++) {
            address module = modules[i];
            if (_approvedTokenRequestAddresses[module]) {
                _approvedTokenRequestAddresses[module] = false;
                modifications++;
            }
        }

        IServer.StructCashback[] memory cashbacks = _serverContract.getAllCashbacks();
        uint256 cashbacsDel = 0;
        uint256 allCashbacks = cashbacks.length;
        if (allCashbacks > 0) {
            for (uint256 i = 0; i < allCashbacks; i++) {
                address module = cashbacks[i].contractCashbackAddress;
                if (module == address(this)) {
                    _serverContract.deleteCashback(keccak256(abi.encodePacked(cashbacks[i].name)));
                    cashbacsDel++;
                }
            }
        }
        IFactory(moduleFactory).removeModule(address(_serverContract));
        emit ServerContractRemoved(address(_serverContract), modifications, cashbacsDel);
        delete _serverContract;
    }
    
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ModuleCashbackTokens) returns (bool) {
        return interfaceId == type(IAGEModule).interfaceId ||
           ModuleCashbackTokens.supportsInterface(interfaceId) ||
           interfaceId == type(IERC721Receiver).interfaceId;
    }

}