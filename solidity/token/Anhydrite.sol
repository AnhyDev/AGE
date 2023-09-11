// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/*
 * Copyright (C) 2023 Anhydrite Gaming Ecosystem
 *
 * This code is part of the Anhydrite Gaming Ecosystem.
 *
 * ERC-20 Token: Anhydrite ANH
 * Network: Binance Smart Chain
 * Website: https://anh.ink
 *
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that explicit attribution to the original code and website
 * is maintained. For detailed terms, please contact the Anhydrite Gaming Ecosystem team.
 *
 * This code is provided as-is, without warranty of any kind, express or implied,
 * including but not limited to the warranties of merchantability, fitness for a 
 * particular purpose, and non-infringement. In no event shall the authors or 
 * copyright holders be liable for any claim, damages, or other liability, whether 
 * in an action of contract, tort, or otherwise, arising from, out of, or in connection 
 * with the software or the use or other dealings in the software.
 */


/*
 * IANHReceiver Interface:
 * - Purpose: To handle the receiving of ERC-20 tokens from another smart contract.
 * - Key Method: 
 *   - `onERC20Received`: This is called when tokens are transferred to a smart contract implementing this interface.
 *                        It allows for custom logic upon receiving tokens.
 */

// Interface for contracts that are capable of receiving ERC20 (ANH) tokens.
interface IANHReceiver {
    // Function that is triggered when ERC20 (ANH) tokens are received.
    function onERC20Received(address _from, address _who, uint256 _amount) external returns (bytes4);

    // An event to track from which address the tokens were transferred, who transferred, to which address and the number of tokens
    event ChallengeIERC20Receiver(address indexed from, address indexed who, address indexed token, uint256 amount);
}

/*
 * Anhydrite Contract:
 * - Inherits From: FinanceManager, TokenManager, ProxyManager, OwnableManager, ERC20, ERC20Burnable, IERC20Receiver.
 * - Purpose: Provides advanced features to a standard ERC-20 token including token minting, burning, and ownership voting.
 * - Special Features:
 *   - Sets a maximum supply limit of 360 million tokens.
 *   - Custom logic for transferring tokens to contracts that implement the IERC20Receiver interface.
 * - Key Methods:
 *   - `getMaxSupply`: Returns the maximum allowed supply of tokens.
 *   - `transferForProxy`: Only allows a proxy smart contract to initiate token transfers.
 *   - `_transferFor`: Checks and performs token transfers, and mints new tokens if necessary, but not exceeding max supply.
 *   - `_onERC20Received`: Handles the receipt of ERC-20 tokens.
 *   - `_mint`: Enforces the max supply limit when minting tokens.
 * - Events:
 *   - `AnhydriteTokensReceivedProcessed`: Emitted after processing tokens received.
 */

contract Anhydrite is FinanceManager, TokenManager, ProxyManager, OwnableManager, WhiteListManager, ERC20, ERC20Burnable, IANHReceiver {
    using ERC165Checker for address;

    // Sets the maximum allowed supply of tokens is 360 million
    uint256 private constant MAX_SUPPLY = 360000000 * 10 ** 18;
    // The magic identifier for the ability in the external contract to cancel the token acquisition transaction
    bytes4 private ANHReceiverMagic;

    // Confirm receipt and handling of Anhydrite tokens by external IERC20Receiver contract
    event AnhydriteTokensReceivedProcessed(address indexed from, address indexed who, address indexed receiver, uint256 amount, bool processed);
    // An event to log the return of Anhydrite tokens to this smart contract
    event ReturnOfAnhydrite(address indexed from, address indexed who, uint256 amount);
    // An event about an exception that occurred during the execution of an external contract
    event ExceptionInfo(address indexed to, string exception, bytes);

    constructor() ERC20("Anhydrite", "ANH") {
        _mint(address(this), 70000000 * 10 ** decimals());
        ANHReceiverMagic = IANHReceiver(address(this)).onERC20Received.selector;
        _whiteList[address(this)] = true;
   }

    // Returns the maximum token supply allowed
    function getMaxSupply() public pure returns (uint256) {
        return MAX_SUPPLY;
    }

    // Sending tokens on request from the smart contract proxy to its address
    function transferForProxy(uint256 amount) public {
        require(address(_proxyContract) != address(0), "Anhydrite: The proxy contract has not yet been established");
        address proxy = address(_proxyContract);
        require(msg.sender == proxy, "Anhydrite: Only a proxy smart contract can activate this feature");
        _transferFor(proxy, amount);
    }

    // Implemented _transferFor function checks token presence, sends to recipient, and mints new tokens if necessary, but not exceeding max supply.
    function _transferFor(address recepient, uint256 amount) internal override {
        if (balanceOf(address(this)) >= amount) {
            _transfer(address(this), recepient, amount);
        } else if (totalSupply() + amount <= MAX_SUPPLY && recepient != address(0)) {
            _mint(recepient, amount);
        } else {
            revert("Anhydrite: Cannot transfer or mint the requested amount");
        }
    }

 /*
  * Private Function: _onERC20Received
  * - Purpose: Verifies if the receiving contract complies with the IANHReceiver interface and triggers corresponding events.
  * - Arguments:
  *   - _from: The origin address of the ERC-20 tokens.
  *   - _to: The destination address of the ERC-20 tokens.
  *   - _amount: The quantity of tokens being transferred.
  * 
  * - Behavior:
  *   1. If `_to` is a smart contract and implements IANHReceiver, this function invokes its `onERC20Received` method.
  *   2. If the external contract returns the correct "magic" identifier, the token receipt is considered successful.
  *   3. If `_to` is not a contract or does not implement IANHReceiver, no action is taken except logging the tokens as unprocessed.
  *   4. If an exception occurs in the external contract's `onERC20Received` method, the token receipt is considered unsuccessful and logged.
  *
  * - Events:
  *   - AnhydriteTokensReceivedProcessed: Triggered to indicate whether the tokens were successfully.
  *   - ExceptionInfo: Triggered when an exception occurs in the receiving contract's `onERC20Received` method, logging the reason for failure.
  */
    function _onERC20Received(address _from, address _to, uint256 _amount) private {
	    if (Address.isContract(_to)) {
            if (_whiteList[msg.sender]) {
	            try IANHReceiver(_to).onERC20Received(_from, msg.sender, _amount) returns (bytes4 retval) {
	                require(retval == ANHReceiverMagic, "Anhydrite: An invalid magic ID was returned");
                    emit AnhydriteTokensReceivedProcessed(_from, msg.sender, _to, _amount, true);
	            } catch Error(string memory reason) {
                    emit ExceptionInfo(_to, reason, new bytes(0));
	            } catch (bytes memory lowLevelData) {
                    emit ExceptionInfo(_to, "Another error.", lowLevelData);
	            }
            } else {
                emit AnhydriteTokensReceivedProcessed(_from, msg.sender, _to, _amount, false);
            }
	    }
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

    /*
     * Overridden Function: _mint
     * Extends the original _mint function from the ERC20 contract to include a maximum supply limit.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        require(totalSupply() + amount <= MAX_SUPPLY, "Anhydrite: MAX_SUPPLY limit reached");
        super._mint(account, amount);
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
     *   - ReturnOfAnhydrite: Emitted when tokens are received from this contract itself.
     *   - DepositERC20: Emitted when other tokens of the EPC-20 standard are received
     */
    function onERC20Received(address _from, address _who, uint256 _amount) external override returns (bytes4) {
        bytes4 fakeID = bytes4(keccak256("anything_else"));
        bytes4 validID = this.onERC20Received.selector;
        bytes4 returnValue = fakeID;  // Default value
        if (Address.isContract(msg.sender)) {
            if (msg.sender == address(this)) {
                emit ReturnOfAnhydrite(_from, _who, _amount);
                returnValue = validID;
            }else {
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

    // Setting which smart contract overrides the transferOwnership function
    function transferOwnership(address proposedOwner) public override (Ownable, OwnableManager) {
        OwnableManager.transferOwnership(proposedOwner);
    }
}

