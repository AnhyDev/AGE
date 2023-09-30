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

import "./Ownable.sol";
import "../../openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../../openzeppelin/contracts/interfaces/IERC721.sol";
import "../../openzeppelin/contracts/interfaces/IERC20.sol";


/*
 * A smart contract that extends the UtilityVotingAndOwnable contract to provide financial management capabilities.
 * The contract allows for:
 * 1. Withdrawal of BNB to a designated address, which is the implementation address of an associated Proxy contract.
 * 2. Withdrawal of ERC20 tokens to the same designated address.
 * 3. Transfer of ERC721 tokens (NFTs) to the designated address.
 * All financial operations are restricted to the contract owner.
 */
abstract contract FinanceManager is IERC721Receiver, Ownable {

    /**
     * @dev Withdraws BNB from the contract to a designated address.
     * @param amount Amount of BNB to withdraw.
     */
    function withdrawMoney(uint256 amount) external onlyOwner {
        address payable recipient = payable(_recepient());
        require(address(this).balance >= amount, "FinanceManager: Contract has insufficient balance");
        recipient.transfer(amount);
    }

    /**
     * @dev Withdraws ERC20 tokens from the contract.
     * @param _tokenAddress The address of the ERC20 token contract.
     * @param _amount The amount of tokens to withdraw.
     */
    function withdrawERC20Tokens(address _tokenAddress, uint256 _amount) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        require(token.balanceOf(address(this)) >= _amount, "FinanceManager: Not enough tokens on contract balance");
        token.transfer(_recepient(), _amount);
    }

    /**
     * @dev Transfers an ERC721 token from this contract.
     * @param _tokenAddress The address of the ERC721 token contract.
     * @param _tokenId The ID of the token to transfer.
     */
    function withdrawERC721Token(address _tokenAddress, uint256 _tokenId) external onlyOwner {
        IERC721 token = IERC721(_tokenAddress);
        require(token.ownerOf(_tokenId) == address(this), "FinanceManager: The contract is not the owner of this token");
        token.safeTransferFrom(address(this), _recepient(), _tokenId);
    }

    /**
     * @dev Internal function to get the recipient address for withdrawals.
     * @return The address to which assets should be withdrawn.
     */
    function _recepient() private view returns (address) {
        address recepient = owner();
        if (address(_proxyContract()) != address(0)) {
            recepient = _proxyContract().implementation();
        }
        return recepient;
    }

    /**
     * @notice The onERC721Received function is used to process the receipt of ERC721 tokens.
     */
    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    
    receive() external payable {}
}
