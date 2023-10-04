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
 
// @filepath Repository Location: [solidity/global/common/AnhydriteManager.sol]

pragma solidity ^0.8.19;

import "../../interfaces/IFullAGE.sol";
import "../../interfaces/IProvider.sol";
import "../../common/BaseUtility.sol";
import "../../openzeppelin/contracts/interfaces/IERC165.sol";

abstract contract AnhydriteManager is BaseUtility {

    address internal addressAGE;

    address internal mainOwnership;

    // Returns the Ethereum address of the MainOwnership contract.
    function getMainOwnership() external view returns (address) {
        return _getMain();
    }

    // Returns the Ethereum address of the AGE contract.
    function getAGEAddress() external view returns (address) {
        return _getMain();
    }

    function getMainAndAGE() external view returns (address, address) {
        return (_getMain(), _getAGE());
    }

    function _setAddressAge(address age) internal override {
        addressAGE = age;
    }

    function _getAGE() internal view override returns (address) {
        return addressAGE;
    }

    function _setAddressMain(address main) internal override {
        mainOwnership = main;
    }

    function _getMain() internal view override returns(address) {
        return mainOwnership;
    }

    function _isMainOwner(address senderAddress) internal view override returns (bool) {
        return _getMainProviderContract().isProxyOwner(senderAddress);
    }

    // Checks if an address is a smart contract that implements the IProvider interface.
    function _checkIProviderContract(address contractAddress) internal view returns (bool) {
        if (contractAddress.code.length > 0) {
            IERC165 targetContract = IERC165(contractAddress);
            return targetContract.supportsInterface(type(IProvider).interfaceId);
        }
        return false;
    }
}