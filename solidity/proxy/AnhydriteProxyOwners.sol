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
// Interface for contracts that are capable of receiving ERC20 (ANH) tokens.
interface IERC20Receiver {
    // Function that is triggered when ERC20 (ANH) tokens are received.
    function onERC20Received(address _from, address _who, uint256 _amount) external returns (bytes4);
}

// AnhydriteProxyOwners is an extension of several contracts and interfaces, designed to manage ownership, voting, and token interaction.
contract AnhydriteProxyOwners
 is Proxy, VotingStopped, VotingNeededForOwnership, VotingNewImplementation, VotingNewOwner, VotingRemoveOwner, IERC20Receiver {

    // Event emitted when an owner voluntarily exits.
    event VoluntarilyExit(address indexed votingSubject, uint returnTokens);
    // Event emitted when Anhydrite tokens are deposited.
    event DepositAnhydrite(address indexed from, address indexed who, uint256 amount);
    
    // Constructor initializes basic contract variables.
    constructor() {
        _implementAGE = address(0);
        _owners[msg.sender] = true;
        _totalOwners++;
        _tokensNeededForOwnership = 100000 * 10 **18;
    }

    // Allows an owner to voluntarily exit and withdraw their tokens.
    function voluntarilyExit() external onlyOwner {
        require(!_isOwnerVotedOut[msg.sender], "Proxy: You have been voted out");
        
        uint256 balance = _balanceOwner[msg.sender];
        if (balance > 0) {
            _transferTokens(msg.sender, balance);
        }

        _owners[msg.sender] = false;
        _totalOwners--;

        emit VoluntarilyExit(msg.sender, balance);

        if (_totalOwners == 0) {
            uint256 remainingBalance = ANHYDRITE.balanceOf(address(this));
            if (remainingBalance > 0) {
                require(ANHYDRITE.transfer(address(ANHYDRITE), remainingBalance), "Proxy: Failed to return remaining tokens to ANHYDRITE contract");
            }
        }
    }
    
    // Allows an owner to withdraw excess tokens from their deposit.
    function withdrawExcessTokens() external onlyOwner {
        require(!_isOwnerVotedOut[msg.sender], "Proxy: You have been voted out");
        uint256 ownerBalance = _balanceOwner[msg.sender];
        uint256 excess = 0;

        if (ownerBalance > _tokensNeededForOwnership) {
            excess = ownerBalance - _tokensNeededForOwnership;
            _transferTokens(msg.sender, excess);
        }
    }

    // Internal function to handle token transfers.
    function _transferTokens(address recepient, uint256 amount) private {
            _balanceOwner[recepient] -= amount;

            if(ANHYDRITE.balanceOf(address(this)) < amount) {
                ANHYDRITE.transferForProxy(amount);
            }
            require(ANHYDRITE.transfer(recepient, amount), "Proxy: Failed to transfer tokens");
    }

    // Allows the contract to rescue any accidentally sent tokens, except for its native Anhydrite token.
    function rescueTokens(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(ANHYDRITE), "Proxy: Cannot rescue the main token");
    
        IERC20 rescueToken = IERC20(tokenAddress);
        uint256 balance = rescueToken.balanceOf(address(this));
    
        require(balance > 0, "Proxy: No tokens to rescue");
    
        require(rescueToken.transfer(_implementation(), balance), "Proxy: Transfer failed");
    }

    // Implementation of IERC20Receiver, for receiving ERC20 tokens.
    function onERC20Received(address _from, address _who, uint256 _amount) external returns (bytes4) {
        if (msg.sender == address(ANHYDRITE)) {
            if (_owners[_who]) {
                _balanceOwner[_who] += _amount;
                emit DepositAnhydrite(_from, _who, _amount);
            }
            return this.onERC20Received.selector;
        }
        return bytes4(keccak256("anything_else"));
    }
}