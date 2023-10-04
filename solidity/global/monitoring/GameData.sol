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

// @filepath Repository Location: [solidity/global/monitoring/GameData.sol]

pragma solidity ^0.8.19;


import "../../interfaces/IAGEMetadata.sol";
import "../common/Ownable.sol";

/**
 * @title GameData
 * @dev This contract serves as the game data management layer.
 * It extends Ownable for basic authorization control and interfaces
 * with a proxy contract to retrieve game-related data.
 */
abstract contract GameData is Ownable {

    /**
     * @dev A constant that represents a sentinel value indicating the end of the list of games.
     * This can be used to mark the last element in a linked list or similar data structures.
     */
    uint256 internal constant END_OF_LIST = 1000;

    /**
     * @dev Internal function to get the interface of the Game Server Metadata contract.
     * @return An instance of IGameData interface.
     */
    function _getGameServerMetadata() internal view returns (IAGEMetadata) {
        return IAGEMetadata(_getFullAGEContract().getGameServerMetadata());
    }

    /**
     * @dev Internal function to check if the game ID is not empty.
     * @param gameId The ID of the game to check.
     * @return True if the game ID exists, false otherwise.
     */
    function _checkGameIdNotEmpty(uint256 gameId) internal view returns (bool) {
        return _getGameServerMetadata().checkGameIdNotEmpty(gameId) != END_OF_LIST;
    }

    /**
     * @dev Private function to actually retrieve the server data of a game.
     * @param gameId The ID of the game.
     * @return name The name of the game server.
     * @return symbol The symbol of the game server.
     */
    function _getServerData(uint256 gameId) private view returns (string memory, string memory) {
        string memory name = "Anhydrite server module ";
        string memory symbol = "AGE_";
        if (address(_getGameServerMetadata()) != address(0)) {
            (name, symbol) = _getGameServerMetadata().getServerData(gameId);
        }
        return (name, symbol);
    }
}

