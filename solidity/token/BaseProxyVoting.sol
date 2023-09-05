// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/access/Ownable.sol";

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


//A basic abstract contract containing public modifiers and private functions,
//emulates Ownable from Openzeppelin
abstract contract BaseProxyVoting is Ownable {
 
 // Proxy contract interface
 IProxy internal _proxyContract;

 // Returns the interface address of the proxy contract
 function getProxyAddress() public view returns (address) {
     return address(_proxyContract);
 }

 // Checks whether the address is among the owners of the proxy contract
 function _isProxyOwner(address senderAddress) internal view returns (bool) {
     return _proxyContract.isProxyOwner(senderAddress);
 }

 // Voting structure
 struct VoteResult {
     address[] isTrue;
     address[] isFalse;
     uint256 timestamp;
 }

 // Adds the voter's address to the corresponding list and also returns the total number of votes, upvotes and downvotes
 function _votes(VoteResult storage result, bool vote) internal returns (uint256, uint256, uint256) {
     uint256 _totalOwners = 1;
     if (address(_proxyContract) != address(0)) {
         _totalOwners = _proxyContract.getTotalOwners();
     } 
     if (vote) {
         result.isTrue.push(msg.sender);
     } else {
         result.isFalse.push(msg.sender);
     }
     return (result.isTrue.length, result.isFalse.length, _totalOwners);
 }

 // Clears structure after voting
 function _resetVote(VoteResult storage vote) internal {
     vote.isTrue = new address[](0);
     vote.isFalse = new address[](0);
     vote.timestamp = 0;
 }

 // Calls the poll structure cleanup function if 3 or more days have passed since it started
 function _closeVote(VoteResult storage vote) internal canClose(vote.timestamp) {
     _resetVote(vote);
 }

 // Checks whether the address is a contract that implements the IProxy interface
 function _checkIProxyContract(address contractAddress) internal view returns (bool) {

     if (Address.isContract(contractAddress)) {
         IERC165 targetContract = IERC165(contractAddress);
         return targetContract.supportsInterface(type(IProxy).interfaceId);
     }

     return false;
 }
 
 // Checks whether the address has voted
 function _hasOwnerVoted(VoteResult memory result, address targetAddress) internal pure returns (bool) {
     for (uint256 i = 0; i < result.isTrue.length; i++) {
         if (result.isTrue[i] == targetAddress) {
             return true;
         }
     }
     for (uint256 i = 0; i < result.isFalse.length; i++) {
         if (result.isFalse[i] == targetAddress) {
             return true;
         }
     }
     return false;
 }

 // Modifier that checks whether you are among the owners of the proxy smart contract and whether you have the right to vote
 modifier onlyProxyOwner(address senderAddress) {
     if (address(_proxyContract) != address(0)) {
         require(_isProxyOwner(senderAddress), "ProxyOwner: caller is not the proxy owner");
     } else {
         require(senderAddress == owner(), "ProxyOwner: caller is not the owner");
     }
     _;
 }

 // Modifier for checking whether 3 days have passed since the start of voting and whether it can be closed
 modifier canClose(uint256 timestamp) {
     require(block.timestamp >= timestamp + 3 days, "Owners: Voting is still open");
     _;
 }

 // A modifier that returns true if the given address has not yet been voted
 modifier hasNotVoted(VoteResult memory result) {
     require(!_hasOwnerVoted(result, msg.sender), "Owners: Already voted");
     _;
 }

 // This override function and is deactivated
 function renounceOwnership() public view override onlyOwner {
     revert("ProxyOwner: this function is deactivated");
 }
}


interface IProxy {
 function getToken() external view returns (IERC20);
 function getImplementation() external view returns (address);
 function isStopped() external view returns (bool);
 function getTotalOwners() external view returns (uint256);
 function isProxyOwner(address tokenAddress) external view returns (bool);
 function isOwner(address account) external view returns (bool);
 function getBalanceOwner(address owner) external view returns (uint256);
 function getTokensNeededForOwnership() external view returns (uint256);
 function isBlacklisted(address account) external view returns (bool);
 function depositTokens(uint256 amount) external;
 function voluntarilyExit() external;
 function withdrawExcessTokens() external;
 function rescueTokens(address tokenAddress) external;

 event VoluntarilyExit(address indexed votingSubject, uint returTokens);
}