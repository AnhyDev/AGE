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

//import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title BaseUtil Contract
 * @dev This is an abstract contract that provides utility functions for interaction with the Anhydrite (ANH) and its proxy contract.
 * It's meant to be inherited by other contracts that require access to the proxy contract owners and their voting rights.
 *
 * Functions:
 * - _getProxyAddress: Returns the proxy contract address from the Anhydrite contract.
 * - _proxyContract: Returns an instance of the proxy contract.
 */
abstract contract BaseUtility {
    
    // Main project token (ANH) address
    IANH internal constant ANHYDRITE = IANH(0x47E0CdCB3c7705Ef6fA57b69539D58ab5570799F);

    IERC1820Registry constant internal erc1820Registry = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    // Returns an instance of the proxy contract.
    function _proxyContract() internal view returns(IProxy) {
        return IProxy(_getProxyAddress());
    }

    // Returns the proxy contract address from the Anhydrite contract.
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
    // Returns the total number of owners
    function isProxyOwner(address tokenAddress) external view returns (bool);
    // Checks if the contract is stopped
    function isStopped() external view returns (bool);

// interface IAGE 
    function getPrice(string memory name) external view returns (uint256);
}

abstract contract FinanceManager is Ownable {

   /// @notice Function for transferring Ether
    function transferMoney(address payable recipient, uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "FinanceManager: Contract has insufficient balance");
        recipient.transfer(amount);
    }

    /// @notice Function for transferring ERC20 tokens
    function transferERC20Tokens(address _tokenAddress, address _to, uint256 _amount) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        require(token.balanceOf(address(this)) >= _amount, "FinanceManager: Not enough tokens on contract balance");
        token.transfer(_to, _amount);
    }

    /// @notice Function for transferring ERC721 tokens
    function transferERC721Token(address _tokenAddress, address _to, uint256 _tokenId) external onlyOwner {
        IERC721 token = IERC721(_tokenAddress);
        require(token.ownerOf(_tokenId) == address(this), "FinanceManager: The contract is not the owner of this token");
        token.safeTransferFrom(address(this), _to, _tokenId);
    }

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

/*
 * ERC20Receiver Contract:
 * - Inherits From: IERC20Receiver, ERC20
 * - Purpose: To handle incoming ERC-20 tokens and trigger custom logic upon receipt.
 * - Special Features:
 *   - Verifies the compliance of receiving contracts with the IERC20Receiver interface.
 *   - Uses the ERC1820 Registry to identify contracts that implement the IERC20Receiver interface.
 *   - Safely calls `onERC20Received` on the receiving contract and logs any exceptions.
 *   - Extends the standard ERC20 `_afterTokenTransfer` function to incorporate custom logic.
 * 
 * - Key Methods:
 *   - `_onERC20Received`: Internal function to verify and trigger `onERC20Received` on receiving contracts.
 *   - `_afterTokenTransfer`: Overridden from ERC20 to add additional behavior upon token transfer.
 *   - `onERC20Received`: Implements the IERC20Receiver interface, allowing the contract to handle incoming tokens.
 * 
 * - Events:
 *   - TokensReceivedProcessed: Logs successful processing of incoming tokens by receiving contracts.
 *   - ExceptionInfo: Logs exceptions during the execution of `onERC20Received` on receiving contracts.
 *   - ReturnOfThisToken: Logs when tokens are received from this contract itself.
 * 
 */
abstract contract ERC20Receiver is IERC20Receiver, ERC20Burnable, BaseUtility, ERC165 {

    // The magic identifier for the ability in the external contract to cancel the token acquisition transaction
    bytes4 private ERC20ReceivedMagic;

    // An event to track from which address the tokens were transferred, who transferred, to which address and the number of tokens
    event ChallengeIERC20Receiver(address indexed from, address indexed who, address indexed token, uint256 amount);
    // An event to log the return of Anhydrite tokens to this smart contract
    event ReturnOfMainToken(address indexed from, address indexed who, address indexed thisToken, uint256 amount);
    // An event about an exception that occurred during the execution of an external contract 
    event ExceptionInfo(address indexed to, string exception);


    constructor() {
        ERC20ReceivedMagic = IERC20Receiver(address(this)).onERC20Received.selector;
        supportedInterfaces[type(IERC20Receiver).interfaceId] = true;
        erc1820Registry.setInterfaceImplementer(address(this), keccak256("ERC20Token"), address(this));
        erc1820Registry.setInterfaceImplementer(address(this), keccak256("IERC20Receiver"), address(this));
    }

    /*
     * Overridden Function: onERC20Received
     * - Purpose: Implements the onERC20Received function from the IERC20Receiver interface to handle incoming ERC-20 tokens.
     * - Arguments:
     *   - _from: The sender of the ERC-20 tokens.
     *   - _who: Indicates the original sender for forwarded tokens (useful in case of proxy contracts).
     *   - _amount: The amount of tokens being sent.
     * 
     * - Behavior:
     *   1. If the message sender is this contract itself, it emits a ReturnOfAnhydrite event and returns the method selector for onERC20Received, effectively acknowledging receipt.
     *   2. If the message sender is not this contract, it returns a different bytes4 identifier, which signifies the tokens were not properly processed as per IERC20Receiver standards.
     * 
     * - Returns:
     *   - The function returns a "magic" identifier (bytes4) that confirms the execution of the onERC20Received function.
     *
     * - Events:
     *   - ReturnOfMainToken: Emitted when tokens are received from this contract itself.
     *   - DepositERC20: Emitted when other tokens of the EPC-20 standard are received
     */
    function onERC20Received(address _from, address _who, uint256 _amount) external override returns (bytes4) {
        bytes4 fakeID = bytes4(keccak256("anything_else"));
        bytes4 validID = ERC20ReceivedMagic;
        bytes4 returnValue = fakeID;  // Default value
        if (msg.sender.code.length > 0) {
            if (msg.sender == address(this)) {
                emit ReturnOfMainToken(_from, _who, address(this), _amount);
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

    // An abstract function for implementing a whitelist to handle trusted contracts with special logic.
    // If this is not required, implement a simple function that always returns false
    function _checkWhitelist(address checked) internal view virtual returns (bool);

    /*
     * Private Function: _onERC20Received
     * - Purpose: Handles the receipt of ERC20 tokens, checking if the receiver implements IERC20Receiver or is whitelisted.
     * - Arguments:
     *   - _from: The sender's address of the ERC-20 tokens.
     *   - _to: The recipient's address of the ERC-20 tokens.
     *   - _amount: The quantity of tokens to be transferred.
     * 
     * - Behavior:
     *   1. Checks if `_to` is a contract by examining the length of its bytecode.
     *   2. If `_to` is whitelisted, it calls the `onERC20Received` method on `_to`, requiring a magic value to be returned.
     *   3. Alternatively, if `_to` is an IERC20Receiver according to the ERC1820 registry, it calls the `_difficultChallenge` method.
     *   4. If none of these conditions are met, the function simply exits, effectively treating `_to` as a regular address.
     */
    function _onERC20Received(address _from, address _to, uint256 _amount) private {
        if (_to.code.length > 0) {
            if (_checkWhitelist(_to)) {
	            bytes4 retval = IERC20Receiver(_to).onERC20Received(_from, msg.sender, _amount);
                require(retval == ERC20ReceivedMagic, "ERC20Receiver: An invalid magic ID was returned");
            } else if (_or1820RegistryReturnIERC20Received(_to)) {
	            _difficultChallenge(_from, _to, _amount);
            }
        }
	}

    /*
     * Internal Function: _difficultChallenge
     * - Purpose: Calls the `onERC20Received` function of the receiving contract and logs exceptions if they occur.
     * - Arguments:
     *   - _from: The origin address of the ERC-20 tokens.
     *   - _to: The destination address of the ERC-20 tokens.
     *   - _amount: The quantity of tokens being transferred.
     *   
     * - Behavior:
     *   1. A try-catch block attempts to call the `onERC20Received` function on the receiving contract `_to`.
     *   2. If the call succeeds, the returned magic value is checked.
     *   3. If the call fails, an exception is caught and the reason is emitted in an ExceptionInfo event.
     */
    function _difficultChallenge(address _from, address _to, uint256 _amount) private {
        bytes4 retval;
        bool callSuccess;
        try IERC20Receiver(_to).onERC20Received(_from, msg.sender, _amount) returns (bytes4 _retval) {
	        retval = _retval;
            callSuccess = true;
	    } catch Error(string memory reason) {
            emit ExceptionInfo(_to, reason);
	    } catch (bytes memory lowLevelData) {
            string memory infoError = "Another error";
            if (lowLevelData.length > 0) {
                infoError = string(lowLevelData);
            }
            emit ExceptionInfo(_to, infoError);
	    }
        if (callSuccess) {
            require(retval == ERC20ReceivedMagic, "ERC20Receiver: An invalid magic ID was returned");
        }
    }

    /*
     * Internal View Function: _or1820RegistryReturnIERC20Received
     * - Purpose: Checks if the contract at `contractAddress` implements the IERC20Receiver interface according to the ERC1820 registry.
     * - Arguments:
     *   - contractAddress: The address of the contract to check.
     * 
     * - Returns: 
     *   - A boolean indicating whether the contract implements IERC20Receiver according to the ERC1820 registry.
     */
    function _or1820RegistryReturnIERC20Received(address contractAddress) internal view virtual returns (bool) {
        return erc1820Registry.getInterfaceImplementer(contractAddress, keccak256("IERC20Receiver")) == contractAddress;
    }

    /*
     * Public View Function: check1820Registry
     * - Purpose: External interface for checking if a contract implements the IERC20Receiver interface via the ERC1820 registry.
     * - Arguments:
     *   - contractAddress: The address of the contract to check.
     * 
     * - Returns:
     *   - A boolean indicating the ERC1820 compliance of the contract.
     */
    function check1820RegistryIERC20Received(address contractAddress) external view returns (bool) {
        return _or1820RegistryReturnIERC20Received(contractAddress);
    }

    /*
     * Overridden Function: _afterTokenTransfer
     * - Purpose: Extends the original _afterTokenTransfer function by additionally invoking _onERC20Received when recepient are not the zero address.
     * - Arguments:
     *   - from: The sender's address.
     *   - to: The recipient's address.
     *   - amount: The amount of tokens being transferred.
     *
     * - Behavior:
     *   1. If the recipient's address (`to`) is not the zero address, this function calls the internal method _onERC20Received.
     *
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        if(to != address(0)) {
            _onERC20Received(from, to, amount);
        }
    }
}
/*
 * IERC1820Registry defines the interface for the ERC1820 Registry contract,
 * which allows contracts and addresses to declare which interface they implement
 * and which smart contract is responsible for its implementation.
 */
interface IERC1820Registry {

    // Allows `account` to specify `implementer` as the entity that implements
    // a particular interface identified by `interfaceHash`.
    // This can only be called by the `account` itself.
    function setInterfaceImplementer(address account, bytes32 interfaceHash, address implementer) external;

    // Retrieves the address of the contract that implements a specific interface
    // identified by `interfaceHash` for `account`.
    function getInterfaceImplementer(address account, bytes32 interfaceHash) external view returns (address);
}


interface ICashback {
    function issueTokens(address _recipient, bytes32 source) external;
    function isAddressApproved(address module) external view returns (bool);
    function toggleAddressApproval(address address_, bool status) external;
}
/**
 * @title Cashback
 * @dev This is an abstract contract implementing base functionality for a Cashback system,
 * utilizing an ERC721 based server contract represented by the IServer interface.
 */
abstract contract Cashback is ICashback, ERC20Receiver, Ownable {

    IServer internal _serverContract;

    //mapping(bytes32 => uint256) internal _cashback;
    mapping(address => bool) internal _approvedTokenRequestAddresses;

    constructor(address serverAddress) {
        _serverContract = IServer(serverAddress);
        supportedInterfaces[type(ICashback).interfaceId] = true;
        erc1820Registry.setInterfaceImplementer(address(this), keccak256("ICashback"), address(this));
    }

    /**
     * @dev Issues tokens to a recipient if the calling address is approved and source of cashback is valid.
     * @param _recipient The address to receive the issued tokens.
     * @param source The bytes32 representing the source of cashback.
     */
    function issueTokens(address _recipient, bytes32 source) external override {
        require(_isAddressApproved(msg.sender), "Cashback: Address not approved to request tokens");
        (/*address moduleAddress*/, uint256 amount) = _serverContract.getCashback(source);
        _giveTokens(_recipient, amount);
    }

    /**
     * @dev Checks whether the message sender is approved for the specified amount.
     * @param module The amount to check approval for.
     * @return bool True if the message sender is approved, false otherwise.
     */
    function isAddressApproved(address module) external view override returns (bool) {
        return _isAddressApproved(module);
    }
    function _isAddressApproved(address module) internal view returns (bool) {
        return _approvedTokenRequestAddresses[module];
    }

    /**
     * @dev Toggles the approval status for a specific address.
     * This can be called by the contract owner to approve or disapprove an address,
     * or by an already approved address to disapprove itself.
     * 
     * @param address_ The address for which to toggle the approval status.
     * @param status The desired approval status.
     *
     * Requirements:
     * - The caller must be the contract owner, or the address itself wishing to disapprove its own approval.
     * - If the caller is the address itself, it can only disapprove its approval (cannot approve itself).
     * 
     * Emits a revert if the caller doesn't have the right permissions to change the approval.
     */
    function toggleAddressApproval(address address_, bool status) external override {
        if (msg.sender == owner()
            || (address_ == msg.sender && _approvedTokenRequestAddresses[address_]) && !status) {
            _approvedTokenRequestAddresses[address_] = status;
        } else {
            revert("Cashback: You do not have permission to change the permission");
        }
        
    }

    /**
     * @dev Converts a string to a bytes32 hash, used as a key for cashback values.
     * @param source The source string to convert.
     * @return result The resulting bytes32 hash.
     */
    function _stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes32 keyHash = keccak256(abi.encodePacked(source));
        return keyHash;
    }

    /**
     * @dev Abstract function to be overridden, used for implementing token distribution logic.
     * @param recipient The recipient of the tokens.
     * @param amount The amount of tokens to distribute.
     */
    function _giveTokens(address recipient, uint256 amount) internal virtual;
}

/**
 * @title IServer
 * @dev This is an interface contract inheriting IERC721 and IERC721Metadata interfaces.
 * It represents the contract interface for an ERC721 based server.
 */
interface IServer is IERC721, IERC721Metadata {
    function getCashback(bytes32 source) external view returns (address, uint256);
}


/**
 * @title CashbackModule
 * @dev This contract extends the abstract Cashback contract, utilizing the ERC20Receiver
 * to implement specific functionality for distributing tokens.
 */
contract TokenCashback is Cashback, FinanceManager {
    
    address private _factoryContractAddress;
    
    constructor(address serverAddress, address factoryContractAddress) Cashback(serverAddress) ERC20(
            string(abi.encodePacked("TokenCashback ", _serverContract.name())),
                string(abi.encodePacked(_serverContract.symbol(), "CT"))) {
        
        _factoryContractAddress = factoryContractAddress;
        _mint(owner(), 1000 * 10 ** decimals());
    }
    
    /**
     * @dev Retrieves the server contract implementing the IServer interface.
     * @return IServer The server contract.
     */
    function getServerContract() external view returns (IServer) {
        return _serverContract;
    }

    /**
     * @dev Removes the associated server contract. 
     * Can only be called by the factory contract.
     * Requirements:
     * - The caller must be the factory contract.
     */
    function removeServerContract() external {
        require(msg.sender == _factoryContractAddress, "TokenCashback: Only the factory contract can call this function");
        delete _serverContract;
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
        return ANHYDRITE.isinWhitelist(checked);
    }
}


/**
 * @title FactoryTokenCashback
 * @dev This contract, FactoryTokenCashback, is utilized for the creation and management of 
 *      TokenCashback contracts. It allows for the dynamic deployment of new modules and their 
 *      removal when necessary, coordinating storage and management of the contracts.
 */
contract FactoryTokenCashback is BaseUtility {

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
    event TokenCashbackCreated(address indexed moduleAddress, address indexed server, address indexed owner);

    /**
     * @dev Modifier to restrict the deployment of modules.
     */
    modifier onlyAllowed(address serverContractAddress) {
        require(!_proxyContract().isStopped(), "FactoryTokenCashback: Deploying is stopped");
        require(msg.sender == _proxyContract().implementation(), "FactoryTokenCashback: Caller is not the implementation");
        require(isDeploy[serverContractAddress] == address(0), "FactoryTokenCashback: This server has already deployed this module");
        _;
    }

    /**
     * @dev Function to deploy a new CashbackModule.
     * @param serverContractAddress Address of the associated server contract.
     * @param ownerAddress Address of the new owner of the deployed module.
     * @return Address of the deployed CashbackModule.
     */
    function deployModule(string memory, string memory,
            address serverContractAddress, address ownerAddress)
                public onlyAllowed(serverContractAddress) returns (address) {

        TokenCashback newModule = new TokenCashback(serverContractAddress, address(this));
        if (ownerAddress != address(0)) {
            newModule.transferOwnership(ownerAddress);
        }
        
        isDeploy[serverContractAddress] = address(newModule);
        deployedModules.push(serverContractAddress);
        
        emit TokenCashbackCreated(address(newModule), serverContractAddress, ownerAddress);
        
        return address(newModule);
    }

    /**
     * @dev Function to remove a deployed TokenCashback associated with a server contract.
     * @param serverContractAddress Address of the associated server contract.
     */
    function removeModule(address serverContractAddress) external {
        address moduleAddress = isDeploy[serverContractAddress];
        require(moduleAddress != address(0), "FactoryTokenCashback: Module not deployed for this server");
    
        TokenCashback module = TokenCashback(moduleAddress);
        require(msg.sender == address(module.getServerContract()), "FactoryTokenCashback: Only the associated server contract can call this function");

        module.removeServerContract();
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
        require(startIndex < deployedModules.length, "FactoryTokenCashback: Start index out of bounds");
    
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
}

