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

// @filepath Repository Location: [solidity/global/global-age/PriceOfServices.sol]

pragma solidity ^0.8.19;

import "../../common/BaseAnh.sol";

abstract contract PriceOfServices is BaseAnh {

    struct Price {
        string name;
        uint256 price;
    }
    
    // Mapping to store the price associated with each service name.
    mapping(bytes32 => Price) private _prices;
    bytes32[] private _priceArray;
    

    // Allows the owner to set the price for a specific service.
    function _addPrice(string memory name, uint256 count) internal {
        bytes32 key = keccak256(abi.encodePacked(name));
        if (!_serviceExists(key)) {
            _priceArray.push(key);
        }
        _prices[key] = Price(name, count);
    }

    // Retrieves the price for a given service name.
    function _getPrice(bytes32 key) internal view returns (uint256) {
        return _prices[key].price;
    }
    
    function _getPrices() internal view returns (Price[] memory) {
        uint256 length = _priceArray.length;
        Price[] memory prices = new Price[](length);
        
        for (uint256 i = 0; i < length; i++) {
            prices[i] = _prices[_priceArray[i]];
        }
        
        return prices;
    }

	function _serviceExists(bytes32 key) internal view returns (bool) {
	    return bytes(_prices[key].name).length > 0;
	}

	function _burnAnhydrite(address from, uint256 amount) internal returns (bool) {
	    if (ANHYDRITE.balanceOf(from) >= amount) {
	        ANHYDRITE.burnFrom(from, amount);
	        return true;
	    } else {
	        return false;
	    }
	}
}