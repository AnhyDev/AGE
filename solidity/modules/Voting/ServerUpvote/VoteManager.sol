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

// @filepath Repository Location: [solidity/modules/Voting/VoteManager.sol]

pragma solidity ^0.8.19;

import "../../../openzeppelin/contracts/interfaces/IERC20.sol";
import "../../../openzeppelin/contracts/interfaces/IERC721.sol";
import "../../../interfaces/IAGEMonitoring.sol";
import "../../common/CashbackManager.sol";
import "../../../interfaces/IVoting.sol";
import "../../../common/BaseAnh.sol";

/**
 * @title VoteManager
 * @dev This contract allows users to vote for servers on a monitoring platform.
 * Users can cast votes using varying amounts such as 1, 10, 100, and so forth.
 * This contract extends functionalities from `CashbackManager`, `IVoting`, and `BaseAnh`.
 */
abstract contract VoteManager is CashbackManager, IVoting, BaseAnh {

    /**
     * @dev Constructor that initializes the cashback list for voting.
     */
	constructor() {
	    string[7] memory initialCashbacks = [
	        "voteForServerWith1",
	        "voteForServerWith10",
	        "voteForServerWith100",
	        "voteForServerWith1000",
	        "voteForServerWith10000",
	        "voteForServerWith100000",
	        "voteForServerWith1000000"
	    ];
	
	    for (uint i = 0; i < initialCashbacks.length; i++) {
            _addCashback(initialCashbacks[i]);
	    }
	}

    /**
     * @dev Allows a user to vote for a server using 1 vote.
     * @param serverAddress Address of the server being voted for.
     */
    function voteForServerWith1(address serverAddress) external override {
        _getMonitoring().voteForServerWith1(msg.sender, serverAddress);
    }

    /**
     * @dev Allows a user to vote for a server using 10 votes.
     * @param serverAddress Address of the server being voted for.
     */
    function voteForServerWith10(address serverAddress) external override {
        _getMonitoring().voteForServerWith10(msg.sender, serverAddress);
    }

    /**
     * @dev Allows a user to vote for a server using 100 votes.
     * @param serverAddress Address of the server being voted for.
     */
    function voteForServerWith100(address serverAddress) external override {
        _getMonitoring().voteForServerWith100(msg.sender, serverAddress);
    }

    /**
     * @dev Allows a user to vote for a server using 1,000 votes.
     * @param serverAddress Address of the server being voted for.
     */
    function voteForServerWith1000(address serverAddress) external override {
        _getMonitoring().voteForServerWith1000(msg.sender, serverAddress);
    }

    /**
     * @dev Allows a user to vote for a server using 10,000 votes.
     * @param serverAddress Address of the server being voted for.
     */
    function voteForServerWith10000(address serverAddress) external override {
        _getMonitoring().voteForServerWith10000(msg.sender, serverAddress);
    }

    /**
     * @dev Allows a user to vote for a server using 100,000 votes.
     * @param serverAddress Address of the server being voted for.
     */
    function voteForServerWith100000(address serverAddress) external override {
        _getMonitoring().voteForServerWith100000(msg.sender, serverAddress);
    }

    /**
     * @dev Allows a user to vote for a server using 1,000,000 votes.
     * @param serverAddress Address of the server being voted for.
     */
    function voteForServerWith1000000(address serverAddress) external override {
        _getMonitoring().voteForServerWith1000000(msg.sender, serverAddress);
    }

    /**
     * @dev Returns the monitoring interface for interacting with it.
     * @return The monitoring interface.
     */
    function _getMonitoring() internal view returns (IAGEMonitoring) {
        return IAGEMonitoring(_getFullAGEContract().getMonitoring().addr);
    }
}