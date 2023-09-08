/*
 * Copyright (C) 2023 Anhydrite Gaming Ecosystem
 *
 * This code is part of the Anhydrite Gaming Ecosystem.
 *
 * ERC-20 Token: Anhydrite ANH 0x578b350455932aC3d0e7ce5d7fa62d7785872221
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

/*
* The abstract proxy smart contract that implements the IProxy interface,
* the main goal here is to delegate calls to the global smart contract,
* to set the project's main token.
*
* In addition, the possibility of depositing tokens by owners to their account in a smart contract,
* withdrawing excess tokens, as well as voluntary exit from owners is realized here.
* There is also an opportunity to get information about the global token, about the owners,
* their deposits, to find out whether the address is among the owners, as well as whether it has the right to vote.
*/
// Proxy is an abstract contract that implements the IProxy interface and adds utility and ownership functionality.
abstract contract Proxy is IProxy, BaseUtilityAndOwnable {

    // Internal function that delegates calls to the implementation contract
    function _delegate() internal virtual {
        require(!_stopped, "Proxy: Contract is currently _stopped.");
        address _impl = _implementation();
        require(_impl != address(0), "Proxy: Implementation == address(0)");

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    // Internal fallback function that delegates the call
    function _fallback() internal virtual {
        _delegate();
    }

    // Fallback function to handle incoming calls
    fallback() external payable virtual {
        _fallback();
    }

    // Function to forward Ether received to the implementation contract
    receive() external payable {
        Address.sendValue(payable(address(_implementation())), msg.value);
    }

    // Returns the main ERC20 token of the project
    function getCoreToken() external override pure returns (IERC20) {
        return ANHYDRITE;
    }

    // Returns the address of the implementation contract
    function implementation() external override view returns (address) {
        return _implementation();
    }

    // Checks if the contract's basic functions are stopped
    function isStopped() external override view returns (bool) {
        return _stopped;
    }

    // Returns the total number of owners
    function getTotalOwners() external override view returns (uint256) {
        return _totalOwners;
    }

    // Checks if an address is a proxy owner (has voting rights)
    function isProxyOwner(address ownerAddress) external override view returns (bool) {
        return _isProxyOwner(ownerAddress);
    }

    // Checks if an address is an owner
    function isOwner(address account) external override view returns (bool) {
        return _owners[account];
    }

    // Returns the balance of an owner
    function getBalanceOwner(address owner) external override view returns (uint256) {
        return _balanceOwner[owner];
    }

    // Returns the number of tokens needed to become an owner
    function getTokensNeededForOwnership() external override view returns (uint256) {
        return _tokensNeededForOwnership;
    }

    // Checks if an address is blacklisted
    function isBlacklisted(address account) external override view returns (bool) {
        return _blackList[account];
    }
}
