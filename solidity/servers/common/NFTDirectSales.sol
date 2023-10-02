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
 
// @filepath Repository Location: [solidity/servers/common/NFTDirectSales.sol]

pragma solidity ^0.8.19;

import "../../openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "../../openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "../../openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../../openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../../openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../openzeppelin/contracts/interfaces/IERC165.sol";
import "../../openzeppelin/contracts/access/Ownable.sol";

/**
 * @title NFTDirectSales
 * @dev This contract is designed to manage the direct sales of NFTs. 
 * It facilitates the pricing and purchasing of NFTs using either Ether or ERC20 tokens.
 * This is an abstract contract meant to be extended by concrete implementations, which should provide the
 * implementation for the _newMint function.
 */
abstract contract NFTDirectSales is ERC721Enumerable, ERC721URIStorage, ERC721Burnable, Ownable {

    // Struct representing the price of the NFT, can be in Ether or ERC20 tokens.
    struct Price {
        address tokenAddress; // Address of the ERC20 token. Address(0) represents Ether.
        uint256 amount; // Amount of either Ether or ERC20 tokens required.
    }
    
    // State variable storing the price of the NFT.
    Price private _price;

    // Event emitted when an NFT is purchased.
    event NFTPurchased(address indexed purchaser);

    /**
     * @dev Allows the owner to set the price of the NFT.
     * @param tokenAddress The address of the ERC20 token, or address(0) for Ether.
     * @param payAmount The amount of Ether or ERC20 tokens required.
     */
    function setPriceNFT(address tokenAddress, uint256 payAmount) external onlyOwner {
       _setPrice(tokenAddress, payAmount);
    }

    /**
     * @dev Internal function to set the price of the NFT.
     * @param tokenAddress The address of the ERC20 token, or address(0) for Ether.
     * @param payAmounts The amount of Ether or ERC20 tokens required.
     */
    function _setPrice(address tokenAddress, uint256 payAmounts) internal {
        _price = Price({
            tokenAddress: tokenAddress,
            amount: payAmounts
        });
    }

    /**
     * @dev Allows users to buy an NFT paying with Ether.
     */
    function buyNFT() external payable {
        _buyNFT();
    }

    /**
     * @dev Allows users to buy an NFT paying with ERC20 tokens.
     */
    function buyNFTWithTokens() external {
        _buyNFT();
    }
  
    /**
     * @dev Internal function executing the purchase of an NFT.
     * Checks if NFTs are available and calls the service to execute the purchase,
     * then mints a new NFT to the buyer.
     */
    function _buyNFT() internal {
        require(totalSupply() > 0, "NFTDirectSales: Token with ID 0 has already been minted");
        _buyService(); // Execute payment and transfer logic
        _newMint(msg.sender, tokenURI(0)); // Mint the new NFT
    }
    
    /**
     * @dev Internal function to handle the transfer of funds and emit the purchase event.
     */
    function _buyService() internal {
        uint256 paymentAmount = _price.amount;
        address paymentToken = _price.tokenAddress;
        if(paymentToken == address(0)) { // If paying with ether
            require(msg.value == paymentAmount, "NFTDirectSales: The amount of ether sent does not match the required amount.");
        } else { // If paying with tokens
            IERC20 token = IERC20(paymentToken);
            token.transferFrom(msg.sender, address(this), paymentAmount); // Transfer the required amount of tokens from the buyer to the contract
        }

        emit NFTPurchased(msg.sender); // Emit the purchase event
    }

    /**
     * @dev Internal virtual function meant to be overridden by concrete implementations.
     * Responsible for minting the new NFT.
     * @param to The address to which the NFT will be minted.
     * @param uri The URI for the NFT's metadata.
     */
    function _newMint(address to, string memory uri) internal virtual;

    /**
     * @dev Retrieves the token URI, resolving conflicts between ERC721 and ERC721URIStorage.
     */
    function tokenURI(uint256 tokenId) public view override (ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId); // Calls the respective functions from inherited contracts
    }

    /**
     * @dev Checks if the contract supports a specific interface, resolving conflicts between ERC721, ERC721Enumerable, and ERC721URIStorage.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC721, ERC721Enumerable, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId) ||
        interfaceId == type(IERC721Receiver).interfaceId;
    }

    /**
     * @dev This function `_update` is used to override the internal `_update` function of the parent contracts `ERC721` and `ERC721Enumerable`.
     */
    function _update(address to, uint256 tokenId, address auth) internal virtual override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }
    
    /**
     * @dev The function `_increaseBalance` is utilized to augment the balance of the specified account `account` by a certain `value`.
     */
    function _increaseBalance(address account, uint128 value) internal virtual override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }
}


