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

// @filepath Repository Location: [solidity/global/global-age/AGE.sol]

pragma solidity ^0.8.19;

import "./ModuleManager.sol";
import "../../interfaces/IAGE.sol";
import "../common/OwnableManager.sol";
import "../common/FinanceManager.sol";
import "../../common/ERC20Receiver.sol";
import "../../openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../../openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "../../openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "../../openzeppelin/contracts/utils/Counters.sol";

// The main contract for the Anhydrite Gaming Ecosystem (AGE).
contract AGE is
    IAGE,
    ERC20Receiver,
    OwnableManager,
    FinanceManager,
    ModuleManager,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Burnable
{
    using Counters for Counters.Counter;

    // Defines the current version of the contract.
    uint256 public constant VERSION = 0;
    
    // A counter to manage unique token IDs.
    Counters.Counter private _tokenIdCounter;
    
    // Mapping between token IDs and corresponding contract addresses.
    mapping(uint256 => address) private _tokenContract;
    
    // Mapping between contract addresses and their corresponding token IDs.
    mapping(address => uint256) private _contractToken;

    struct Price {
        string name;
        uint256 price;
    }
    
    // Mapping to store the price associated with each service name.
    mapping(bytes32 => Price) internal _prices;
    bytes32[] internal _priceArray;

    constructor() ERC721("Anhydrite Gaming Ecosystem", "AGE") {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, "ipfs://bafkreif66z2aeoer6lyujghufat3nxtautrza3ucemwcwgfiqpajjlcroy");
        _tokenContract[tokenId] = msg.sender;
    }

    // Allows the owner to set the price for a specific service.
    function addPrice(string memory name, uint256 count) public override onlyOwner {
        bytes32 key = keccak256(abi.encodePacked(name));
        if (bytes(_prices[key].name).length == 0) {
            _priceArray.push(key);
        }
        _prices[key] = Price(name, count);
    }

    // Retrieves the price for a given service name.
    function getPrice(bytes32 key) public view override returns (uint256) {
        return _prices[key].price;
    }
    
    function getPrices() public view returns (Price[] memory) {
        uint256 length = _priceArray.length;
        Price[] memory prices = new Price[](length);
        
        for (uint256 i = 0; i < length; i++) {
            prices[i] = _prices[_priceArray[i]];
        }
        
        return prices;
    }

    // Retrieves the address of the server associated with a given token ID.
    function getServerFromTokenId(uint256 tokenId) public view override returns (address) {
        return _tokenContract[tokenId];
    }

    // Retrieves the token ID associated with a given server address.
    function getTokenIdFromServer(address serverAddress) public view override returns (uint256) {
        return _contractToken[serverAddress];
    }

    // Overrides the tokenURI function to provide the URI for each token.
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    // Checks if the contract supports a specific interface.
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC721URIStorage, ERC20Receiver) returns (bool) {
        return interfaceId == type(IAGE).interfaceId ||
               interfaceId == type(IERC20Receiver).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    // Internal function to mint a token for a given server.
    function _mintTokenForServer(address serverAddress) internal override {
        require(_contractToken[serverAddress] == 0, "AnhydriteGamingEcosystem: This contract has already used safeMint");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _tokenContract[tokenId] = serverAddress;
        _contractToken[serverAddress] = tokenId;

        _mint(serverAddress, tokenId);
        _setTokenURI(tokenId, tokenURI(0));
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