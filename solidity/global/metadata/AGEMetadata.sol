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

import "./ModuleTypeData.sol";
import "../common/FinanceManager.sol";
import "../../common/ERC20Receiver.sol";


/**
 * @title GameServerMetadata Contract
 * @dev This contract is responsible for storing metadata related to various gaming servers.
 * It inherits from the BaseUtil contract to utilize functions for proxy contract interactions.
 * 
 * Data Structure:
 * - _gamesData: A mapping from uint256-based game IDs to an array containing the game's name, contract name, and contract symbol.
 * - END_OF_LIST: A constant that represents the end of the games list.
 *
 * Functions:
 * - constructor: Initializes the _gamesData mapping with predefined gaming server data.
 * - getFullData: Returns the full array of a game's data based on its ID.
 * - getServerData: Returns the contract name and symbol of a game based on its ID.
 * - getGameName: Returns the name of a game based on its ID.
 * - addServerData: Allows the contract owner and/or the proxy contract owners to add new gaming server data.
 */
contract AGEMetadata is ModuleTypeData, FinanceManager, ERC20Receiver {

    // A constant that represents the end of the games list.
    uint256 public constant END_OF_LIST = 1000;
    bytes32 private constant STR_END_OF_LIST = keccak256(bytes("END_OF_LIST"));

    // A structure for storing the id and name of the game
    struct GameInfo {
        uint256 gameId;
        string gameName;
    }

    // A mapping from uint256-based game IDs to an array containing the game's name, contract name, and contract symbol.
    mapping(uint256 => string[]) internal _gamesData;


    constructor () {
        // Initializes the _gamesData mapping with predefined gaming server data.
        _gamesData[0] = [   "Minecraft",               "Anhydrite Minecraft server contract",              "AGEMC"  ];
        _gamesData[1] = [   "GTA",                     "Grand Theft Auto server contract",                 "AGEGTA" ];
        _gamesData[2] = [   "Terraria",                "Anhydrite Terraria server contract",               "AGETER" ];
        _gamesData[3] = [   "ARK Survival Evolved",    "Anhydrite ARK Survival Evolved server contract",   "AGESE"  ];
        _gamesData[4] = [   "Rust",                    "Anhydrite Rust server contract",                   "AGERST" ];
        _gamesData[5] = [   "Counter Strike",          "Counter-Strike server contract",                   "AGECS"  ];
        _gamesData[END_OF_LIST] = [ "END_OF_LIST",     "Anhydrite server module ",                         "AGESM"  ];
    }
    
    /**
     * @dev Returns the full data related to a game based on its ID.
     * @param gameId The ID of the game.
     * @return An array containing the game's name, contract name, and contract symbol.
     */
    function getFullData(uint256 gameId) external view returns (string[] memory) {
        return _gamesData[gameId];
    }

    /**
     * @dev Returns the contract name and symbol of a game based on its ID.
     * @param gameId The ID of the game.
     * @return The contract name and symbol of the game.
     */
    function getServerData(uint256 gameId) external view returns (string memory, string memory) {
        if (_gamesData[gameId].length == 0) {
            gameId = END_OF_LIST;
        }
        return (_gamesData[gameId][1], _gamesData[gameId][2]);
    }

    /**
     * @dev Returns the name of a game based on its ID.
     * @param gameId The ID of the game.
     * @return The name of the game.
     */
    function getGameName(uint256 gameId) external view returns (string memory) {
        if (_gamesData[gameId].length == 0) {
            gameId = END_OF_LIST;
        }
        return _gamesData[gameId][0];
    }

    /**
     * @dev Adds new server data. Can only be called by the contract owner or proxy contract owners.
     * @param gameId The ID of the game.
     * @param gameName The name of the game.
     * @param contractName The name of the contract related to the game.
     * @param contractSymbol The symbol of the contract related to the game.
     */
    function addServerData(uint256 gameId, string memory gameName, string memory contractName, string memory contractSymbol) public onlyOwner {
        require(gameId < END_OF_LIST, "GameServerMetadata: gameId must be less than 1000");
        if (_gamesData[gameId].length == 0) {
            _gamesData[gameId].push(gameName);
            _gamesData[gameId].push(contractName);
            _gamesData[gameId].push(contractSymbol);
        } else {
            revert("GameServerMetadata: It is not possible to change the existing position");
        }
    }

    /**
     * @dev Function to retrieve non-empty game data from the _gamesData mapping.
     * @return An array of GameInfo structures containing the id and name of the game for non-empty entries.
     */
    function getAllGames() external view returns (GameInfo[] memory) {
        // We initialize a dynamic array for storing results
        GameInfo[] memory nonEmptyGames = new GameInfo[](1000);  
        uint256 count = 0; // A counter for tracking the number of non-empty records

        // We go through the _gamesData mapping
        for (uint256 i = 0; i <= 999; i++) { 
            if (_gamesData[i].length != 0) {
                // We add a non-empty record to the result
                nonEmptyGames[count] = GameInfo(i, _gamesData[i][0]);
                count++;
            }
        }
        // We reduce the size of the array to the actual number of non-empty records
        GameInfo[] memory results = new GameInfo[](count);
        for (uint256 j = 0; j < count; j++) {
            results[j] = nonEmptyGames[j];
        }
        return results;
    }
    
    /**
     * @dev Checks if the game associated with the given gameId has a non-empty name.
     * Returns the gameId if the name is not empty and the game data array exists.
     * Returns END_OF_LIST if the game data array is empty or if the gameName is "END_OF_LIST".
     * 
     * @param gameId The ID of the game to check.
     * @return The gameId if gameName is not empty, otherwise returns END_OF_LIST.
     */
    function checkGameIdNotEmpty(uint256 gameId) external view returns (uint256) {
        // Retrieve the array of strings associated with the given gameId.
        string[] memory gameData = _gamesData[gameId];

        // If the array is empty, or the gameName is "END_OF_LIST", return END_OF_LIST
        if (gameData.length == 0 || keccak256(bytes(gameData[0])) == STR_END_OF_LIST) {
            return END_OF_LIST;
        }
        // Otherwise, return the gameId.
        return gameId;
    }
}