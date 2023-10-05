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
 
// @filepath Repository Location: [solidity/global/common/Anhydrite.sol]

pragma solidity ^0.8.19;

import "../../common/ERC20ReceiverToken.sol";
import "./FinanceManager.sol";
import "./TokenManager.sol";
import "./MainManager.sol";
import "../common/OwnableManager.sol";


/*
 * Anhydrite Contract:
 * - Inherits From: FinanceManager, TokenManager, ProxyManager, OwnableManager, ERC20, ERC20Burnable, ERC20Receiver.
 * - Purpose: Provides advanced features to a standard ERC-20 token including token minting, burning, and ownership voting.
 * - Special Features:
 *   - Sets a maximum supply limit of 360 million tokens.
 * - Key Methods:
 *   - `getMaxSupply`: Returns the maximum allowed supply of tokens.
 *   - `transferForProxy`: Only allows a proxy smart contract to initiate token transfers.
 *   - `_transferFor`: Checks and performs token transfers, and mints new tokens if necessary, but not exceeding max supply.
 *   - `_mint`: Enforces the max supply limit when minting tokens.
 */
contract Anhydrite is ERC20ReceiverToken, FinanceManager, TokenManager, MainManager, OwnableManager{

    // Sets the maximum allowed supply of tokens is 360 million
    uint256 constant public MAX_SUPPLY = 360000000 * 10 ** 18;

    constructor() ERC20ReceiverToken("Anhydrite", "ANH") {
        _whiteList[address(this)] = true;
        
        erc1820Registry.setInterfaceImplementer(address(this), keccak256("IANH"), address(this));
   }

    // Sending tokens on request from the smart contract MainProvider to its address
    function transferForMainOwnership(uint256 amount) external {
        address main = _getMain();
        require(main != address(0), "Anhydrite: The MainProvider contract has not yet been established");
        require(msg.sender == main, "Anhydrite: Only a MainProvider smart contract can activate this feature");
        _transferFor(main, amount);
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
     * Internal function to check if an address is on the whitelist.
     * This function overrides a function defined in a parent contract (as indicated by the `override` keyword).
     * It returns a boolean value indicating the whitelist status of the given address `checked`.
     */
    function _checkWhitelist(address checked) internal view override returns (bool) {
        return _whiteList[checked];
    }

    /*
     * Overridden Function: _mint
     * Extends the original _mint function from the ERC20 contract to include a maximum supply limit.
     */
    function _mint(address account, uint256 amount) internal override {
        require(totalSupply() + amount <= MAX_SUPPLY, "Anhydrite: MAX_SUPPLY limit reached");
        super._mint(account, amount);
    }
    
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC20ReceiverToken) returns (bool) {
        return ERC20ReceiverToken.supportsInterface(interfaceId) ||
           interfaceId == type(IERC721Receiver).interfaceId;
    }
}
