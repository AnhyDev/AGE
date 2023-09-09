// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

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

//Base contract for utility and ownership functionalities
abstract contract BaseUtilityAndOwnable is IERC721Receiver, IERC165 {

 // Main project token (ANH) address
 IANH internal constant ANHYDRITE = IANH(0xE30B7FC00df9016E8492e71760169BB66Fc6f77C);
 // Global contract (AGE) address
 address internal _implementAGE;
 // Tokens required for ownership rights
 uint256 internal _tokensNeededForOwnership;

 // The total number of owners
 uint256 internal _totalOwners;
 // Owner status mapping
 mapping(address => bool) internal _owners;
 // Owner token balance mapping
 mapping(address => uint256) internal _balanceOwner;
 // Owners under exclusion vote
 mapping(address => bool) internal _isOwnerVotedOut;
 // Blacklisted addresses
 mapping(address => bool) internal _blackList;

 // Voting outcome structure
 struct VoteResult {
     address[] isTrue;
     address[] isFalse;
     uint256 timestamp;
 }

 // Service status flags
 bool internal _stopped = false;
 bool internal _proposedStopped = false;
 VoteResult internal _votesForStopped;

 mapping(bytes4 => bool) internal supportedInterfaces;

 constructor() {
     supportedInterfaces[0x01ffc9a7] = true;
     supportedInterfaces[type(IProxy).interfaceId] = true;
 }


 // Realization ERC165
 function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
     return supportedInterfaces[interfaceId];
 }

 // Returns global contract (AGE) address
 function _implementation() internal view returns (address){
     return _implementAGE;
 }

 // Adds vote and returns vote counts 
 function _votes(VoteResult storage result, bool vote) internal returns (uint256, uint256) {
     if (vote) {
         result.isTrue.push(msg.sender);
     } else {
         result.isFalse.push(msg.sender);
     }
     return (result.isTrue.length, result.isFalse.length);
 }

 // Returns vote details
 function _getVote(VoteResult memory vote, address addresess) internal pure returns (address, uint256, uint256, uint256) {
     return (
         addresess, 
         vote.isTrue.length, 
         vote.isFalse.length, 
         vote.timestamp
     );
 }
 
 // Resets vote counts after voting
 function _resetVote(VoteResult storage vote) internal {
     _increaseByPercent(vote.isTrue, vote.isFalse);
     vote.isTrue = new address[](0);
     vote.isFalse = new address[](0);
     vote.timestamp = 0;
 }

 // Closes voting after 3 days
 function _closeVote(VoteResult storage vote) internal canClose(vote.timestamp) {
     _resetVote(vote);
     _increaseByPercent(msg.sender);
 }

 // Increases interest for specific owner
 function _increaseByPercent(address recepient) internal {
     uint256 percent = _tokensNeededForOwnership * 1 / 100;
     _balanceOwner[recepient] += percent;
 }

 // Increases interest for voting participants
 function _increaseByPercent(address[] memory addresses1, address[] memory addresses2) internal {
     for (uint256 i = 0; i < addresses1.length; i++) {
         _increaseByPercent(addresses1[i]);
     }

     for (uint256 j = 0; j < addresses2.length; j++) {
         _increaseByPercent(addresses2[j]);
     }
 }
 
 // Checks if the owner has voted
 function _hasOwnerVoted(VoteResult memory addresses, address targetAddress) internal pure returns (bool) {
     for (uint256 i = 0; i < addresses.isTrue.length; i++) {
         if (addresses.isTrue[i] == targetAddress) {
             return true;
         }
     }
     for (uint256 i = 0; i < addresses.isFalse.length; i++) {
         if (addresses.isFalse[i] == targetAddress) {
             return true;
         }
     }
     return false;
 }

 // Validates owner's voting rights
 function _isProxyOwner(address ownerAddress) internal view returns (bool) {
     return _owners[ownerAddress] 
     && !_isOwnerVotedOut[ownerAddress]
     && _balanceOwner[ownerAddress] >= _tokensNeededForOwnership;
 }

 // Modifier for checking whether 3 days have passed since the start of voting and whether it can be closed
 modifier canClose(uint256 timestamp) {
     require(block.timestamp >= timestamp + 3 days, "BaseUtilityAndOwnable: Voting is still open");
     _;
 }

 // Modifier to check if the owner has the right to vote on this issue,
 // that is, whether he has not voted before, and whether his deposit corresponds to the amount required for the right to vote
 modifier hasNotVoted(VoteResult memory result) {
     require(!_hasOwnerVoted(result, msg.sender), "BaseUtilityAndOwnable: Already voted");
     _;
 }

 // A modifier that checks whether an address is in the list of owners, and whether a vote for exclusion is open for this address
 modifier onlyOwner() {
     require(_isProxyOwner(msg.sender), "BaseUtilityAndOwnable: Not an owner");
     _;
 }

 // Handles received NFTs and forwards them
 function onERC721Received(address, address, uint256 tokenId, bytes calldata) external override returns (bytes4) {
     require(IERC165(msg.sender).supportsInterface(0x80ac58cd), "BaseUtilityAndOwnable: Sender does not support ERC-721");

     IERC721(msg.sender).safeTransferFrom(address(this), _implementation(), tokenId);
     return this.onERC721Received.selector;
 }

 // Checks if a contract implements a specific IAGE interface
 function _checkContract(address contractAddress) internal view returns (bool) {
     return IERC165(contractAddress).supportsInterface(type(IAGE).interfaceId);
 }
}

//Interface to ensure that the global contract follows certain standards.
interface IAGE {
 // Gets the version of the global contract.
 function getVersion() external pure returns (uint256);
 // Adds a price.
 function addPrice(string memory name, uint256 count) external;
 // Gets a price.
 function getPrice(string memory name) external view returns (uint256);
 // Gets the server address from a token ID.
 function getServerFromTokenId(uint256 tokenId) external view returns (address);
 // Gets a token ID from a server address.
 function getTokenIdFromServer(address serverAddress) external view returns (uint256);
}

//Interface for interacting with the Anhydrite contract.
interface IANH is IERC20 {
 // Gets the max supply of the token.
 function getMaxSupply() external pure returns (uint256);
 // Transfers tokens for the proxy.
 function transferForProxy(uint256 amount) external;
}
