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

// @filepath Repository Location: [solidity/global/metadata/ModuleTypeData.sol]

pragma solidity ^0.8.19;

import "../../interfaces/IModuleType.sol";

abstract contract ModuleTypeData is IModuleType {

    // Internal utility function to get string representation of a ModuleType enum.
    function getModuleTypeString(ModuleType moduleType) external pure returns (string memory) {
        if (moduleType == ModuleType.Server) {
            return "Server";
        } else if (moduleType == ModuleType.Cashback) {
            return "Cashback";
        } else if (moduleType == ModuleType.Token) {
            return "Token";
        } else if (moduleType == ModuleType.NFT) {
            return "NFT";
        } else if (moduleType == ModuleType.Shop) {
            return "Shop";
        } else if (moduleType == ModuleType.Exchange) {
            return "Exchange";
        } else if (moduleType == ModuleType.Auction) {
            return "Auction";
        } else if (moduleType == ModuleType.Advertisement) {
            return "Advertisement";
        } else if (moduleType == ModuleType.SocialFunctions) {
            return "SocialFunctions";
        } else if (moduleType == ModuleType.AffiliateProgram) {
            return "AffiliateProgram";
        } else if (moduleType == ModuleType.Event) {
            return "Event";
        } else if (moduleType == ModuleType.Game) {
            return "Game";
        } else if (moduleType == ModuleType.Lottery) {
            return "Lottery";
        } else if (moduleType == ModuleType.Raffle) {
            return "Raffle";
        } else if (moduleType == ModuleType.Voting) {
            return "Voting";
        } else if (moduleType == ModuleType.RatingSystem) {
            return "RatingSystem";
        } else if (moduleType == ModuleType.Charity) {
            return "Charity";
        } else {
            return "Unknown";
        }
    }
}
