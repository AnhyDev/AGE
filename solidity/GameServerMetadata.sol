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

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title BaseUtil Contract
 * @dev This is an abstract contract that provides utility functions for interaction with the Anhydrite (ANH) and its proxy contract.
 * It's meant to be inherited by other contracts that require access to the proxy contract owners and their voting rights.
 *
 * Functions:
 * - _getProxyAddress: Returns the proxy contract address from the Anhydrite contract.
 * - _proxyContract: Returns an instance of the proxy contract.
 * - _isProxyOwner: Checks if an address is among the proxy contract owners.
 *
 * Modifier:
 * - onlyProxyOwner: Restricts function execution to the proxy contract owners or to the contract owner if the proxy is not set.
 */
abstract contract BaseUtil is Ownable {
    
    // Main project token (ANH) address
    IANH public constant ANHYDRITE = IANH(0x30cbF6931D7Ae248bf1D06e60931CE95096d4Aa0);

    // Returns the proxy contract address from the Anhydrite contract.
    function _getProxyAddress() internal view returns (address) {
        return ANHYDRITE.getProxyAddress();
    }

    // Returns an instance of the proxy contract.
    function _proxyContract() internal view returns(IProxy) {
        return IProxy(_getProxyAddress());
    }

    // Checks if an address is among the proxy contract owners.
    function _isProxyOwner(address senderAddress) internal view returns (bool) {
        return _proxyContract().isProxyOwner(senderAddress);
    }

    // Restricts function execution to the proxy contract owners or to the contract owner if the proxy is not set.
    modifier onlyProxyOwner() {
        IProxy proxy = _proxyContract();
        if (address(proxy) != address(0) && proxy.getTotalOwners() > 0) {
            require(_isProxyOwner(msg.sender), "BaseUtility: caller is not the proxy owner");
        } else {
            _checkOwner();
        }
        _;
    }
}
// Interface for interacting with the Anhydrite contract.
interface IANH is IERC20 {
    // Returns the interface address of the proxy contract
    function getProxyAddress() external view returns (address);
}
// Interface for interacting with the Proxy contract.
interface IProxy {
    // Returns the address of the current implementation (logic contract)
    function implementation() external view returns (address);
    // Returns the total number of owners
    function getTotalOwners() external view returns (uint256);
    // Checks if an address is a proxy owner (has voting rights)
    function isProxyOwner(address tokenAddress) external view returns (bool);
}




/*
 * A smart contract that extends the BaseUtil contract to provide financial management capabilities.
 * The contract allows for:
 * 1. Withdrawal of BNB to a designated address, which is the implementation address of an associated Proxy contract.
 * 2. Withdrawal of ERC20 tokens to the same designated address.
 * 3. Transfer of ERC721 tokens (NFTs) to the designated address.
 * All financial operations are restricted to the contract owner.
 */
abstract contract FinanceManager is BaseUtil {

   // Function for transferring BNB
    function withdrawMoney(uint256 amount) external onlyProxyOwner {
        address payable recipient = payable(_recepient());
        require(address(this).balance >= amount, "FinanceManager: Contract has insufficient balance");
        recipient.transfer(amount);
    }

    // Function for transferring ERC20 tokens
    function withdraERC20Tokens(address _tokenAddress, uint256 _amount) external onlyProxyOwner {
        IERC20 token = IERC20(_tokenAddress);
        require(token.balanceOf(address(this)) >= _amount, "FinanceManager: Not enough tokens on contract balance");
        token.transfer(_recepient(), _amount);
    }

    // Function for transferring ERC721 tokens
    function withdraERC721Token(address _tokenAddress, uint256 _tokenId) external onlyProxyOwner {
        IERC721 token = IERC721(_tokenAddress);
        require(token.ownerOf(_tokenId) == address(this), "FinanceManager: The contract is not the owner of this token");
        token.safeTransferFrom(address(this), _recepient(), _tokenId);
    }

    function _recepient() internal view returns (address) {
        address recepient = address(ANHYDRITE);
        if (address(_proxyContract()) != address(0)) {
            recepient = _proxyContract().implementation();
        }
        return recepient;
    }
}

// Interface for contracts that are capable of receiving ERC20 (ANH) tokens.
interface IERC20Receiver {
    // Function that is triggered when ERC20 (ANH) tokens are received.
    function onERC20Received(address _from, address _who, uint256 _amount) external returns (bytes4);

    // An event to track from which address the tokens were transferred, who transferred, to which address and the number of tokens
    event ChallengeIERC20Receiver(address indexed from, address indexed who, address indexed token, uint256 amount);
}

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
contract GameServerMetadata is BaseUtil, FinanceManager, IERC20Receiver {

    // A constant that represents the end of the games list.
    uint256 public constant END_OF_LIST = 1000;

    // A mapping from uint256-based game IDs to an array containing the game's name, contract name, and contract symbol.
    mapping(uint256 => string[]) internal _gamesData;

    // Event emitted when Anhydrite tokens are deposited.
    event DepositAnhydrite(address indexed from, address indexed who, uint256 amount);


    constructor () {
        // Initializes the _gamesData mapping with predefined gaming server data.
        _gamesData[0] = [   "Minecraft",               "Anhydrite Minecraft server contract",              "AGE_MC"    ];
        _gamesData[1] = [   "GTA",                     "Grand Theft Auto server contract",                 "AGE_GTA"   ];
        _gamesData[2] = [   "Terraria",                "Anhydrite Terraria server contract",               "AGE_TERRA" ];
        _gamesData[3] = [   "ARK Survival Evolved",    "Anhydrite ARK Survival Evolved server contract",   "AGE_ARK"   ];
        _gamesData[4] = [   "Rust",                    "Anhydrite Rust server contract",                   "AGE_RST"   ];
        _gamesData[5] = [   "Counter Strike",          "Counter-Strike server contract",                   "AGE_CS"    ];
        _gamesData[END_OF_LIST] = [ "END_OF_LIST",     "Anhydrite server module ",                         "AGE_"      ];

        IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24).setInterfaceImplementer(address(this), keccak256("IERC20Receiver"), address(this));
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
    function addServerData(uint256 gameId, string memory gameName, string memory contractName, string memory contractSymbol) public onlyOwner onlyProxyOwner {
        if (_gamesData[gameId].length == 0) {
            _gamesData[gameId].push(gameName);
            _gamesData[gameId].push(contractName);
            _gamesData[gameId].push(contractSymbol);
        } else {
            revert("GameServerMetadata: It is not possible to change the existing position");
        }
    }

    /**
     * @dev Handles the receipt of ERC20 tokens. Implements the IERC20Receiver interface.
     * @param _from The address from which the tokens are sent.
     * @param _who The address that triggered the sending of tokens.
     * @param _amount The amount of tokens received.
     * @return bytes4 The interface identifier, to confirm contract adherence.
     */
    function onERC20Received(address _from, address _who, uint256 _amount) external override returns (bytes4) {
        bytes4 fakeID = bytes4(keccak256("anything_else"));
        bytes4 validID = this.onERC20Received.selector;
        bytes4 returnValue = fakeID;  // Default value
        if (msg.sender.code.length > 0) {
            if (msg.sender == address(ANHYDRITE)) {
                emit DepositAnhydrite(_from, _who, _amount);
                returnValue = validID;
            } else {
                try IERC20(msg.sender).balanceOf(address(this)) returns (uint256 balance) {
                    if (balance >= _amount) {
                        emit ChallengeIERC20Receiver(_from, _who, msg.sender, _amount);
                        returnValue = validID;
                    }
                } catch {
                    // No need to change returnValue, it's already set to fakeID
                }
            }
        }
        return returnValue;
    }
}
// Interface for interacting with the ERC1820Registry contract.
interface IERC1820Registry {
    function setInterfaceImplementer(address account, bytes32 interfaceHash, address implementer) external;
    function getInterfaceImplementer(address account, bytes32 interfaceHash) external view returns (address);
}