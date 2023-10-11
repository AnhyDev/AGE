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
 
// @filepath Repository Location: [solidity/servers/minecraft/AGEMinecraft.sol]

pragma solidity ^0.8.19;

import "../../openzeppelin/contracts/utils/Counters.sol";
import "../../interfaces/IAGEMinecraft.sol";
import "../../common/FinanceManager.sol";
import "../../common/ERC20Receiver.sol";
import "../common/CashbackStorage.sol";
import "../common/NFTDirectSales.sol";
import "../common/CheckingData.sol";
import "../common/Modules.sol";

contract AGEMinecraft is
  IAGEMinecraft,
  ERC20Receiver,
  FinanceManager,
  NFTDirectSales,
  Modules,
  CashbackStorage,
  CheckingData {

    using Counters for Counters.Counter;
    

    Counters.Counter private _tokenIdCounter;
    string private _serverIpAddress;
    uint16 private _serverPort;
    string private _serverName;
    string private _serverAddress;
    address private serverToken;

    constructor(address creator, string memory name, string memory symbol, string memory uri) ERC721(name, symbol) Ownable(creator) {
        _newMint(address(this), uri);
    }


    function _newMint(address to, string memory uri) internal override {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

	function getServerDetails() external view override returns (ServerInfo memory) {
	    ServerInfo memory info = ServerInfo({
	        ipAddress: _serverIpAddress,
	        port: _serverPort,
	        name: _serverName,
	        domainAddress: _serverAddress,
	        tokenAddress: serverToken
	    });
	    return info;
	}
    
    function setServerIpAddress(string calldata newServerIpAddress) external override onlyOwner {
        require(_isValidIPv4String(newServerIpAddress), "AGEMinecraft: Invalid IP address");
        _serverIpAddress = newServerIpAddress;
    }
    
    function getServerIpAddress() external override view returns (string memory) {
        return _serverIpAddress;
    }

    function setServerPort(uint16 newServerPort) external override onlyOwner {
        require(_isValidMinecraftPort(newServerPort), "AGEMinecraft: Invalid Port");
        _serverPort = newServerPort;
    }

    function getServerPort() external override view returns (uint16) {
        return _serverPort;
    }

    function setServerName(string calldata newName) external override onlyOwner {
        _serverName = newName;
    }

    function getServerName() external view override returns (string memory) {
        return _serverName;
    }

    function setServerDomainAddress(string calldata newDomainAddress) external override onlyOwner {
        require(_isValidDomain(newDomainAddress), "AGEMinecraft: Invalid domain address");
        _serverAddress = newDomainAddress;
    }

    function getServerDomainAddress() external view override returns (string memory) {
        return _serverAddress;
    }

    function getServerToken() public view returns (address) {
        return address(serverToken);
    }

    // Функція для зміни адреси serverToken
    function setServerToken(address _serverToken) public onlyOwner {
        require(true, "AGEMinecraft: Invalid ServerToken address");
        serverToken = _serverToken;
    }
    
    function supportsInterface(bytes4 interfaceId) public view override (ERC20Receiver, NFTDirectSales) returns (bool) {
        return  interfaceId == type(IAGEMinecraft).interfaceId ||
                super.supportsInterface(interfaceId);
    }
}
