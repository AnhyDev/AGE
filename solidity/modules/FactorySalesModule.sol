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

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title BaseUtil Contract
 * @dev This is an abstract contract that provides utility functions for interaction with the Anhydrite (ANH) and its proxy contract.
 * It's meant to be inherited by other contracts.
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
    // Returns the address of the current implementation (logic contract)
    function implementation() external view returns (address);
    // Checks and returns whether the contract is stopped or not
    function isStopped() external view returns (bool);
   
   // Functions delegated to the implementation contract
   
    // Gets the price associated with the given name from the implementation contract.
    function getPrice(string memory name) external view returns (uint256); 
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


// Declares an abstract contract ERC165 that implements the IERC165 interface
abstract contract ERC165 is IERC165 {

    // Internal mapping to store supported interfaces
    mapping(bytes4 => bool) internal supportedInterfaces;

    // Constructor to initialize the mapping of supported interfaces
    constructor() {
        // 0x01ffc9a7 is the interface identifier for ERC165 according to the standard
        supportedInterfaces[0x01ffc9a7] = true;
    }

    // Implements the supportsInterface method from the IERC165 interface
    // The function checks if the contract supports the given interface
    function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
        return supportedInterfaces[interfaceId];
    }
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
        supportedInterfaces[type(IERC20Receiver).interfaceId] = true;
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
 * @title Cashback
 * @dev This abstract contract provides a template for implementing
 * module-specific cashback logic in collaboration with an IServer contract.
 */
abstract contract Cashback is Ownable {

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
    function dissociateAndCleanUpServerContract() external {
        require(msg.sender == address(_serverContract), "Cashback: Only the server contract can call this function");
        
        IServer.StructCashback[] memory cashbacks = _serverContract.getAllCashbacks();
        uint256 modifications = 0;
        for (uint256 i = 0; i < cashbacks.length; i++) {
            IModuleCashback cashbackModule = IModuleCashback(cashbacks[i].contractCashbackAddress);
            if (cashbackModule.isAddressApproved(address(this))) {
                cashbackModule.toggleAddressApproval(address(this), false);
                modifications++;
            }
        }
        delete _serverContract;
        IFactory(moduleFactory).removeModule(address(_serverContract));
        emit ServerContractRemoved(address(_serverContract), modifications);
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
interface IFactory {
    function removeModule(address serverContractAddress) external;
}

/**
 * @title IServer
 * @dev Interface to represent the Server contract which manages and provides the cashback data.
 */
interface IServer {
    struct StructCashback {
        string name;
        address contractCashbackAddress;
        uint256 price;
    }

    function getAllCashbacks() external view returns (StructCashback[] memory);
    function getCashback(bytes32 source) external view returns (address, uint256);
}

/**
 * @title ICashback
 * @dev Interface to represent the Cashback contract where tokens can be issued to a recipient.
 */
interface IModuleCashback {
    function issueTokens(address _recipient, bytes32 source) external;
    function isAddressApproved(address module) external view returns (bool);
    function toggleAddressApproval(address address_, bool status) external;
}


/**
 * @title UtilitySales
 * @dev This contract represents a marketplace where different types of services can be listed and purchased.
 * The contract handles the listing, pricing, and purchasing of services, and includes features for handling ERC20 tokens and NFTs.
 */
abstract contract ServiceManager is Cashback {

    /**
     * @dev Enum representing the various types of services that can be listed and purchased in the contract.
     */
    enum ServiceType {
        Permanent,
        OneTime,
        TimeBased,
        NFT,
        ERC20,
        END_OF_LIST // Marker indicating the end of the enum list.
    }

    /**
     * @dev Struct defining the price of a service in terms of a token address and an amount.
     */
    struct Price {
        address tokenAddress;
        uint256 amount;
    }

    /**
     * @dev Struct defining the properties of a service including its name, price, timestamp, duration, tokenAddress, and number.
     */
    struct Service {
        bytes32 hash;
        string name;
        Price price;
        uint256 timestamp;
        uint256 duration;
        address tokenAddress;
        uint256 number;
    }

    // Mapping from a serviceId to an array of Service structs representing the services listed under that id.
    mapping(uint256 => Service[]) internal services;

    // Mapping from a user address to a mapping from a serviceId to an array of Service structs representing the services purchased by that user under that id.
    mapping(address => mapping(uint256 => Service[])) public userPurchasedServices;

    /**
     * @dev Emitted when a service is purchased.
     * @param purchaser The address of the user who purchased the service.
     * @param serviceType The type of the purchased service.
     */
    event ServicePurchased(address indexed purchaser, ServiceType serviceType);
    
    /**
     * @dev Modifier to check whether the provided serviceId is valid.
     */
    modifier validServiceId(uint256 serviceId) {
        require(serviceId < uint(ServiceType.END_OF_LIST), "Invalid service type");
        _;
    }

    /**
     * @dev Internal function to retrieve a service by its name and type (serviceId).
     * @param serviceId The ID representing the type of the service.
     * @param serviceName The name of the service.
     * @return The Service struct representing the found service.
     */
    function _getServiceByNameAndType(uint256 serviceId, string memory serviceName) internal view returns (Service memory) {
        bytes32 serviceNameHash = keccak256(abi.encodePacked(serviceName));
        Service[] memory serviceArray = services[serviceId];
        for(uint i = 0; i < serviceArray.length; i++) {
            if(serviceArray[i].hash == serviceNameHash) {
                return serviceArray[i];
            }
        }
        revert("Service not found");
    }
    
    /**
     * @dev Internal function to handle the purchase of a service, managing the payment and triggering the appropriate events and effects.
     * @param service The Service struct representing the service to be purchased.
     * @param serviceId The ID representing the type of the service to be purchased.
     */
    function _buyService(Service memory service, uint256 serviceId) internal validServiceId(serviceId) {
        uint256 paymentAmount = service.price.amount;
        address paymentToken = service.price.tokenAddress;
        if(paymentToken == address(0)) {
            // If paying with ether
            require(msg.value == paymentAmount, "The amount of ether sent does not match the required amount.");
        } else {
            // If paying with tokens
            IERC20 token = IERC20(paymentToken);
            require(token.balanceOf(msg.sender) >= paymentAmount, "Your token balance is not enough.");
            require(token.allowance(msg.sender, address(_serverContract)) >= paymentAmount, "The contract does not permit the transfer of tokens on behalf of the user.");
            token.transferFrom(msg.sender, address(_serverContract), paymentAmount);
        }

        _purchaseService(msg.sender, service, serviceId);
    }

    /**
     * @dev Internal function to facilitate the purchasing of services listed as ERC20.
     * @param serviceName The name of the service.
     */
    function _buyListedERC20(string memory serviceName) internal {
        uint256 serviceId = uint(ServiceType.ERC20);
        Service memory service = _getServiceByNameAndType(serviceId, serviceName);
        uint256 amount = service.number;
        IERC20 erc20Token = IERC20(service.tokenAddress);
        require(erc20Token.balanceOf(address(this)) >= amount, "Not enough tokens in contract balance");

        _buyService(service, serviceId);
        erc20Token.transfer(msg.sender, amount);
    }
    
    /**
     * @dev Internal function to facilitate the purchasing of services listed as NFT.
     * @param serviceName The name of the service.
     */
    function _buyListedNFT(string memory serviceName) internal {
        uint256 serviceId = uint(ServiceType.NFT);
        Service memory service = _getServiceByNameAndType(serviceId, serviceName);
        uint256 idNft = service.number;
        IERC721 token = _listedNFT(idNft, service);

        _buyService(service, serviceId);
        token.safeTransferFrom(address(this), msg.sender, idNft);
        
        _removeServiceFromList(serviceId, serviceName);
    }
    
    /**
     * @dev Private helper function to ensure the listed NFT is available and valid for purchase.
     * @param idNft The ID of the NFT.
     * @param service The Service struct representing the service to be purchased.
     * @return returnedToken The IERC721 token representing the NFT.
     */
    function _listedNFT(uint256 idNft, Service memory service) private view returns (IERC721 returnedToken) {
        address tokenAddress = service.tokenAddress;
        require(service.price.tokenAddress != address(0), "This service is sold for tokens");
        require(tokenAddress != address(0), "This service has no NFTs for sale");
        require(service.number == idNft, "NFT with such id is not for sale");
        IERC721 tokenInstance = IERC721(tokenAddress);
        require(tokenInstance.ownerOf(idNft) == address(this), "Token is not owned by this contract");
        return tokenInstance;
    }

    /**
     * @dev Private function to handle the logic after a service has been successfully purchased.
     * @param sender The address of the user purchasing the service.
     * @param service The Service struct representing the purchased service.
     * @param serviceId The ID representing the type of the purchased service.
     */
    function _purchaseService(address sender, Service memory service, uint256 serviceId) private {
        userPurchasedServices[sender][serviceId].push(service);

        _giveCashback(sender, service.hash);
        
        emit ServicePurchased(sender, ServiceType(serviceId));
    }

    /**
     * @dev Internal virtual function to remove a service from the listing once it has been purchased.
     * This function is meant to be overridden in derived contracts to implement specific removal logic.
     * @param serviceId The ID representing the type of the purchased service.
     * @param serviceName The name of the service.
     */
    function _removeServiceFromList(uint256 serviceId, string memory serviceName) internal virtual;
}


/**
 * @title UtilityService
 * @dev This contract allows the owner to add and remove services.
 * It inherits from the UtilitySales contract.
 */
abstract contract ServiceManagement is ServiceManager {

    /**
     * @dev Allows the owner to add a Permanent Service payable with Ether.
     * @param serviceName Name of the service.
     * @param payAmount Amount to pay for the service.
     */
    function addServicePermanent(string memory serviceName, uint256 payAmount) public onlyOwner {
        uint256 serviceId = uint(ServiceType.Permanent);
        _addService(serviceId, serviceName, address(0), payAmount, 0, address(0), 0);
    }

    /**
     * @dev Allows the owner to add a Permanent Service payable with Tokens.
     * @param serviceName Name of the service.
     * @param payAmount Amount to pay for the service.
     */
    function addServicePermanentWithTokens(string memory serviceName, address payAddress, uint256 payAmount) public onlyOwner {
        uint256 serviceId = uint(ServiceType.Permanent);
        _addService(serviceId, serviceName, payAddress, payAmount, 0, address(0), 0);
    }

    /**
     * @dev Allows the owner to add a OneTime Service payable with Ether.
     * @param serviceName Name of the service.
     * @param payAmount Amount to pay for the service.
     */
    function addServiceOneTime(string memory serviceName, uint256 payAmount) public onlyOwner {
        uint256 serviceId = uint(ServiceType.OneTime);
        _addService(serviceId, serviceName, address(0), payAmount, 0, address(0), 0);
    }

    /**
     * @dev Allows the owner to add a OneTime Service payable with Tokens.
     * @param serviceName Name of the service.
     * @param payAmount Amount to pay for the service.
     */
    function addServiceOneTimeWithTokens(string memory serviceName, address payAddress, uint256 payAmount) public onlyOwner {
        uint256 serviceId = uint(ServiceType.OneTime);
        _addService(serviceId, serviceName, payAddress, payAmount, 0, address(0), 0);
    }

    /**
     * @dev Allows the owner to add a TimeBased Service payable with Ether.
     * @param serviceName Name of the service.
     * @param payAmount Amount to pay for the service.
     */
    function addServiceTimeBased(string memory serviceName, uint256 payAmount, uint256 duration) public onlyOwner {
        uint256 serviceId = uint(ServiceType.TimeBased);
        _addService(serviceId, serviceName, address(0), payAmount, duration, address(0), 0);
    }

    /**
     * @dev Allows the owner to add a TimeBased Service payable with Tokens.
     * @param serviceName Name of the service.
     * @param payAmount Amount to pay for the service.
     */
    function addServiceTimeBasedWithTokens(string memory serviceName, address payAddress, uint256 payAmount, uint256 duration) public onlyOwner {
        uint256 serviceId = uint(ServiceType.TimeBased);
        _addService(serviceId, serviceName, payAddress, payAmount, duration, address(0), 0);
    }

    /**
     * @dev Allows the owner to add a NFT Service payable with Ether.
     * @param serviceName Name of the service.
     * @param payAmount Amount to pay for the service.
     */
    function addServiceNFT(string memory serviceName, uint256 payAmount, address tokenAddress, uint256 number) public onlyOwner {
        uint256 serviceId = uint(ServiceType.NFT);
        _addService(serviceId, serviceName, address(0), payAmount, 0, tokenAddress, number);
    }

    /**
     * @dev Allows the owner to add a TimNFTeBased Service payable with Tokens.
     * @param serviceName Name of the service.
     * @param payAmount Amount to pay for the service.
     */
    function addServiceNFTWithTokens(string memory serviceName, address payAddress, uint256 payAmount, address tokenAddress, uint256 number) public onlyOwner {
        uint256 serviceId = uint(ServiceType.NFT);
        _addService(serviceId, serviceName, payAddress, payAmount, 0, tokenAddress, number);
    }

    /**
     * @dev Allows the owner to add a ERC20 Service payable with Ether.
     * @param serviceName Name of the service.
     * @param payAmount Amount to pay for the service.
     */
    function addServiceERC20(string memory serviceName, uint256 payAmount, address tokenAddress, uint256 number) public onlyOwner {
        uint256 serviceId = uint(ServiceType.ERC20);
        _addService(serviceId, serviceName, address(0), payAmount, 0, tokenAddress, number);
    }

    /**
     * @dev Allows the owner to add a ERC20 Service payable with Tokens.
     * @param serviceName Name of the service.
     * @param payAmount Amount to pay for the service.
     */
    function addServiceERC20WithTokens(string memory serviceName, address payAddress, uint256 payAmount, address tokenAddress, uint256 number) public onlyOwner {
        uint256 serviceId = uint(ServiceType.ERC20);
        _addService(serviceId, serviceName, payAddress, payAmount, 0, tokenAddress, number);
    }

    /**
     * @dev Removes the specified service from the list of services.
     * @param serviceId The ID of the service type.
     * @param serviceName Name of the service.
     */
    function removeServiceFromList(uint256 serviceId, string memory serviceName) public onlyOwner {
        _removeServiceFromList(serviceId, serviceName);
    }

    /**
     * @dev Internal function to add a service.
     * @param serviceId The ID of the service type.
     * @param moduleName Name of the module.
     * @param payAddress The address to pay to.
     * @param payAmount Amount to pay for the service.
     * @param duration The duration of the service.
     * @param tokenAddress The address of the token contract.
     * @param number The number of tokens.
     */
    function _addService(uint256 serviceId, string memory moduleName, address payAddress, uint256 payAmount, uint256 duration,
      address tokenAddress, uint256 number) private {
        bytes32 hash = keccak256(abi.encodePacked(moduleName));
        services[serviceId].push(Service({
            hash: hash,
            name: moduleName,
            price: Price({
                tokenAddress: payAddress,
                amount: payAmount
            }),
            timestamp: block.timestamp,
            duration: duration,
            tokenAddress: tokenAddress,
            number: number
        }));
        serviceExist[hash] = serviceId++;
    }

    /**
     * @dev Overridden internal function to remove a service from the list.
     * @param serviceId The ID of the service type.
     * @param serviceName Name of the service.
     */
    function _removeServiceFromList(uint256 serviceId, string memory serviceName) internal override {  
        bytes32 hash = keccak256(abi.encodePacked(serviceName));   
        // Find the service index and remove it
        for (uint256 i = 0; i < services[serviceId].length; i++) {
            if (keccak256(abi.encodePacked(services[serviceId][i].name)) == hash) {
                require(i < services[serviceId].length, "Index out of bounds");

                // Move the last element to the spot at index
                services[serviceId][i] = services[serviceId][services[serviceId].length - 1];
        
                // Remove the last element
                services[serviceId].pop();
                serviceExist[hash] = 0;
                break;
            }
        }
    }
}


/**
 * @title SalesProcessing Contract
 * @dev This contract is responsible for handling services' sales, allowing users to purchase services using either Ether or ERC20 tokens.
 * It extends functionalities from ServiceManagement.
 */
abstract contract SalesProcessing is ServiceManagement {

    /**
     * @dev Returns the list of services by ID.
     * @param serviceId The ID of the services.
     * @return An array of services corresponding to the serviceId.
     */
    function getServicesById(uint256 serviceId) public view returns (Service[] memory) {
        return services[serviceId];
    }

    /**
     * @dev Fetches a service based on the serviceId and serviceName.
     * @param serviceId The ID of the service.
     * @param serviceName The name of the service.
     * @return A Service struct representing the found service.
     */
    function getServiceByIdAndName(uint256 serviceId, string memory serviceName) public view returns (Service memory) {
        return _getServiceByNameAndType(serviceId, serviceName);
    }

    /**
     * @dev Allows users to buy a service with Ether.
     * @param serviceId The ID of the service.
     * @param serviceName The name of the service.
     * @notice The function reverts if the service is not sold for Ether.
     */
    function buyService(uint256 serviceId, string memory serviceName) public payable validServiceId(serviceId) {
        _checkBuyServiceId(serviceId, false);
        Service memory service = _getServiceByNameAndType(serviceId, serviceName);
        require(service.price.tokenAddress == address(0), "This service is sold for tokens");
        _buyService(service, serviceId);
    }

    /**
     * @dev Allows users to buy a service with tokens.
     * @param serviceId The ID of the service.
     * @param serviceName The name of the service.
     */
    function buyServiceWithTokens(uint256 serviceId, string memory serviceName) public validServiceId(serviceId) {
        _checkBuyServiceId(serviceId, false);
        Service memory service = _getServiceByNameAndType(serviceId, serviceName);
        _buyService(service, serviceId);
    }
    
    /** 
     * @dev Enables users to buy listed NFT services with Ether.
     * @param serviceName The name of the service.
     */
    function buyListedNFT(string memory serviceName) public payable {
        _buyListedNFT(serviceName);
    }
    
    /**
     * @dev Enables users to buy listed NFT services with tokens.
     * @param serviceName The name of the service.
     */
    function buyListedNFTWithTokens(string memory serviceName) public {
        _buyListedNFT(serviceName);
    }
    
    /**
     * @dev Allows users to purchase listed ERC20 services with Ether.
     * @param serviceName The name of the ERC20 service.
     */
    function buyListedERC20(string memory serviceName) public payable {
        _buyListedERC20(serviceName);
    }

    /**
     * @dev Allows users to purchase listed ERC20 services with tokens.
     * @param serviceName The name of the ERC20 service.
     */
    function buyListedERC20WithTokens(string memory serviceName) public {
        _buyListedERC20(serviceName);
    }

    /**
     * @dev Provides a way to get the service type name by the service ID.
     * @param serviceId The ID of the service type.
     * @return A string representing the name of the service type.
     */
    function getServiceTypeNameById(uint256 serviceId) public pure returns (string memory) {
        string[6] memory serviceTypeNames = [
            "Permanent",
            "OneTime",
            "TimeBased",
            "NFT",
            "ERC20",
            "END_OF_LIST"
        ];
    
        if(serviceId >= uint(ServiceType.END_OF_LIST)) {
            return "Invalid serviceId: Such type does not exist";
        }
    
        return serviceTypeNames[serviceId];
    }

    /**
     * @dev Internal function that validates the provided serviceId depending.
     * @param serviceId The ID of the service to be checked.
     * @param isTokens A boolean value.
     * - If isTokens is false:
     * - It checks whether the serviceId is valid and less than ServiceType.NFT. If not, it reverts with a message indicating that such a service type does not exist for purchases made without tokens.
     * - If isTokens is true:
     * - It checks whether the serviceId is valid, greater than or equal to ServiceType.NFT, and less than ServiceType.END_OF_LIST. If not, it reverts with a message indicating that such a service type does not exist for purchases made with tokens.
     * This function ensures that only valid service IDs are processed, providing an additional layer of security and data integrity for service purchases.
      */
    function _checkBuyServiceId(uint256 serviceId, bool isTokens) private pure {
        if (!isTokens) {
            if(serviceId >= uint(ServiceType.NFT)) {
                revert("Invalid serviceId: Such type does not exist");
            }
        } else {
            if(serviceId >= uint(ServiceType.END_OF_LIST) || serviceId < uint(ServiceType.NFT)) {
                revert("Invalid serviceId: Such type does not exist");
            }
        }
    }
}


interface IAGEModule {
    
    // Enum declaration for ModuleType
    enum ModuleType {
        Server,
        Token,
        NFT,
        Shop,
        Voting,
        Lottery,
        Raffle,
        Game,
        Advertisement,
        AffiliateProgram,
        Event,
        RatingSystem,
        SocialFunctions,
        Auction,
        Charity
    }

    // External functions
    function getServerContract() external view returns (address);
    function getModuleName() external view returns (string memory);
    function getModuleType() external view returns (ModuleType);
    function getModuleTypeString() external view returns (string memory);
    function getModuleFactory() external view returns (address);
}

/**
 * @title SalesModule Contract
 * @dev This contract handles various sales functionalities.
 */
contract SalesModule is SalesProcessing, FinanceManager, ERC20Receiver, IAGEModule {

    string private constant moduleName = "SalesModule";
    ModuleType private constant moduleType = ModuleType.Shop;
    string private constant moduleTypeString = "Shop";

    constructor(address serverContract_, address factoryContractAddress) Cashback(serverContract_, factoryContractAddress) {
        supportedInterfaces[type(IAGEModule).interfaceId] = true;
        supportedInterfaces[type(IERC721Receiver).interfaceId] = true;
        erc1820Registry.setInterfaceImplementer(address(this), keccak256("IAGEModule"), address(this));
        erc1820Registry.setInterfaceImplementer(address(this), keccak256("ERC721Receiver"), address(this));
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
}



/**
 * @title FactorySalesModule
 * @dev This contract, FactorySalesModule, is utilized for the creation and management of 
 *      SalesModule contracts. It allows for the dynamic deployment of new modules and their 
 *      removal when necessary, coordinating storage and management of the contracts.
 */
contract FactorySalesModule is BaseUtility {

    /**
     * @dev List of addresses of deployed modules.
     */
    address[] internal deployedModules;

    /**
     * @dev Mapping that links the server contract addresses to the deployed module addresses.
     */
    mapping(address => address) public isDeploy;

    /**
     * @dev Event emitted when a new module is created.
     */
    event SalesModuleCreated(address indexed moduleAddress, address indexed server, address indexed owner);

    /**
     * @dev Modifier to restrict the deployment of modules.
     */
    modifier onlyAllowed(address serverContractAddress) {
        require(!_proxyContract().isStopped(), "FactorySalesModule: Deploying is stopped");
        require(msg.sender == _proxyContract().implementation(), "FactorySalesModule: Caller is not the implementation");
        require(isDeploy[serverContractAddress] == address(0), "FactorySalesModule: This server has already deployed this module");
        _;
    }

    /**
     * @dev Function to deploy a new SalesModule.
     * @param serverContractAddress Address of the associated server contract.
     * @param ownerAddress Address of the new owner of the deployed module.
     * @return Address of the deployed SalesModule.
     */
    function deployModule(string memory, string memory,
            address serverContractAddress, address ownerAddress)
                public onlyAllowed(serverContractAddress) returns (address) {

        SalesModule newModule = new SalesModule(serverContractAddress, address(this));
        if (ownerAddress != address(0)) {
            newModule.transferOwnership(ownerAddress);
        }
        
        isDeploy[serverContractAddress] = address(newModule);
        deployedModules.push(serverContractAddress);
        
        emit SalesModuleCreated(address(newModule), serverContractAddress, ownerAddress);
        
        return address(newModule);
    }

    /**
     * @dev Function to remove a deployed SalesModule associated with a server contract.
     * @param serverContractAddress Address of the associated server contract.
     */
    function removeModule(address serverContractAddress) external {
        require(msg.sender == isDeploy[serverContractAddress], "FactorySalesModule: Module not deployed for this server");

        delete isDeploy[serverContractAddress]; 
    }

    /**
     * @dev Function to get the number of deployed modules.
     * @return Number of deployed modules.
     */
    function getAmountOfDeployedModules() public view returns (uint256) {
        return deployedModules.length;
    }

    /**
     * @dev Function to get the list of deployed modules.
     * @return Array of addresses of deployed modules.
     */
    function getDeployedModules() public view returns (address[] memory) {
        return deployedModules;
    }

    /**
     * @dev Function to retrieve a subset of the deployed modules between given indices.
     * @param startIndex Start index of the subset.
     * @param endIndex End index of the subset.
     * @return Array of addresses of deployed modules in the specified range.
     */
    function getDeployedModules(uint256 startIndex, uint256 endIndex) public view returns (address[] memory) {
        require(startIndex < deployedModules.length, "FactorySalesModule: Start index out of bounds");
    
        if(endIndex >= deployedModules.length) {
            endIndex = deployedModules.length - 1;
        }
    
        uint256 length = endIndex - startIndex + 1;
        address[] memory result = new address[](length);
    
        for (uint256 i = 0; i < length; i++) {
            result[i] = deployedModules[startIndex + i];
        }
    
        return result;
    }

    receive() external payable {
        payable(_proxyContract().implementation()).transfer(msg.value);
    }
}

