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
pragma solidity ^0.8.19;

import "../openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../openzeppelin/contracts/interfaces/IERC721.sol";
import "../openzeppelin/contracts/interfaces/IERC20.sol";
import "../openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FinanceManager
 * @dev The FinanceManager contract is an abstract contract that extends Ownable.
 * It provides a mechanism to transfer Ether, ERC20 tokens, and ERC721 tokens from
 * the contract's balance, accessible only by the owner.
 */
abstract contract FinanceManager is IERC721Receiver, Ownable {

    /**
     * @notice Transfers Ether from the contract's balance to a specified recipient.
     * @dev Can only be called by the contract owner.
     * @param recipient The address to receive the transferred Ether.
     * @param amount The amount of Ether to be transferred in wei.
     */
    function transferMoney(address payable recipient, uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "FinanceManager: Contract has insufficient balance");
        require(recipient != address(0), "FinanceManager: Recipient address is the zero address");
        recipient.transfer(amount);
    }
    
    /**
     * @notice Transfers ERC20 tokens from the contract's balance to a specified address.
     * @dev Can only be called by the contract owner.
     * @param _tokenAddress The address of the ERC20 token contract.
     * @param _to The recipient address to receive the transferred tokens.
     * @param _amount The amount of tokens to be transferred.
     */
    function transferERC20Tokens(address _tokenAddress, address _to, uint256 _amount) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        require(token.balanceOf(address(this)) >= _amount, "FinanceManager: Not enough tokens on contract balance");
        token.transfer(_to, _amount);
    }

    /**
     * @notice Transfers an ERC721 token from the contract's balance to a specified address.
     * @dev Can only be called by the contract owner.
     * @param _tokenAddress The address of the ERC721 token contract.
     * @param _to The recipient address to receive the transferred token.
     * @param _tokenId The unique identifier of the token to be transferred.
     */
    function transferERC721Token(address _tokenAddress, address _to, uint256 _tokenId) external onlyOwner {
        IERC721 token = IERC721(_tokenAddress);
        require(token.ownerOf(_tokenId) == address(this), "FinanceManager: The contract is not the owner of this token");
        token.safeTransferFrom(address(this), _to, _tokenId);
    }

    /**
     * @notice The onERC721Received function is used to process the receipt of ERC721 tokens.
     */
    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    
    receive() external payable {}
}