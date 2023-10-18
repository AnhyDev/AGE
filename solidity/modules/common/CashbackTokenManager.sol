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
 
// @filepath Repository Location: [solidity/modules/ModuleCashbackTokens.sol]

pragma solidity ^0.8.19;

import "../../openzeppelin/contracts/interfaces/IERC165.sol";
import "../../openzeppelin/contracts/access/Ownable.sol";
import "../../interfaces/IModuleCashback.sol";
import "../../interfaces/IAGEModule.sol";
import "../../interfaces/IServer.sol";
import "../../common/ERC20ReceiverToken.sol";

/**
 * @title CashbackTokenManager
 * @dev This contract serves as a manager for issuing tokens as part of a cashback system. 
 * Only approved addresses are permitted to request the issuance of tokens. 
 * The owner of the contract can manage these approvals. 
 * This is an abstract contract, and the specific token issuance logic should be defined in derived contracts.
 */
abstract contract CashbackTokenManager is IModuleCashback, ERC20ReceiverToken, Ownable {

	IServer internal _serverContract;
    
    address internal moduleFactory;

    //mapping(bytes32 => uint256) internal _cashback;
    mapping(address => bool) internal _approvedTokenRequestAddresses;

    constructor(address serverAddress, address factoryContractAddress) {
        moduleFactory = factoryContractAddress;
        _serverContract = IServer(serverAddress);
        erc1820Registry.setInterfaceImplementer(address(this), keccak256("IModuleCashback"), address(this));
    }

    /**
     * @dev Issues tokens to a recipient if the calling address is approved and source of cashback is valid.
     * @param _recipient The address to receive the issued tokens.
     * @param source The bytes32 representing the source of cashback.
     */
    function issueTokens(address _recipient, bytes32 source) external override {
        require(_isAddressApproved(msg.sender), "CashbackTokenManager: Address not approved to request tokens");
        (/*address moduleAddress*/, uint256 amount) = _serverContract.getCashback(source);
        _giveTokens(_recipient, amount);
    }

    /**
     * @dev Checks whether the message sender is approved for the specified amount.
     * @param module The amount to check approval for.
     * @return bool True if the message sender is approved, false otherwise.
     */
    function isAddressApproved(address module) external view override returns (bool) {
        return _isAddressApproved(module);
    }
    function _isAddressApproved(address module) internal view returns (bool) {
        return _approvedTokenRequestAddresses[module];
    }

    /**
     * @dev Toggles the approval status for a specific address. This function allows:
     * - The contract owner OR the server contract to change permissions, but only for addresses that are associated with a module in the module list.
     * - An already approved address to revoke its own approval (but it cannot re-approve itself).
     * 
     * @param address_ The address for which to toggle the approval status.
     * @param status The desired approval status (true for approval, false for disapproval).
     *
     * Requirements:
     * - If the caller is the address itself, it can only revoke its own approval (it cannot re-approve itself).
     * 
     * Throws an error if the caller doesn't have the appropriate permissions to change the approval.
     */
    function toggleAddressApproval(address address_, bool status) external override {
        if (((msg.sender == owner() || msg.sender == address(_serverContract)) && _isAddressInModuleList(IAGEModule(address_).getModuleFactory()))
            || (address_ == msg.sender && _approvedTokenRequestAddresses[address_]) && !status) {
            _approvedTokenRequestAddresses[address_] = status;
        } else {
            revert("CashbackTokenManager: You do not have permission to change the permission");
        }
        
    }

    /**
     * @dev Internal function that checks whether a given address is among the modules.
     * @param targetAddress Address to check.
     * @return bool Whether the address is in the module list.
     */
    function _isAddressInModuleList(address targetAddress) internal view returns (bool) {
        address[] memory moduleAddresses = _serverContract.getModuleAddresses();
        for (uint256 i = 0; i < moduleAddresses.length; i++) {
            if (moduleAddresses[i] == targetAddress) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Converts a string into a bytes32 hash, which is used as a key for cashback values.
     * @param source Input string to convert.
     * @return result The resulting bytes32 hash.
     */
    function _stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes32 keyHash = keccak256(abi.encodePacked(source));
        return keyHash;
    }

    /**
     * @dev Abstract function to be overridden, used for implementing token distribution logic.
     * @param recipient The recipient of the tokens.
     * @param amount The amount of tokens to distribute.
     */
    function _giveTokens(address recipient, uint256 amount) internal virtual;
    
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC20ReceiverToken) virtual returns (bool) {
        return interfaceId == type(IModuleCashback).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

