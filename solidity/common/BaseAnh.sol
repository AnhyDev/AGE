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
 
// @filepath Repository Location: [solidity/common/BaseAnh.sol]

pragma solidity ^0.8.19;

import "./BaseUtility.sol";
import "../interfaces/IANH.sol";
import "../interfaces/IERC1820Registry.sol";

abstract contract BaseAnh is BaseUtility {

    // Address of the Main project token (ANH)
    IANH public constant ANHYDRITE = IANH(0xB893A85D80e53Da458656105a54525198A88E419);

    function _getAGE() internal view override virtual returns (address) {
        return ANHYDRITE.getAGEAddress();
    }

    function _getMain() internal view override virtual returns(address) {
        return ANHYDRITE.getMainOwnership();
    }

    function _isMainOwner(address senderAddress) internal view override virtual returns (bool) {
        return _getMainProviderContract().isProxyOwner(senderAddress);
    }

    function _setAddressMain(address /*main*/) internal pure override virtual {
        revert("BaseAnh: A plug for implementing the interface standard");
    }

    function _setAddressAge(address age) internal override virtual {
        ANHYDRITE.setAGEAddress(age);
    }
}