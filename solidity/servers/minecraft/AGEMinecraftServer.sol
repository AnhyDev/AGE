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

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title BaseUtil Contract
 * @dev This is an abstract contract that provides utility functions for interaction with the Anhydrite (ANH) and its proxy contract.
 * It's meant to be inherited by other contract.
 *
 * Functions:
 * - _getProxyAddress: Returns the proxy contract address from the Anhydrite contract.
 * - _proxyContract: Returns an instance of the proxy contract.
 */
abstract contract BaseUtility {
    
    // Address of the Main project token (ANH)
    IANH public constant ANHYDRITE = IANH(0x47E0CdCB3c7705Ef6fA57b69539D58ab5570799F);

    // Address of the ERC-1820 Registry
    IERC1820Registry constant internal erc1820Registry = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    /**
    * @notice Returns an instance of the proxy contract.
    * @dev Creates and returns an instance of the proxy contract using the address obtained from _getProxyAddress function.
    * @return IProxy An instance of the proxy contract.
    */
    function _proxyContract() internal view returns(IProxy) {
        return IProxy(_getProxyAddress());
    }

    /**
    * @notice Returns the proxy contract address from the Anhydrite contract.
    * @dev Retrieves and returns the address of the proxy contract by calling getProxyAddress function of the ANHYDRITE contract.
    * @return address The address of the proxy contract.
    */
    function _getProxyAddress() private view returns (address) {
        return ANHYDRITE.getProxyAddress();
    }
}

// Interface for interacting with the Anhydrite contract.
interface IANH is IERC20 {
    // Returns the interface address of the proxy contract
    function getProxyAddress() external view returns (address);
    // Is the address whitelisted
    function isinWhitelist(address contractAddress) external view returns (bool);
}

// Interface for interacting with the Proxy contract.
interface IProxy {
    // Returns the address of the current implementation (logic contract).
    function implementation() external view returns (address);
    
    // Checks and returns whether the contract is stopped or not.
    function isStopped() external view returns (bool);
   
    // Enum representing the various types of modules that can be interacted with via the proxy.
    enum ModuleType {
        Server, // Represents a server module.
        Token, // Represents a token module.
        NFT, // Represents a NFT module.
        Shop, // Represents a shop or item shop module.
        Voting, // Represents a voting module.
        Lottery, // Represents a lottery module.
        Raffle, // Represents a raffle module.
        Game, // Represents a game module.
        Advertisement, // Represents an advertisement module.
        AffiliateProgram, // Represents an affiliate program module.
        Event, // Represents an event module.
        RatingSystem, // Represents a rating system module.
        SocialFunctions, // Represents a social functions module.
        Auction, // Represents an auction module.
        Charity // Represents a charity module.
    }
    
    // Structure defining a Module with a name, type, type as a string, and the address of its factory contract.
    struct Module {
        string moduleName;
        ModuleType moduleType;
        string moduleTypeString;
        address moduleFactory;
    }
   
    // Retrieves the price associated with the given name from the implementation contract.
    function getPrice(string memory name) external view returns (uint256);
    
    // Creates and handles a module in the implementation contract, returning the address of the created module.
    function deployModuleOnServer(string memory factoryName, uint256 moduleId, address ownerAddress) external returns (address);
    
    // Converts and returns the module type from an enum to a string.
    function getModuleTypeString(ModuleType moduleType) external pure returns (string memory);
}


/**
 * @title FinanceManager
 * @dev The FinanceManager contract is an abstract contract that extends Ownable.
 * It provides a mechanism to transfer Ether, ERC20 tokens, and ERC721 tokens from
 * the contract's balance, accessible only by the owner.
 */
abstract contract FinanceManager is Ownable, IERC721Receiver {

    /**
     * @notice Transfers Ether from the contract's balance to a specified recipient.
     * @dev Can only be called by the contract owner.
     * @param recipient The address to receive the transferred Ether.
     * @param amount The amount of Ether to be transferred in wei.
     */
    function transferMoney(address payable recipient, uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "FinanceManager: Contract has insufficient balance");
        require(recipient != address(0), "FinanceManager: Recipient address is the zero address");
        recipient.transfer(amount);
    }
    
    /**
     * @notice Transfers ERC20 tokens from the contract's balance to a specified address.
     * @dev Can only be called by the contract owner.
     * @param _tokenAddress The address of the ERC20 token contract.
     * @param _to The recipient address to receive the transferred tokens.
     * @param _amount The amount of tokens to be transferred.
     */
    function transferERC20Tokens(address _tokenAddress, address _to, uint256 _amount) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        require(token.balanceOf(address(this)) >= _amount, "FinanceManager: Not enough tokens on contract balance");
        token.transfer(_to, _amount);
    }

    /**
     * @notice Transfers an ERC721 token from the contract's balance to a specified address.
     * @dev Can only be called by the contract owner.
     * @param _tokenAddress The address of the ERC721 token contract.
     * @param _to The recipient address to receive the transferred token.
     * @param _tokenId The unique identifier of the token to be transferred.
     */
    function transferERC721Token(address _tokenAddress, address _to, uint256 _tokenId) external onlyOwner {
        IERC721 token = IERC721(_tokenAddress);
        require(token.ownerOf(_tokenId) == address(this), "FinanceManager: The contract is not the owner of this token");
        token.safeTransferFrom(address(this), _to, _tokenId);
    }

    /**
     * @notice The onERC721Received function is used to process the receipt of ERC721 tokens.
     */
    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    
    receive() external payable {}
}


/*
 * IERC20Receiver Interface:
 * - Purpose: To handle the receiving of ERC-20 tokens from another smart contract.
 * - Key Method: 
 *   - `onERC20Received`: This is called when tokens are transferred to a smart contract implementing this interface.
 *                        It allows for custom logic upon receiving tokens.
 */
interface IERC20Receiver {
    // Function that is triggered when ERC20 (ANH) tokens are received.
    function onERC20Received(address _from, address _who, uint256 _amount) external returns (bytes4);
}

/**
 * @title ERC20Receiver Abstract Contract
 * @dev This contract extends from IERC20Receiver, BaseUtility, and ERC165 interfaces.
 *      It provides functionalities for receiving ERC20 (ANHYDRITE) tokens and responding with a magic identifier.
 *      It uses the IERC1820Registry for handling standardized contract interface detection.
 * 
 *      Events:
 *      - DepositAnhydrite: Emitted when ANHYDRITE tokens are deposited.
 *      - ChallengeIERC20Receiver: Emitted to track from which address the tokens were transferred,
 *          who transferred them, to which address and the number of tokens.
 * 
 *      Functions include:
 *      - onERC20Received: Overridden from IERC20Receiver, handles incoming ERC20 token transfers.
 */
abstract contract ERC20Receiver is IERC20Receiver, BaseUtility, ERC165 {

    // Event emitted when Anhydrite tokens are deposited.
    event DepositAnhydrite(address indexed from, address indexed who, uint256 amount);
    // An event to track from which address the tokens were transferred, who transferred, to which address and the number of tokens
    event ChallengeIERC20Receiver(address indexed from, address indexed who, address indexed token, uint256 amount);

    constructor() {
        //supportedInterfaces[type(IERC20Receiver).interfaceId] = true;
        erc1820Registry.setInterfaceImplementer(address(this), keccak256("IERC20Receiver"), address(this));
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
            return returnValue;
        } else {
            revert ("ERC20Receiver: This function is for handling token acquisition");
        }
    }

    function supportsInterface(bytes4 interfaceId) public view override virtual returns (bool) {
        return  interfaceId == type(IERC20Receiver).interfaceId ||
                super.supportsInterface(interfaceId);
    }
}
/**
 * @title IERC1820Registry Interface
 * @dev This is an interface for the ERC1820 Registry contract, a central registry 
 *      used to discover which interface a particular address supports.
 * 
 *      The ERC1820 standard is a meta-standard that defines a universal registry smart contract 
 *      where any address (contract or regular account) can indicate which interface it supports.
 *
 *      Functions:
 *      - setInterfaceImplementer: Sets the contract which implements a specific interface for an address.
 */
interface IERC1820Registry {
    function setInterfaceImplementer(address account, bytes32 interfaceHash, address implementer) external;
}


/**
 * @title CashbackStorage Contract
 * @dev This contract allows the owner to manage cashback entries,
 * each identified by a name and linked to a contract address and a price.
 * It also provides utility functions to verify and retrieve cashback information.
 */
abstract contract CashbackStorage is Ownable {

    /** 
     * @dev Struct to represent individual Cashback entry with its properties
     */
    struct StructCashback {
        string name;  // Name of the cashback entry
        address contractCashbackAddress;  // Associated contract address
        uint256 price;  // Price linked with the cashback entry
    }
    
    // Mapping to store cashback entries
    mapping(bytes32 => StructCashback) internal _cashback;
    
    // Array to store keys of cashback entries
    bytes32[] internal _cashbackList;

    /**
     * @dev Allows owner to create or update a cashback entry.
     * @param name Name of the cashback entry.
     * @param contractCashbackAddress Address of the linked contract.
     * @param price Price associated with the cashback entry.
     */
    function upsertCashback(string memory name, address contractCashbackAddress, uint256 price) external onlyOwner {
        require(_supportsICashback(contractCashbackAddress), "CashbackStorage: Address does not comply with ICashback interface");
        bytes32 key = keccak256(abi.encodePacked(name));
        
        if (!isCashbackExists(key)) {
            _cashbackList.push(key);
        }
        
        // додати автоматичне встановлення дозволу модулю отримувати кешбек у контракті кешбеку
        
        StructCashback storage cb = _cashback[key];
        cb.name = name;
        cb.contractCashbackAddress = contractCashbackAddress;
        cb.price = price;
    }

    /**
     * @dev Allows owner to delete a cashback entry.
     * @param key The key associated with the cashback entry to be deleted.
     */
    function deleteCashback(bytes32 key) external {
        require(isCashbackExists(key), "CashbackStorage: Key does not exist.");

        if (msg.sender == owner() || (msg.sender == _cashback[key].contractCashbackAddress)) {
            delete _cashback[key];
        
            for (uint256 i = 0; i < _cashbackList.length; i++) {
                if (_cashbackList[i] == key) {
                    _cashbackList[i] = _cashbackList[_cashbackList.length - 1];
                    _cashbackList.pop();
                    break;
                }
            }
        } else {
            revert("CashbackStorage: Caller does not have permission to delete this cashback");
        }
    }

    /**
     * @dev Utility function to check existence of a cashback entry.
     * @param source The key associated with the cashback entry.
     * @return Returns true if the cashback entry exists, otherwise false.
     */
    function isCashbackExists(bytes32 source) internal view returns (bool) {
        return _cashback[source].contractCashbackAddress != address(0);
    }

    /**
     * @dev Function to retrieve a cashback entry by name.
     * @param name Name of the cashback entry.
     * @return Address of the linked contract and the associated price.
     */
    function getCashback(string memory name) external view returns (address, uint256) {
        return _getCashback(keccak256(abi.encodePacked(name)));
    }

    /**
     * @dev Function to retrieve a cashback entry by key.
     * @param source The key associated with the cashback entry.
     * @return Address of the linked contract and the associated price.
     */
    function getCashback(bytes32 source) external view returns (address, uint256) {
        return _getCashback(source);
    }

    /**
     * @dev Internal function to retrieve a cashback entry by key.
     * @param source The key associated with the cashback entry.
     * @return Address of the linked contract and the associated price.
     */
    function _getCashback(bytes32 source) internal view returns (address, uint256) {
        return (_cashback[source].contractCashbackAddress, _cashback[source].price);
    }

    /**
     * @dev Function to retrieve all the cashback entries.
     * @return An array of StructCashback representing all cashback entries.
     */
    function getAllCashbacks() external view returns (StructCashback[] memory) {
        uint256 length = _cashbackList.length;
        StructCashback[] memory cashbacksList = new StructCashback[](length);
        
        for (uint256 i = 0; i < length; i++) {
            bytes32 key = _cashbackList[i];
            cashbacksList[i] = _cashback[key];
        }
        
        return cashbacksList;
    }

    /**
     * @dev Utility function to verify if an address supports ICashback interface.
     * @param contractAddress Address to be verified.
     * @return Returns true if the address supports ICashback interface, otherwise false.
     */
    function _supportsICashback(address contractAddress) internal view returns (bool) {
        return IERC165(contractAddress).supportsInterface(type(ICashback).interfaceId);
    }
}
/**
 * @title ICashback Interface
 * @dev Specifies the interface to interact with cashback related contracts.
 */
interface ICashback {
    function issueTokens(address _recipient, bytes32 source) external;
    function isAddressApproved(address module) external view returns (bool);
    function toggleAddressApproval(address address_, bool status) external;
}



/**
 * @title NFTDirectSales
 * @dev This contract is designed to manage the direct sales of NFTs. 
 * It facilitates the pricing and purchasing of NFTs using either Ether or ERC20 tokens.
 * This is an abstract contract meant to be extended by concrete implementations, which should provide the
 * implementation for the _newMint function.
 */
abstract contract NFTDirectSales is ERC721Enumerable, ERC721URIStorage, ERC721Burnable, Ownable {

    // Struct representing the price of the NFT, can be in Ether or ERC20 tokens.
    struct Price {
        address tokenAddress; // Address of the ERC20 token. Address(0) represents Ether.
        uint256 amount; // Amount of either Ether or ERC20 tokens required.
    }
    
    // State variable storing the price of the NFT.
    Price private _price;

    // Event emitted when an NFT is purchased.
    event NFTPurchased(address indexed purchaser);

    /**
     * @dev Allows the owner to set the price of the NFT.
     * @param tokenAddress The address of the ERC20 token, or address(0) for Ether.
     * @param payAmount The amount of Ether or ERC20 tokens required.
     */
    function setPriceNFT(address tokenAddress, uint256 payAmount) external onlyOwner {
       _setPrice(tokenAddress, payAmount);
    }

    /**
     * @dev Internal function to set the price of the NFT.
     * @param tokenAddress The address of the ERC20 token, or address(0) for Ether.
     * @param payAmounts The amount of Ether or ERC20 tokens required.
     */
    function _setPrice(address tokenAddress, uint256 payAmounts) internal {
        _price = Price({
            tokenAddress: tokenAddress,
            amount: payAmounts
        });
    }

    /**
     * @dev Allows users to buy an NFT paying with Ether.
     */
    function buyNFT() external payable {
        _buyNFT();
    }

    /**
     * @dev Allows users to buy an NFT paying with ERC20 tokens.
     */
    function buyNFTWithTokens() external {
        _buyNFT();
    }
  
    /**
     * @dev Internal function executing the purchase of an NFT.
     * Checks if NFTs are available and calls the service to execute the purchase,
     * then mints a new NFT to the buyer.
     */
    function _buyNFT() internal {
        require(totalSupply() > 0, "NFTDirectSales: Token with ID 0 has already been minted");
        _buyService(); // Execute payment and transfer logic
        _newMint(msg.sender, tokenURI(0)); // Mint the new NFT
    }
    
    /**
     * @dev Internal function to handle the transfer of funds and emit the purchase event.
     */
    function _buyService() internal {
        uint256 paymentAmount = _price.amount;
        address paymentToken = _price.tokenAddress;
        if(paymentToken == address(0)) { // If paying with ether
            require(msg.value == paymentAmount, "NFTDirectSales: The amount of ether sent does not match the required amount.");
        } else { // If paying with tokens
            IERC20 token = IERC20(paymentToken);
            token.transferFrom(msg.sender, address(this), paymentAmount); // Transfer the required amount of tokens from the buyer to the contract
        }

        emit NFTPurchased(msg.sender); // Emit the purchase event
    }

    /**
     * @dev Internal virtual function meant to be overridden by concrete implementations.
     * Responsible for minting the new NFT.
     * @param to The address to which the NFT will be minted.
     * @param uri The URI for the NFT's metadata.
     */
    function _newMint(address to, string memory uri) internal virtual;

    /**
     * @dev Handles actions to perform before transferring tokens, resolving conflicts between ERC721 and ERC721Enumerable.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize); // Calls the respective functions from inherited contracts
    }

    /**
     * @dev Burns the token, resolving conflicts between ERC721 and ERC721URIStorage.
     */
    function _burn(uint256 tokenId) internal override (ERC721, ERC721URIStorage) {
        super._burn(tokenId); // Calls the respective functions from inherited contracts
    }

    /**
     * @dev Retrieves the token URI, resolving conflicts between ERC721 and ERC721URIStorage.
     */
    function tokenURI(uint256 tokenId) public view override (ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId); // Calls the respective functions from inherited contracts
    }

    /**
     * @dev Checks if the contract supports a specific interface, resolving conflicts between ERC721, ERC721Enumerable, and ERC721URIStorage.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC721, ERC721Enumerable, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId); // Calls the respective functions from inherited contracts
    }
}


abstract contract Modules is BaseUtility, Ownable {

    struct Module {
        string moduleName;
        IProxy.ModuleType moduleType;
        string moduleTypeString;
        address moduleDeployedAddress;
    }

    bytes32[] private _moduleList;
    mapping(bytes32 => Module) private _modules;

    event DeployModule(address indexed contractAddress, string moduleName, uint256 moduleId);


    // Deploy a module
    function deployModule(string memory name, uint256 moduleId) external onlyOwner {
        IProxy.ModuleType moduleType = IProxy.ModuleType(moduleId);
        bytes32 hash = _getModuleHash(name, moduleType);
        require(!_isModuleInstalled(hash), "Modules: Module already installed");
        address contractAddress = _proxyContract().deployModuleOnServer(name, moduleId, msg.sender);

        Module memory module = Module({
            moduleName: name,
            moduleType: moduleType,
            moduleTypeString: _proxyContract().getModuleTypeString(moduleType),
            moduleDeployedAddress: contractAddress
        });

        _modules[hash] = module;
        _moduleList.push(hash);
        
        emit DeployModule(contractAddress, name, moduleId);
    }

    // Remove a module
    function removeModule(string memory moduleName, uint256 moduleId) external  onlyOwner {
        IProxy.ModuleType moduleType = IProxy.ModuleType(moduleId);
        bytes32 hash = _getModuleHash(moduleName, moduleType);
        require(_isModuleInstalled(hash), "Modules: Module not installed");

        IModules(_modules[hash].moduleDeployedAddress).dissociateAndCleanUpServerContract();
        _modules[hash] = Module("", IProxy.ModuleType.Voting, "", address(0));
        for (uint i = 0; i < _moduleList.length; i++) {
            if (_moduleList[i] == hash) {
                _moduleList[i] = _moduleList[_moduleList.length - 1];
                _moduleList.pop();
                return;
            }
        }
    }
    
    // Get a module
    function getModuleAddress(string memory name, uint256 moduleId) external view returns (address) {
        return _getModuleAddress(name, moduleId);
    }
    function _getModuleAddress(string memory name, uint256 moduleId) internal view returns (address) {
        bytes32 hash = _getModuleHash(name, IProxy.ModuleType(moduleId));
        Module memory module = _modules[hash];
        return module.moduleDeployedAddress;
    }

    // Check if a module Installed
    function isModuleInstalled(string memory name, uint256 moduleId) external view returns (bool) {
        bytes32 hash = _getModuleHash(name, IProxy.ModuleType(moduleId));
        return _isModuleInstalled(hash);
    }
    function _isModuleInstalled(bytes32 hash) internal view returns (bool) {
       return bytes(_modules[hash].moduleName).length != 0;
    }

    // Get a hsah 
    function _getModuleHash(string memory name, IProxy.ModuleType moduleType) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(name, uint256(moduleType)));
    }

}
interface IModules {
    function dissociateAndCleanUpServerContract() external;
}



interface IAGEMC {
    function setServerDetails(string calldata ipString, uint16 newServerPort, string calldata newServerName, string calldata newServerAddress) external;
    function setServerIpAddress(string calldata ipString) external;
    function getServerIpAddress() external view returns (string memory);
    function setServerPort(uint16 newPort) external;
    function getServerPort() external view returns (uint16);
    function setServerName(string calldata newName) external;
    function getServerName() external view returns (string memory);
    function setServerDomainAddress(string calldata newAddress) external;
    function getServerDomainAddress() external view returns (string memory);
}


contract AGEMinecraftServer is
  FinanceManager,
  Modules,
  NFTDirectSales,
  ERC20Receiver,
  CashbackStorage,
  IAGEMC {

    using Counters for Counters.Counter;
    

    Counters.Counter private _tokenIdCounter;
    string private _serverIpAddress;
    uint16 private _serverPort;
    string private _serverName;
    string private _serverAddress;
    IProxy.Module[] private _moduleList;
    mapping(bytes32 => IProxy.Module) private _modules;

    IERC20 public _tokenServer;

    constructor(address creator, string memory name, string memory symbol) ERC721(name, symbol) {
        _newMint(creator, "ipfs://bafkreiahrn7kxg244pnzm5cv5y7oyja54tyn2f3ao3b62tcxqv44hlj4ru");
        erc1820Registry.setInterfaceImplementer(address(this), keccak256("ERC721Receiver"), address(this));
    }


    function _newMint(address to, string memory uri) internal override {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }


    function setServerDetails(
        string calldata newServerIpAddress, uint16 newServerPort, string calldata newServerName, string calldata newServerAddress) external override onlyOwner {
            _setServerDetails(newServerIpAddress, newServerPort, newServerName, newServerAddress);
    }

    function _setServerDetails(
        string calldata newServerIpAddress, uint16 newServerPort, string calldata newServerName, string calldata newDomainAddress) internal {
        bool validIP = _isValidIPv4String(newServerIpAddress);
        bool validPort = _isValidMinecraftPort(newServerPort);
        bool validServerName = bytes(newServerName).length != 0;
        bool validServerAddress = _isValidDomain(newDomainAddress);
        require(validIP || validPort || validServerName || validServerAddress, "AGEMinecraftServer: At least one valid parameter is required");

        if (validIP) {
            _serverIpAddress = newServerIpAddress;
        }

        if (newServerPort != 0) {
            _serverPort = newServerPort;
        }

        if (validServerName) {
            _serverName = newServerName;
        }

        if (validServerAddress) {
            _serverAddress = newDomainAddress;
        }
    }
    
    function setServerIpAddress(string calldata newServerIpAddress) external override onlyOwner {
        require(_isValidIPv4String(newServerIpAddress), "Invalid IP address");
        _serverIpAddress = newServerIpAddress;
    }
    
    function getServerIpAddress() external override view returns (string memory) {
        return _serverIpAddress;
    }

    function setServerPort(uint16 newServerPort) external override onlyOwner {
        _isValidMinecraftPort(newServerPort);
        _serverPort = newServerPort;
    }

    function getServerPort() external override view returns (uint16) {
        return _serverPort;
    }

    function setServerName(string calldata newName) external override onlyOwner {
        _serverName = newName;
    }

    function getServerName() external view override returns (string memory) {
        return _serverName;
    }

    function setServerDomainAddress(string calldata newDomainAddress) external override onlyOwner {
        _isValidDomain(newDomainAddress);
        _serverAddress = newDomainAddress;
    }

    function getServerDomainAddress() external view override returns (string memory) {
        return _serverAddress;
    }

    function supportsInterface(bytes4 interfaceId) public view override (ERC20Receiver, NFTDirectSales) returns (bool) {
        return  interfaceId == type(IERC721Receiver).interfaceId ||
                interfaceId == type(IAGEMC).interfaceId ||
                super.supportsInterface(interfaceId);
    }

    function _isValidIPv4String(string memory ipString) private pure returns (bool) {
        // Перевірка довжини рядка
        if (bytes(ipString).length < 7 || bytes(ipString).length > 15) return false;
        
        bytes memory ipBytes = bytes(ipString);
        uint8 dotCount = 0;
        bytes4 ipBytesTemp;
        uint8 currentOctet = 0;

        // Конвертація рядка із символів та перевірка валідності
        for (uint256 i = 0; i < ipBytes.length; i++) {
            if ((ipBytes[i] < "0" || ipBytes[i] > "9") && ipBytes[i] != ".") return false;

            if (ipBytes[i] == ".") {
                if (currentOctet > 255 || currentOctet == 0) return false;
                ipBytesTemp |= bytes4(bytes1(currentOctet & 0xFF)) >> (dotCount * 8);
                currentOctet = 0;
                dotCount++;
            } else {
                currentOctet = currentOctet * 10 + uint8(ipBytes[i]) - 48;
            }
        }

        // Перевірка кількості крапок та валідності останнього октета
        if (dotCount != 3 || currentOctet > 255 || currentOctet == 0) return false;
        ipBytesTemp |= bytes4(bytes1(currentOctet & 0xFF));

        // Перевірка валідності конвертованого IP-адреси та чи він не є приватним
        if (ipBytesTemp == bytes4(0) || 
            uint8(ipBytesTemp[0]) == 10 || 
            (uint8(ipBytesTemp[0]) == 172 && (uint8(ipBytesTemp[1]) >= 16 && uint8(ipBytesTemp[1]) <= 31)) || 
            (uint8(ipBytesTemp[0]) == 192 && uint8(ipBytesTemp[1]) == 168)) return false;

        return true;
    }

    function _isValidDomain(string memory domain) private pure returns (bool) {
        bytes memory domainBytes = bytes(domain);
        if(domainBytes.length < 3 || domainBytes[0] == '.' || domainBytes[domainBytes.length - 1] == '.') return false;
        
        uint dotCount = 0;
        
        for(uint i=0; i<domainBytes.length; i++) {
            bytes1 char = domainBytes[i];
            
            if(char == '.') {
                dotCount++;
                if(dotCount > 3) return false;
            }
            
            if(!((char >= 'a' && char <= 'z') || (char >= '0' && char <= '9') || char == '-' || char == '.')) return false;
            if(i > 0 && domainBytes[i] == '.' && domainBytes[i-1] == '.') return false; // перевіряємо на '..'
        }
        
        if(dotCount < 1 || domainBytes[domainBytes.length - 1] == '-') return false;

        return true;
    }

    function _isValidMinecraftPort(uint16 port) private pure returns (bool) {
        if (port < 1024) return false;
        return true;
    }
}


contract FactoryAGEMinecraftServer is BaseUtility {

    struct Deployed {
        address moduleAddress;
        address ownerAddress;
    }

    Deployed[] private _deployedModules;
    mapping(address => bool) public isDeploy;

    event ModuleCreated(address indexed moduleAddress, address indexed owner);


    function deployModule(string memory name, string memory symbol, address ownerAddress, address) external onlyAllowed(ownerAddress) returns (address) {
        // unusedAddress not used but retained for compatibility with the standard
        AGEMinecraftServer newModule = new AGEMinecraftServer(ownerAddress, name, symbol);
        newModule.transferOwnership(ownerAddress);
        
        Deployed memory newDeployedModule = Deployed({
            moduleAddress: address(newModule),
            ownerAddress: ownerAddress
        });
        isDeploy[ownerAddress] = true;

        _deployedModules.push(newDeployedModule);
        emit ModuleCreated(address(newModule), msg.sender);
        
        return address(newModule);
    }

    function getDeployedModules() external view returns (Deployed[] memory) {
        return _deployedModules;
    }

    function getNumberOfDeployedModules() external view returns (uint256) {
        return _deployedModules.length;
    }

    modifier onlyAllowed(address ownerAddress) {
        require(msg.sender == _proxyContract().implementation(), "Caller is not the implementation");
        require(!_proxyContract().isStopped(), "Deploying is stopped");
        require(!isDeploy[ownerAddress], "This address has already deployed this module");
        _;
    }

    receive() external payable {
        Address.sendValue(payable(_proxyContract().implementation()), msg.value);
    }
}