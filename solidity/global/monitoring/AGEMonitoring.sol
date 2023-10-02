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

// @filepath Repository Location: [solidity/global/monitoring/AGEMonitoring.sol]

pragma solidity ^0.8.19;


import "../../interfaces/IAGEMonitoring.sol";
import "../../common/ERC20Receiver.sol";
import "../common/FinanceManager.sol";
import "../common/OwnableManager.sol";
import "./GameData.sol";
import "./ServerBlockingManager.sol";


/**
 * @title ServerDelegator
 * @author Your Name or Organization
 * @notice Контракт ServerDelegator розроблений для делегування серверів та обчислення плати за використання ресурсів.
 * Контракт надає можливість голосування для вибору сервера та забезпечує транспарентність та правильність обчислення плати.
 */
contract AGEMonitoring is IAGEMonitoring,
    OwnableManager,
    ServerBlockingManager,
    FinanceManager,
    GameData,
    ERC20Receiver {

    // Constant for pricing model.
    bytes32 private constant _priceVotingBytes  = keccak256(
        abi.encodePacked("The price of voting on monitoring")
    );

    // The base price is the fundamental unit of ether (wei) expressed in its decimal form (10^18).
    uint256 private constant _basePrice = 1 * 10 ** 18;
    
    // The following constants represent the percentage of tokens to be burnt when voting, 
    // varying based on the number of votes cast in a single transaction.
    // The higher the number of votes, the lower the percentage of tokens burnt.
    uint256 private constant PERCENTAGE_1_VOTES = 100;
    uint256 private constant PERCENTAGE_10_VOTES = 90;
    uint256 private constant PERCENTAGE_100_VOTES = 80;
    uint256 private constant PERCENTAGE_1000_VOTES = 70;
    uint256 private constant PERCENTAGE_10000_VOTES = 60;
    uint256 private constant PERCENTAGE_100000_VOTES = 50;
    uint256 private constant PERCENTAGE_1000000_VOTES = 40;

    // State variable to check if the contract is operational or not.
    bool public isContractStopped = false;

    // Mappings and struct to manage server-related data.
    // serversInfo stores metadata about each server including its index, game ID, vote count, and block status.
    mapping(address => ServerInfo) internal serversInfo;
    // servers is a quick lookup table to check if a server already exists.
    mapping(address => bool) internal servers;
    // gameServers maps game IDs to an array of server addresses.
    mapping(uint256 => address[]) internal gameServers;

    struct ServerInfo {
        uint256 index;
        uint256 gameId;
        uint256 votes;
        bool isBlocked;
    }


    // Voted event is emitted when a user successfully votes for a server.
    event Voted(address indexed voter, address indexed serverAddress, string game, string indexed symbol, uint256 totalVotes, uint256 newVotes);
    // ContractStopped is emitted when the contract is manually halted by the owner.
    event ContractStopped();

    constructor() {
        erc1820Registry.setInterfaceImplementer(address(this), keccak256("IAGEMonitoring"), address(this));
    }

    // This modifier ensures that the function can only be executed if the contract is not stopped.
    modifier notStopped() {
        require(!isContractStopped, "AGEMonitoring: Contract is stopped.");
        _;
    }

    // This modifier ensures that the function can only be executed by the global smart contract.
    // This is verified by comparing the caller address to the implementation address of the proxy contract.
    modifier onlyGlobal() {
        require(_proxyContract().implementation() == msg.sender,
            "AGEMonitoring: This function is only available from a global smart contract."
        );
        _;
    }

    /**
     * This function allows a global contract to add a new server address for a specified game.
     * @param gameId: The ID of the game to which the server is to be added.
     * @param serverAddress: The address of the server that is to be added.
     */
    function addServerAddress(uint256 gameId, address serverAddress) external override onlyGlobal notStopped {
        _addServerAddress(gameId, serverAddress);
    }

    /**
     * This internal function performs the actual addition of the server address for a specified game.
     * @param gameId: The ID of the game to which the server is to be added.
     * @param serverAddress: The address of the server that is to be added.
     */
    function _addServerAddress(uint256 gameId, address serverAddress) internal {
        //require(_checkGameIdNotEmpty(gameId), "AGEMonitoring: Invalid game ID");
        require(serverAddress != address(0), "AGEMonitoring: Invalid server address");
        require(!servers[serverAddress], "AGEMonitoring: Server address already added");

        gameServers[gameId].push(serverAddress);

        serversInfo[serverAddress] = ServerInfo({
            index: gameServers[gameId].length,
            gameId: gameId,
            votes: 1,
            isBlocked: false
        });

        servers[serverAddress] = true;
    }

    /**
     * This function allows a global contract to remove a server address.
     * @param serverAddress: The address of the server that is to be removed.
     */
    function removeServerAddress(address serverAddress) external override onlyGlobal notStopped {
        require(servers[serverAddress], "AGEMonitoring: Server address not found");

        uint256 gameId = serversInfo[serverAddress].gameId;
        uint256 index = serversInfo[serverAddress].index;
        gameServers[gameId][index] = address(0);
        delete servers[serverAddress];
        delete serversInfo[serverAddress];
    }

    /*
     * VOTING MECHANISM HANDLERS
     * These functions are responsible for handling 
     * all operations related to the voting process.
     */ 
    function voteForServer(address voterAddress, address serverAddress) external override notStopped {
        voterAddress = _getVoterAddress(voterAddress);
        _vote(voterAddress, serverAddress, 1, PERCENTAGE_1_VOTES);
    }
    function voteForServerWith10(address voterAddress, address serverAddress) external override notStopped {
        voterAddress = _getVoterAddress(voterAddress);
        _vote(voterAddress, serverAddress, 10, PERCENTAGE_10_VOTES);
    }
    function voteForServerWith100(address voterAddress, address serverAddress) external override notStopped {
        voterAddress = _getVoterAddress(voterAddress);
        _vote(voterAddress, serverAddress, 100, PERCENTAGE_100_VOTES);
    }
    function voteForServerWith1000(address voterAddress, address serverAddress) external override notStopped {
        voterAddress = _getVoterAddress(voterAddress);
        _vote(voterAddress, serverAddress, 1000, PERCENTAGE_1000_VOTES);
    }
    function voteForServerWith10000(address voterAddress, address serverAddress) external override notStopped {
        voterAddress = _getVoterAddress(voterAddress);
        _vote(voterAddress, serverAddress, 10000, PERCENTAGE_10000_VOTES);
    }
    function voteForServerWith100000(address voterAddress, address serverAddress) external override notStopped {
        voterAddress = _getVoterAddress(voterAddress);
        _vote(voterAddress, serverAddress, 100000, PERCENTAGE_100000_VOTES);
    }
    function voteForServerWith1000000(address voterAddress, address serverAddress) external override notStopped {
        voterAddress = _getVoterAddress(voterAddress);
        _vote(voterAddress, serverAddress, 1000000, PERCENTAGE_1000000_VOTES);
    }

    /*
     * TRANSACTION BURN FEE CALCULATORS
     * These functions are responsible for calculating the 
     * commission fees to be burned during a transaction.
     */
    function getBurnFeeFor1Vote() external view override returns (uint256) {
        return _calculateAmountToBurn(1, 100);
    }
    function getBurnFeeFor10Votes() external view override returns (uint256) {
        return _calculateAmountToBurn(10, PERCENTAGE_10_VOTES);
    }
    function getBurnFeeFor100Votes() external view override returns (uint256) {
        return _calculateAmountToBurn(100, PERCENTAGE_100_VOTES);
    }
    function getBurnFeeFor1000Votes() external view override returns (uint256) {
        return _calculateAmountToBurn(1000, PERCENTAGE_1000_VOTES);
    }
    function getBurnFeeFor10000Votes() external view override returns (uint256) {
        return _calculateAmountToBurn(10000, PERCENTAGE_10000_VOTES);
    }
    function getBurnFeeFor100000Votes() external view override returns (uint256) {
        return _calculateAmountToBurn(100000, PERCENTAGE_100000_VOTES);
    }
    function getBurnFeeFor1000000Votes() external view override returns (uint256) {
        return _calculateAmountToBurn(1000000, PERCENTAGE_1000000_VOTES);
    }

    /**
     * This internal function gets the address of the voter. 
     * If the sender is not the proxy contract implementation, 
     * the voter address is set to the sender's address. 
     * This function is mainly used in the voting mechanism handlers 
     * to ensure the correct voter address is used in the vote transactions.
     * @param voterAddress: The input address to be checked and possibly reassigned.
     * @return address: The address of the voter.
     */
    function _getVoterAddress(address voterAddress) internal view returns (address) {
        if (_proxyContract().implementation() != msg.sender) {
            voterAddress = msg.sender;
        }
        return voterAddress;
    }

    /**
     * This internal function handles the voting process, where votes are cast 
     * for a server, and the corresponding amount of tokens are burnt based on the 
     * number of votes and the specified percentage.
     * If the server does not exist, it gets added, and if it does, 
     * the number of votes it has received is updated.
     * An event is emitted with details of the vote transaction.
     * @param voterAddress: The address of the voter.
     * @param serverAddress: The address of the server being voted for.
     * @param numberOfVotes: The number of votes being cast.
     * @param percentage: The specified percentage to calculate the amount to burn.
     */
    function _vote(address voterAddress, address serverAddress, uint256 numberOfVotes, uint256 percentage) internal {
        require(serverAddress != address(0), "AGEMonitoring: Invalid server address");
        
        uint256 amountToBurn = _calculateAmountToBurn(numberOfVotes, percentage);

        if (amountToBurn > 0) {
            require(ANHYDRITE.balanceOf(voterAddress) >= amountToBurn, "AGEMonitoring: Insufficient token balance");
            require(ANHYDRITE.allowance(voterAddress, address(this)) >= amountToBurn, "AGEMonitoring: Token allowance too small");
            ANHYDRITE.burnFrom(voterAddress, amountToBurn);
        }

        uint256 gameId = serversInfo[serverAddress].gameId;
        if (!servers[serverAddress]) {
            _addServerAddress(gameId, serverAddress);
        } else {
            serversInfo[serverAddress].votes += numberOfVotes;
        }
        (string memory gameName, string memory gameSymbol) = _getGameServerMetadata().getServerData(gameId);

        emit Voted(voterAddress, serverAddress, gameName, gameSymbol, serversInfo[serverAddress].votes, numberOfVotes);
    }
 
    /**
     * This function calculates the amount of tokens to burn based on the number of votes and the specified percentage.
     * @param numberOfVotes: The number of votes.
     * @param percentage: The specified percentage.
     */
    function _calculateAmountToBurn(uint256 numberOfVotes, uint256 percentage) internal view returns (uint256) {
        uint256 burned = _proxyContract().getPrice(_priceVotingBytes) != 0 ? 
            _proxyContract().getPrice(_priceVotingBytes) : _basePrice;
            
        if (numberOfVotes == 1 && _proxyContract().getPrice(_priceVotingBytes) == 0) {
            return 0;
        } else {
            return (burned * numberOfVotes * percentage) / 100;
        }
    }

    /**
     * This function returns the vote count of a specified server.
     * @param serverAddress: The address of the server.
     */
    function getServerVotes(address serverAddress) external override view returns (uint256) {
        if(serversInfo[serverAddress].isBlocked) {
            return 0;
        }
        return serversInfo[serverAddress].votes;
    }

    /**
     * This function returns a list of server addresses for a specified game ID within a range of indices.
     * @param gameId: The ID of the game.
     * @param startIndex: The starting index of the range.
     * @param endIndex: The ending index of the range.
     */
    function getGameServerAddresses(uint256 gameId, uint256 startIndex, uint256 endIndex) external override view returns (address[] memory) {
        require(_checkGameIdNotEmpty(gameId), "AGEMonitoring: Invalid game ID");
        require(startIndex <= endIndex, "AGEMonitoring: Invalid start or end index");

        address[] storage originalList = gameServers[gameId];
        uint256 length = originalList.length;

        if (length == 0) {
            return new address[](0);
        }

        require(startIndex < length, "AGEMonitoring: Start index out of bounds.");

        if (endIndex >= length) {
            endIndex = length - 1;
        }

        uint256 resultLength = endIndex - startIndex + 1;

        // Create a dynamic memory array to hold the valid server addresses temporarily
        address[] memory tempResult = new address[](resultLength);
        uint256 count = 0;

        // Loop through the original list and only add non-zero addresses to tempResult
        for (uint256 i = 0; i < resultLength; i++) {
            address serverAddress = originalList[startIndex + i];
            if (serverAddress != address(0)) {
                tempResult[count] = serverAddress;
                count++;
            }
        }

        // Create a new array with the correct size and copy valid addresses from tempResult
        address[] memory resultList = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            resultList[i] = tempResult[i];
        }

        return resultList;
    }

    /**
     * This function checks whether a server exists given its address.
     * @param serverAddress: The address of the server.
     */
    function isServerExist(address serverAddress) external override view returns (bool) {
        return _isServer(serverAddress);
    }

    /**
     * This function checks whether a server is blocked and also returns its vote count.
     * @param serverAddress: The address of the server.
     */
    function getServerBlocked(address serverAddress) external override view returns (bool, uint256) {
        return (_isBlocked(serverAddress), serversInfo[serverAddress].votes);
    }

    /**
     * This function allows the contract owner to halt the contract operations.
     */
    function stopContract() external onlyOwner {
        require(!isContractStopped, "AGEMonitoring: Contract is already stopped.");
        isContractStopped = true;
        emit ContractStopped();
    }

    /**
     * This internal function checks whether a server exists.
     * @param serverAddress: The address of the server.
     */
    function _isServer(address serverAddress) internal override view virtual returns (bool) {
        return servers[serverAddress];
    }
    
    /**
     * This internal function checks whether a server is blocked.
     * @param serverAddress: The address of the server.
     */
    function _isBlocked(address serverAddress) internal override view virtual returns (bool) {
        return serversInfo[serverAddress].isBlocked;
    }

    /**
     * This internal function sets a server as blocked.
     * @param serverAddress: The address of the server.
     */
    function _setBlocked(address serverAddress) internal override virtual {
        serversInfo[serverAddress].isBlocked = true;
    }
    
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC20Receiver) returns (bool) {
        return interfaceId == type(IAGEMonitoring).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}