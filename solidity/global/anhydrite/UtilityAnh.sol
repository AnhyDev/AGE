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
 
// @filepath Repository Location: [solidity/global/common/UtilityAnh.sol]

pragma solidity ^0.8.19;

import "../../interfaces/IProxy.sol";
import "../../common/BaseUtility.sol";
import "../../interfaces/IERC1820Registry.sol";
import "../../openzeppelin/contracts/interfaces/IERC165.sol";


/**
 * @title BaseUtility Abstract Contract
 * @dev This abstract contract provides base functionalities for interacting with a proxy contract.
 *      It includes helper methods for setting, querying, and interacting with the proxy contract.
 * 
 *      The '_proxy' state variable stores the Ethereum address of the proxy contract that adheres to the IProxy interface.
 * 
 *      Functions include:
 *      - getProxyAddress: To publicly get the Ethereum address of the proxy contract.
 *      - _setProxyContract: To set or update the proxy contract address.
 *      - _proxyContract: To get the current proxy contract address.
 *      - _isProxyOwner: To check if an address is an owner of the proxy contract.
 *      - _checkIProxyContract: To validate if an address is a smart contract that implements the IProxy interface.
 */
abstract contract UtilityAnh is BaseUtility {
    
    // Proxy contract interface
    IProxy private _proxy;

    // Returns the Ethereum address of the proxy contract.
    function getProxyAddress() public view returns (address) {
        return _getProxyAddress();
    }

    /*
     * Internal function to update the proxy contract address.
     * This function is used to set a new address for the proxy contract and 
     * it takes the new address as an argument. It assumes the address adheres to the IProxy interface.
     * The internal state variable '_proxy' is then updated with this new address.
     */
    function _setProxyContract(address newProxy) internal {
        _proxy = IProxy(newProxy);
    }

    // Checks if an address is an owner of the proxy contract, as per the proxy contract's own rules.
    function _isProxyOwner(address senderAddress) internal view override returns (bool) {
        return _proxyContract().isProxyOwner(senderAddress);
    }

    // Checks if an address is a smart contract that implements the IProxy interface.
    function _checkIProxyContract(address contractAddress) internal view returns (bool) {
        if (contractAddress.code.length > 0) {
            IERC165 targetContract = IERC165(contractAddress);
            return targetContract.supportsInterface(type(IProxy).interfaceId);
        }
        return false;
    }

    /**
    * @notice Returns the proxy contract address from the Anhydrite contract.
    * @dev Retrieves and returns the address of the proxy contract by calling getProxyAddress function of the ANHYDRITE contract.
    * @return address The address of the proxy contract.
    */
    function _getProxyAddress() internal view override returns (address) {
        return address(_proxy);
    }
}
