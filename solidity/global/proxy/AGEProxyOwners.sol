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

// @filepath Repository Location: [solidity/global/proxy/AGEProxyOwners.sol]

pragma solidity ^0.8.19;


import "../../openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../../openzeppelin/contracts/interfaces/IERC721.sol";
import "./Provider.sol";
import "./VotingStopped.sol";
import "./VotingNeededForOwnership.sol";
import "./VotingNewImplementation.sol";
import "./VotingNewOwner.sol";
import "./VotingRemoveOwner.sol";
import "./ERC20Receiver.sol";

/**
 * @title AnhydriteProxyOwners
 * @dev This smart contract serves as a governance proxy for managing owners and interactions
 *      with the Anhydrite token and other tokens. It inherits multiple functionalities including
 *      governance through voting, handling ERC20 and ERC721 tokens, and implementing various proxy patterns.
 * 
 *      Inheritance Tree:
 *      - Proxy: Provides basic proxy functionality to execute calls via an implementation contract.
 *      - VotingStopped, VotingNeededForOwnership, VotingNewImplementation, 
 *        VotingNewOwner, VotingRemoveOwner: Governance mechanisms implemented through voting.
 *      - ERC20Receiver: Handles ERC20 tokens following a specific interface.
 *      - IERC721Receiver: Allows the contract to handle ERC721 tokens.
 *
 *      Key Features:
 *      1. Ownership Management: Allows adding, removing, and updating owners via voting mechanisms.
 *      2. Token Interactions: Handles receiving and transferring ERC20 (Anhydrite) and ERC721 tokens.
 *      3. Upgradability: Allows upgrading the implementation contract through voting.
 *      4. Token Requirements: Sets the minimum number of Anhydrite tokens needed for ownership.
 *      5. Rescue Mechanism: Allows rescuing accidentally sent tokens other than the native Anhydrite token.
 *
 *      Events:
 *      - VoluntarilyExit: Emitted when an owner voluntarily exits.
 */
contract AGEProxyOwners is
    Provider,
    VotingStopped,
    VotingNeededForOwnership,
    VotingNewImplementation,
    VotingNewOwner,
    VotingRemoveOwner,
    ERC20Receiver,
    IERC721Receiver {
    
    // Event emitted when an owner voluntarily exits.
    event VoluntarilyExit(address indexed votingSubject, uint returnTokens);

    // Constructor initializes basic contract variables.
    constructor() {
        _owners[msg.sender] = true;
        _totalOwners++;
        _tokensNeededForOwnership = 100000 * 10 **18;
    }

    // Allows an owner to voluntarily exit and withdraw their tokens.
    function voluntarilyExit() external proxyOwner {
        require(!_isOwnerVotedOut[msg.sender], "AnhydriteProxyOwners: You have been voted out");
        
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
                require(ANHYDRITE.transfer(address(ANHYDRITE), remainingBalance), "AnhydriteProxyOwners: Failed to return remaining tokens to ANHYDRITE contract");
            }
        }
    }
    
    // Allows an owner to withdraw excess tokens from their deposit.
    function withdrawExcessTokens() external proxyOwner {
        require(!_isOwnerVotedOut[msg.sender], "AnhydriteProxyOwners: You have been voted out");
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
            require(ANHYDRITE.transfer(recepient, amount), "AnhydriteProxyOwners: Failed to transfer tokens");
    }

    // Allows the contract to rescue any accidentally sent tokens, except for its native Anhydrite token.
    function rescueTokens(address tokenAddress) external proxyOwner {
        require(tokenAddress != address(ANHYDRITE), "AnhydriteProxyOwners: Cannot rescue the main token");
    
        IERC20 rescueToken = IERC20(tokenAddress);
        uint256 balance = rescueToken.balanceOf(address(this));
    
        require(balance > 0, "AnhydriteProxyOwners: No tokens to rescue");
    
        require(rescueToken.transfer(_implementation(), balance), "AnhydriteProxyOwners: Transfer failed");
    }

    // Handles received NFTs and forwards them
    function onERC721Received(address, address, uint256 tokenId, bytes calldata) external override returns (bytes4) {
        require(IERC165(msg.sender).supportsInterface(0x80ac58cd), "AnhydriteProxyOwners: Sender does not support ERC-721");

        IERC721(msg.sender).safeTransferFrom(address(this), _implementation(), tokenId);
        return this.onERC721Received.selector;
    }
}
