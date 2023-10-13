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
import "../../common/FinanceManager.sol";
import "../../interfaces/IServer.sol";
import "../../interfaces/IFactory.sol";
import "../../openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";


contract ServerUpvote is IAGEModule {

    string private constant moduleName = "ServerUpvote";
    ModuleType private constant moduleType = ModuleType.Voting;
    string private constant moduleTypeString = "Voting";

    /**
     * @dev Emitted when the server contract is removed and address approvals are toggled.
     * @param serverContractAddress Address of the server contract.
     * @param voter Address of the voter.
     * @param numberOfvotes The number of votes cast for the server.
     */
    event ServerContractRemoved(address indexed serverContractAddress, address indexed voter, uint256 numberOfvotes);

    constructor() {}

    function getServerContract() external view override returns (address) {}
    
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
    
    function getModuleFactory() external view override returns (address) {}
    
    function dissociateAndCleanUpServerContract() external override {}
}