// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

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

interface IERC20Receiver {
	/* Interface to add the ability for the external contract to handle the receive token event.
	 * For this, the external contract must inheritance the IERC20Receiver interface and implement the function
	 * function onERC20Received(address _from, address _who, uint256 _amount) external returns (bytes4);
	 * In the body of this function, process the event and send back the magic ID of the interface.
	 *
	 * If the contract does not implement the IERC20Receiver interface, or if the event handling throws an exception
	 * this function will be ignored and the transaction will continue.
	 *
	 * In order to roll back the entire transaction, the outer contract must return false
	 * magic id.
	 *
	 * Valid magic ID: return bytes4(keccak256("onERC20Received(address,address,uint256)"));
	 * Invalid magic ID: return bytes4(keccak256("anything_else"));
	 */
	
    function onERC20Received(address _from, address _who, uint256 _amount) external returns (bytes4);
}