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

contract CheckingData {

	function _isValidIPv4String(string memory stringIP) internal pure returns (bool) {
	    bytes memory bytesIP = bytes(stringIP);

	    if (!_hasValidLength(string(bytesIP))) return false;

	    uint8[] memory octets = new uint8[](4);
	    uint8 dotCount = 0;
	    uint16 currentOctet = 0;  // Змінили на uint16

	    for (uint256 i = 0; i < bytesIP.length; i++) {
	        if (bytesIP[i] == ".") {
	            if (currentOctet > 255) return false;
	            octets[dotCount] = uint8(currentOctet);
	            currentOctet = 0;
	            dotCount++;
	        } else {
	            uint8 digitValue = _checkSingleDigit(bytesIP[i]);
	            if(digitValue == 100) return false; 
	            currentOctet = currentOctet * 10 + digitValue;
	        }
	    }

	    if (dotCount != 3 || currentOctet > 255 || _isPrivateIP(octets)) return false;  // Змінили умову для перевірки

	    return true;
	}

    function _hasValidLength(string memory ipString) internal pure returns (bool) {
        uint length = bytes(ipString).length;
        return length >= 7 && length <= 15;
    }

    function _isValidOctet(uint8 octet) internal pure returns (bool) {
        return octet <= 255;
    }

    function _checkSingleDigit(bytes1 char) internal pure returns (uint8) {
        if (char >= '0' && char <= '9') {
            return uint8(char) - 48;
        }
        return 100;
    }

	function _isPrivateIP(uint8[] memory octets) internal pure returns (bool) {
	    if (octets[0] == 0 && octets[1] == 0 && octets[2] == 0 && octets[3] == 0) return true;
	    return octets[0] == 10 || 
	           (octets[0] == 172 && octets[1] >= 16 && octets[1] <= 31) ||
	           (octets[0] == 192 && octets[1] == 168);
	}

    function _isValidDomain(string memory domain) internal pure returns (bool) {
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
            if(i > 0 && domainBytes[i] == '.' && domainBytes[i-1] == '.') return false;
        }
        
        if(dotCount < 1 || domainBytes[domainBytes.length - 1] == '-') return false;

        return true;
    }

    function _isValidMinecraftPort(uint16 port) internal pure returns (bool) {
        if (port < 1024) return false;
        return true;
    }
}
