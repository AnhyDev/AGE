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

// @filepath Repository Location: [solidity/global/proxy/Proxy.sol]

pragma solidity ^0.8.19;

import "./BaseProxy.sol";

// Proxy is an abstract contract that implements the IProxy interface and adds utility and ownership functionality.
abstract contract Provider is IProxy, BaseProxy {

    // Function to forward Ether received to the implementation contract
    receive() external payable {
        address payable recipient = payable(address(ANHYDRITE));
        recipient.transfer(msg.value);
    }

    // Returns the address of the implementation contract
    function implementation() external override view returns (address) {
        return _implementation();
    }

    // Checks if the contract's basic functions are stopped
    function isStopped() external override view returns (bool) {
        return _stopped;
    }

    // Returns the total number of owners
    function getTotalOwners() external override view returns (uint256) {
        return _totalOwners;
    }

    // Checks if an address is a proxy owner (has voting rights)
    function isProxyOwner(address ownerAddress) external override view returns (bool) {
        return _isProxyOwner(ownerAddress);
    }

    // Checks if an address is an owner
    function isOwner(address account) external override view returns (bool) {
        return _owners[account];
    }

    // Returns the balance of an owner
    function getBalanceOwner(address owner) external override view returns (uint256) {
        return _balanceOwner[owner];
    }

    // Returns the number of tokens needed to become an owner
    function getTokensNeededForOwnership() external override view returns (uint256) {
        return _tokensNeededForOwnership;
    }

    // Checks if an address is blacklisted
    function isBlacklisted(address account) external override view returns (bool) {
        return _blackList[account];
    }

    // Increases interest for voting participants
    function increase(address[] memory addresses) external {
        require(msg.sender == address(ANHYDRITE), "Proxy: This is a disabled feature for you");
        for (uint256 i = 0; i < addresses.length; i++) {
            _increaseByPercent(addresses[i]);
        }
    }
}
