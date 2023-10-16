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

// @filepath Repository Location: [solidity/global/owners/BaseMain.sol]

pragma solidity ^0.8.19;

import "../../openzeppelin/contracts/interfaces/IERC165.sol";
import "../../interfaces/IAGE.sol";
import "../../common/BaseAnh.sol";


abstract contract BaseMain is BaseAnh {
	
    // Service status flags
    bool internal _stopped = false;

    // Global contract (AGE) address
    address internal _implementationAGE;

    // Tokens required for ownership rights
    uint256 internal _tokensNeededForOwnership;

    // The total number of owners
    uint256 internal _totalOwners;

    // Owner status mapping
    mapping(address => bool) internal _owners;

    // Owner token balance mapping
    mapping(address => uint256) internal _balanceOwner;

    // Owners under exclusion vote
    mapping(address => bool) internal _isOwnerVotedOut;

    // Blacklisted addresses
    mapping(address => bool) internal _blackList;

    function _getMain() internal view override virtual returns(address) {
        return address(this);
    }

    // Validates owner's voting rights
    function _isMainOwner(address ownerAddress) internal view override virtual returns (bool) {
        return _owners[ownerAddress] 
        && !_isOwnerVotedOut[ownerAddress]
        && _balanceOwner[ownerAddress] >= _tokensNeededForOwnership;
    }

    // A modifier that checks whether an address is in the list of owners, and whether a vote for exclusion is open for this address
    modifier proxyOwner() {
        require(_isMainOwner(msg.sender), "BaseMain: Not an owner");
        _;
    }

    // Checks if a contract implements a specific IAGE interface
    function _checkContract(address contractAddress) internal view returns (bool) {
        return IERC165(contractAddress).supportsInterface(type(IAGE).interfaceId);
    }

    // Increases interest for specific owner
    function _increaseByPercent(address recepient) internal {
        if (address(0) != recepient) {
            uint256 percent = _tokensNeededForOwnership * 1 / 100;
            _balanceOwner[recepient] += percent;
        }
    }

    // Increases interest for voting participants
    function _increaseByPercent(address[] memory addresses1, address[] memory addresses2) internal {
        for (uint256 i = 0; i < addresses1.length; i++) {
            _increaseByPercent(addresses1[i]);
        }

        for (uint256 j = 0; j < addresses2.length; j++) {
            _increaseByPercent(addresses2[j]);
        }
    }
}