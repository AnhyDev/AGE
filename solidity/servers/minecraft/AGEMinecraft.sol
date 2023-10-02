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
import "../common/Modules.sol";

contract AGEMinecraft is
  IAGEMinecraft,
  ERC20Receiver,
  FinanceManager,
  NFTDirectSales,
  Modules,
  CashbackStorage {

    using Counters for Counters.Counter;
    

    Counters.Counter private _tokenIdCounter;
    string private _serverIpAddress;
    uint16 private _serverPort;
    string private _serverName;
    string private _serverAddress;

    IERC20 public _tokenServer;

    constructor(address creator, string memory name, string memory symbol, string memory uri) ERC721(name, symbol) Ownable(creator) {
        _newMint(creator, uri);
        erc1820Registry.setInterfaceImplementer(address(this), keccak256("ERC721Receiver"), address(this));
    }


    function _newMint(address to, string memory uri) internal override {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }


    function setServerDetails(
        string calldata newServerIpAddress, uint16 newServerPort, string calldata newServerName, string calldata newServerAddress) external override onlyOwner {
            _setServerDetails(newServerIpAddress, newServerPort, newServerName, newServerAddress);
    }

    function _setServerDetails(
        string calldata newServerIpAddress, uint16 newServerPort, string calldata newServerName, string calldata newDomainAddress) internal {
        bool validIP = _isValidIPv4String(newServerIpAddress);
        bool validPort = _isValidMinecraftPort(newServerPort);
        bool validServerName = bytes(newServerName).length != 0;
        bool validServerAddress = _isValidDomain(newDomainAddress);
        require(validIP || validPort || validServerName || validServerAddress, "AGEMinecraftServer: At least one valid parameter is required");

        if (validIP) {
            _serverIpAddress = newServerIpAddress;
        }

        if (newServerPort != 0) {
            _serverPort = newServerPort;
        }

        if (validServerName) {
            _serverName = newServerName;
        }

        if (validServerAddress) {
            _serverAddress = newDomainAddress;
        }
    }
    
    function setServerIpAddress(string calldata newServerIpAddress) external override onlyOwner {
        require(_isValidIPv4String(newServerIpAddress), "Invalid IP address");
        _serverIpAddress = newServerIpAddress;
    }
    
    function getServerIpAddress() external override view returns (string memory) {
        return _serverIpAddress;
    }

    function setServerPort(uint16 newServerPort) external override onlyOwner {
        _isValidMinecraftPort(newServerPort);
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
        _isValidDomain(newDomainAddress);
        _serverAddress = newDomainAddress;
    }

    function getServerDomainAddress() external view override returns (string memory) {
        return _serverAddress;
    }

    function supportsInterface(bytes4 interfaceId) public view override (ERC20Receiver, NFTDirectSales) returns (bool) {
        return  interfaceId == type(IAGEMinecraft).interfaceId ||
                super.supportsInterface(interfaceId);
    }

    function _isValidIPv4String(string memory ipString) private pure returns (bool) {
        // Перевірка довжини рядка
        if (bytes(ipString).length < 7 || bytes(ipString).length > 15) return false;
        
        bytes memory ipBytes = bytes(ipString);
        uint8 dotCount = 0;
        bytes4 ipBytesTemp;
        uint8 currentOctet = 0;

        // Конвертація рядка із символів та перевірка валідності
        for (uint256 i = 0; i < ipBytes.length; i++) {
            if ((ipBytes[i] < "0" || ipBytes[i] > "9") && ipBytes[i] != ".") return false;

            if (ipBytes[i] == ".") {
                if (currentOctet > 255 || currentOctet == 0) return false;
                ipBytesTemp |= bytes4(bytes1(currentOctet & 0xFF)) >> (dotCount * 8);
                currentOctet = 0;
                dotCount++;
            } else {
                currentOctet = currentOctet * 10 + uint8(ipBytes[i]) - 48;
            }
        }

        // Перевірка кількості крапок та валідності останнього октета
        if (dotCount != 3 || currentOctet > 255 || currentOctet == 0) return false;
        ipBytesTemp |= bytes4(bytes1(currentOctet & 0xFF));

        // Перевірка валідності конвертованого IP-адреси та чи він не є приватним
        if (ipBytesTemp == bytes4(0) || 
            uint8(ipBytesTemp[0]) == 10 || 
            (uint8(ipBytesTemp[0]) == 172 && (uint8(ipBytesTemp[1]) >= 16 && uint8(ipBytesTemp[1]) <= 31)) || 
            (uint8(ipBytesTemp[0]) == 192 && uint8(ipBytesTemp[1]) == 168)) return false;

        return true;
    }

    function _isValidDomain(string memory domain) private pure returns (bool) {
        bytes memory domainBytes = bytes(domain);
        if(domainBytes.length < 3 || domainBytes[0] == '.' || domainBytes[domainBytes.length - 1] == '.') return false;
        
        uint dotCount = 0;
        
        for(uint i=0; i<domainBytes.length; i++) {
            bytes1 char = domainBytes[i];
            
            if(char == '.') {
                dotCount++;
                if(dotCount > 3) return false;
            }
            
            if(!((char >= 'a' && char <= 'z') || (char >= '0' && char <= '9') || char == '-' || char == '.')) return false;
            if(i > 0 && domainBytes[i] == '.' && domainBytes[i-1] == '.') return false; // перевіряємо на '..'
        }
        
        if(dotCount < 1 || domainBytes[domainBytes.length - 1] == '-') return false;

        return true;
    }

    function _isValidMinecraftPort(uint16 port) private pure returns (bool) {
        if (port < 1024) return false;
        return true;
    }
}
