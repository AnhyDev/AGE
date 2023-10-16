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
 
// @filepath Repository Location: [solidity/common/BaseUtility.sol]

pragma solidity ^0.8.19;

import "../interfaces/IANH.sol";
import "../interfaces/IFullAGE.sol";
import "../interfaces/IProvider.sol";
import "../interfaces/IERC1820Registry.sol";

abstract contract BaseUtility {

    // Address of the ERC-1820 Registry
    IERC1820Registry constant internal erc1820Registry = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);


    function _setAddressAge(address age) internal virtual;

    function _getAGE() internal view virtual returns (address);

    function _setAddressMain(address main) internal virtual;

    function _getMain() internal view virtual returns(address);

    // Checks whether the address is among the owners of the proxy contract
    function _isMainOwner(address senderAddress) internal view virtual returns (bool);

    function _getFullAGEContract() internal view returns(IFullAGE) {
        return IFullAGE(_getAGE());
    }

    function _getMainProviderContract() internal view returns(IProvider) {
        return IProvider(_getMain());
    }

    function _getMainAndAGE() internal view returns (address, address) {
        return (_getMain(), _getAGE());
    }
}