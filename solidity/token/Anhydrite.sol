// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/*
 * Copyright (C) 2023 Anhydrite Gaming Ecosystem
 *
 * This code is part of the Anhydrite Gaming Ecosystem.
 *
 * ERC-20 Token: Anhydrite ANH
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
* VotingOwner is the only way to change the owner of a smart contract.
* The standard Ownable owner change functions from OpenZeppelin are blocked.
*/

abstract contract VotingOwner is Ownable {
    
    IProxy internal _proxyContract;

    struct VoteResult {
        address[] isTrue;
        address[] isFalse;
        uint256 timestamp;
    }

    address internal _proposedOwner;
    VoteResult internal _votesForNewOwner;

    event VotingForOwner(address indexed voter, address votingSubject, bool vote);
    event VotingOwnerCompleted(address indexed voter, address votingSubject, bool vote, uint votesFor, uint votesAgainst);

    constructor(address proxyAddress) {
        _proxyContract = IProxy(proxyAddress);
    }

    // Please provide the address of the new owner for the smart contract.
    function proposedVoteForOwner(address proposedOwner) external onlyProxyOwner(msg.sender) {
        require(!_isActiveForVoteOwner(), "VotingOwner: voting is already activated");
        require(!_proxyContract.isBlacklisted(proposedOwner), "VotingOwner: this address is blacklisted");
        require(_isProxyOwner(proposedOwner), "VotingOwner: caller is not the proxy owner");

        _proposedOwner = proposedOwner;
        _votesForNewOwner = VoteResult(new address[](0), new address[](0), block.timestamp);
        _voteForNewOwner(true);
    }

    function voteForNewOwner(bool vote) external onlyProxyOwner(_proposedOwner) {
        _voteForNewOwner(vote);
    }

    // Voting for the address of the new owner of the smart contract
    function _voteForNewOwner(bool vote) internal {
        require(_isActiveForVoteOwner(), "VotingOwner: there are no votes at this address");

        if (vote) {
            _votesForNewOwner.isTrue.push(msg.sender);
        } else {
            _votesForNewOwner.isFalse.push(msg.sender);
        }

        uint256 _totalOwners = _proxyContract.getTotalOwners();

        uint votestrue = _votesForNewOwner.isTrue.length;
        uint votesfalse = _votesForNewOwner.isFalse.length;

        emit VotingForOwner(msg.sender, _proposedOwner, vote);

        if (votestrue * 100 >= _totalOwners * 60) {
            _transferOwnership(_proposedOwner);
            _resetVote(_votesForNewOwner);
            emit VotingOwnerCompleted(msg.sender, _proposedOwner, vote, votestrue, votesfalse);
            _proposedOwner = address(0);
        } else if (votesfalse * 100 > _totalOwners * 40) {
            _resetVote(_votesForNewOwner);
            emit VotingOwnerCompleted(msg.sender, _proposedOwner, vote, votestrue, votesfalse);
            _proposedOwner = address(0);
        }
    }

    // Check if voting is enabled for new contract owner and their address.
    function getActiveForVoteOwner() external view returns (bool, address) {
        require(_isActiveForVoteOwner(), "VotingOwner: re is no active voting");
        return (_isActiveForVoteOwner(), _proposedOwner);
    }

    function _isActiveForVoteOwner() internal view returns (bool) {
        return _proposedOwner != address(0) && _proposedOwner !=  owner();
    }

    function _resetVote(VoteResult storage vote) internal {
        vote.isTrue = new address[](0);
        vote.isFalse = new address[](0);
        vote.timestamp = 0;
    }

    function _isProxyOwner(address senderAddress) internal view returns (bool) {
        return _proxyContract.isProxyOwner(senderAddress);
    }

    // Modifier that checks whether you are among the owners of the proxy smart contract and whether you have the right to vote
    modifier onlyProxyOwner(address senderAddress) {
        require(_isProxyOwner(senderAddress), "VotingOwner: caller is not the proxy owner");
        _;
    }

    // The renounceOwnership() function is blocked
    function renounceOwnership() public override onlyOwner onlyProxyOwner(msg.sender) {
        bool deact = false;
        require(deact, "VotingOwner: this function is deactivated");
        _transferOwnership(owner());
    }

    // The transferOwnership(address newOwner) function is blocked
    function transferOwnership(address newOwner) public override onlyOwner onlyProxyOwner(msg.sender) {
        bool deact = false;
        require(deact, "VotingOwner: this function is deactivated");
        require(newOwner != address(0), "VotingOwner: new owner is the zero address");
        _transferOwnership(owner());
    }
}

abstract contract Finances is VotingOwner {

   /// @notice Function for transferring Ether
    function withdrawMoney(uint256 amount) external onlyOwner {
        address payable recipient = payable(_proxyContract.getImplementation());
        require(address(this).balance >= amount, "Contract has insufficient balance");
        recipient.transfer(amount);
    }

    /// @notice Function for transferring ERC20 tokens
    function withdraERC20Tokens(address _tokenAddress, uint256 _amount) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        require(token.balanceOf(address(this)) >= _amount, "Not enough tokens on contract balance");
        token.transfer(_proxyContract.getImplementation(), _amount);
    }

    /// @notice Function for transferring ERC721 tokens
    function withdraERC721Token(address _tokenAddress, uint256 _tokenId) external onlyOwner {
        IERC721 token = IERC721(_tokenAddress);
        require(token.ownerOf(_tokenId) == address(this), "The contract is not the owner of this token");
        token.safeTransferFrom(address(this), _proxyContract.getImplementation(), _tokenId);
    }

}

contract Anhydrite is Finances, ERC20, ERC20Burnable {
    using ERC165Checker for address;

    address private _permitted;

    constructor(address proxy_) ERC20("Anhydrite", "ANH") VotingOwner(proxy_) {
        _mint(address(this), 70000000 * 10 ** decimals());
    }

    function setPermitedContract(address to) public onlyOwner onlyProxyOwner(msg.sender) {
        // require(!_permitted[to], "Anhydrite: this Pyramid already has permission");
        _permitted = to;
    }

    function getTokens(uint256 amount) public {
        require(msg.sender == _proxyContract.getImplementation(), "Anhydrite: unauthorized call");
        if (balanceOf(address(this)) >= amount) {
            _transfer(address(this), msg.sender, amount);
        } else {
            _mint(msg.sender, amount);
        }
    }

}

interface IProxy {
    function getImplementation() external view returns (address);
    function getTotalOwners() external view returns (uint256);
    function isBlacklisted(address account) external view returns (bool);
    function isProxyOwner(address tokenAddress) external view returns (bool);
}