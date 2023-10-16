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
 
// @filepath Repository Location: [solidity/common/ERC20ReceiverToken.sol]

pragma solidity ^0.8.19;

import "../openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../openzeppelin/contracts/interfaces/IERC165.sol";
import "../interfaces/IERC1820Registry.sol";
import "../interfaces/IERC20Receiver.sol";
import "./BaseUtility.sol";

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
abstract contract ERC20ReceiverToken is IERC20Receiver, ERC20, ERC20Burnable, BaseUtility, IERC165 {

    // The magic identifier for the ability in the external contract to cancel the token acquisition transaction
    bytes4 private ERC20ReceivedMagic;

    // An event to track from which address the tokens were transferred, who transferred, to which address and the number of tokens
    event ChallengeIERC20Receiver(address indexed from, address indexed who, address indexed token, uint256 amount);
    // An event to log the return of Anhydrite tokens to this smart contract
    event ReturnOfMainToken(address indexed from, address indexed who, address indexed thisToken, uint256 amount);
    // An event about an exception that occurred during the execution of an external contract 
    event ExceptionInfo(address indexed to, string exception);


    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        ERC20ReceivedMagic = IERC20Receiver(address(this)).onERC20Received.selector;
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
     * External View Function: check1820Registry
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
    
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override virtual returns (bool) {
        return interfaceId == type(IERC20Receiver).interfaceId;
    }
}