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

// @filepath Repository Location: [solidity/global/global-age/MonitoringManager.sol]

pragma solidity ^0.8.19;

import "../common/Ownable.sol";
import "../../interfaces/IAGEMonitoring.sol";


/*
 * The Monitorings smart contract is designed to work with monitoring,
 * add, delete, vote for the server, get the number of votes, and more.
 */
abstract contract MonitoringManager is Ownable {
    enum ServerStatus {
        NotFound,
        Monitored,
        Blocked
    }

    address[] private _monitoring;

    struct Monitoring {
        uint256 version;
        address addr;
    }

    // Add a new address to the monitoring list.
    function addMonitoring(address newAddress) external onlyOwner {
        _monitoring.push(newAddress);
    }

    // Get the last non-zero monitoring address and its index.
    function getMonitoring() external view returns (Monitoring memory) {
        return _getMonitoring();
    }

    // Get the list of non-zero monitoring addresses.
    function getMonitoringAddresses() external view returns (Monitoring[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < _monitoring.length; i++) {
            if (_monitoring[i] != address(0)) {
                count++;
            }
        }

        Monitoring[] memory result = new Monitoring[](count);

        uint256 index = 0;
        for (uint256 i = 0; i < _monitoring.length; i++) {
            if (_monitoring[i] != address(0)) {
                result[index] = Monitoring({
                    version: i,
                    addr: _monitoring[i]
                });
                index++;
            }
        }
        return result;
    }

    // Remove an address from the monitoring list by replacing it with the zero address.
    function removeMonitoringAddress(address addressToRemove) external onlyOwner {
        bool found = false;
        // Find the address to be removed and replace it with the zero address.
        for (uint256 i = 0; i < _monitoring.length; i++) {
            if (_monitoring[i] == addressToRemove) {
                _monitoring[i] = address(0);
                found = true;
                break;
            }
        }
        require(found, "Monitorings: Address not found");
    }

    // Check whether the specified address is monitored and not blocked or not found
    function getServerMonitoringStatus(address serverAddress) external view returns (string memory) {
        (ServerStatus status,) = _getVotesMonitoredOrBlocked(serverAddress, false);
        string memory stringStatus = "NotFound";
        if (status == ServerStatus.Monitored) {
            stringStatus = "Monitored";
        } else if (status == ServerStatus.Blocked) {
            stringStatus = "Blocked";
        }
        return stringStatus;
    }

    // Get the number of votes on monitorings for the specified address
    function getTotalServerVotes(address serverAddress) external view returns (uint256) {
        (, uint256 totalVotes) = _getVotesMonitoredOrBlocked(serverAddress, true);
        return totalVotes;
    }

    // Vote on monitoring for the address
    function voteForServer(address serverAddress) external {
        _voteForServer(serverAddress);
    }

    /**
     * @dev Retrieves the monitoring status and optionally the total votes for a given server address.
     * This function iterates through the `_monitoring` array and checks each monitoring contract to determine
     * whether the server exists, and if it does, whether it is blocked or simply being monitored.
     *
     * @param serverAddress The address of the server to be checked.
     * @param getVotes A boolean flag indicating whether to retrieve the total votes for the server.
     *
     * @return A tuple containing the ServerStatus enum value (NotFound, Monitored, Blocked) and the total votes.
     *         - ServerStatus: Indicates the final monitoring status of the server.
     *         - totalVotes: The total number of votes for this server across all monitoring contracts.
     *                       This value is only meaningful if `getVotes` is true and the server is not blocked.
     *
     * Requirements:
     * - serverAddress must not be the zero address.
     */
    function _getVotesMonitoredOrBlocked(address serverAddress, bool getVotes) private view returns (ServerStatus, uint256) {
        ServerStatus status = ServerStatus.NotFound;
        uint256 totalVotes = 0;
        for (uint256 i = 0; i < _monitoring.length; i++) {
            if (address(_monitoring[i]) == address(0)) {
                continue;
            }
            IAGEMonitoring monitoring = IAGEMonitoring(_monitoring[i]);
            if (monitoring.isServerExist(serverAddress)) {
                status = ServerStatus.Monitored;
                if (getVotes) {
                    totalVotes += monitoring.getServerVotes(serverAddress);
                }
                (bool blocked,) = monitoring.getServerBlocked(serverAddress);
                if (blocked) {
                    status = ServerStatus.Blocked;
                    totalVotes = 0;
                    break;
                }
            }
        }
        return (status, totalVotes);
    }

    function _isServerMonitored(address serverAddress) internal view returns (bool) {
        (ServerStatus status,) = _getVotesMonitoredOrBlocked(
            serverAddress,
            false
       );
        return status == ServerStatus.Monitored;
    }

    event ExceptionInfo(address indexed to, string exception);

    function _voteForServer(address serverAddress) private {
        require(_isServerMonitored(serverAddress), "Monitorings: This address is not monitored or blocked");
        address monitoringAddress = _getMonitoring().addr;

        try IAGEMonitoring(monitoringAddress).voteForServer(msg.sender, serverAddress) {
	    } catch Error(string memory reason) {
            emit ExceptionInfo(msg.sender, reason);
	    } catch (bytes memory lowLevelData) {
            string memory infoError = "Another error";
            if (lowLevelData.length > 0) {
                infoError = string(lowLevelData);
            }
            emit ExceptionInfo(msg.sender, infoError);
        }
            
    }

    function _getMonitoring() private view returns (Monitoring memory) {
        for (uint256 i = _monitoring.length; i > 0; i--) {
            if (_monitoring[i - 1] != address(0)) {
                return Monitoring({version: i - 1, addr: _monitoring[i - 1]});
            }
        }
        revert("Monitorings: no found");
    }

    function _addServerToMonitoring(uint256 gameId, address serverAddress) internal {
        address monitoringAddress = _getMonitoring().addr;

        IAGEMonitoring(monitoringAddress).addServerAddress(gameId, serverAddress);
    }
}