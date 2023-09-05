// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
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



//Anhydrite smart contract implementation, ERC-20 standard with advanced features
contract Anhydrite is FinanceManager, TokenManager, ProxyManager, OwnableManager, ERC20, ERC20Burnable {
 using ERC165Checker for address;

 // Sets the maximum allowed supply of tokens is 360 million
 uint256 private constant MAX_SUPPLY = 360000000 * 10 ** 18;
 // The magic identifier for the ability in the external contract to cancel the token acquisition transaction
 bytes4 constant ERC20ReceivedMagic = bytes4(keccak256("onERC20Received(address,address,uint256)"));

 // Confirm receipt and handling of Anhydrite tokens by external IERC20Receiver contract
 event AnhydriteTokensReceivedProcessed(address indexed from, address indexed who, address indexed receiver, uint256 amount);

 constructor() ERC20("Anhydrite", "ANH") {
     _mint(address(this), 70000000 * 10 ** decimals());
 }

 // Returns the maximum token supply allowed
 function getMaxSupply() public pure returns (uint256) {
     return MAX_SUPPLY;
 }

 // Sending tokens on request from the smart contract proxy to its address
 function transferForProxy(uint256 amount) public {
     address proxy = address(_proxyContract);
     require(_msgSender() == proxy, "Anhydrite: Only a proxy smart contract can activate this feature");
     _transferFor(proxy, amount);
 }

 // Setting which smart contract overrides the transferOwnership function
 function transferOwnership(address proposedOwner) public override (Ownable, OwnableManager) {
     OwnableManager.transferOwnership(proposedOwner);
 }

 // Implemented _transferFor function checks token presence, sends to recipient, and mints new tokens if necessary, but not exceeding max supply.
 function _transferFor(address recepient, uint256 amount) internal override {
     if (balanceOf(address(this)) >= amount) {
         _transfer(address(this), recepient, amount);
     } else if (totalSupply() + amount <= MAX_SUPPLY && recepient != address(0)) {
         _mint(recepient, amount);
     }
 }

 /* Private function to add the ability for the external contract to handle the receive token event.
  * For this, the external contract must inheritance the IERC20Receiver interface and implement the function
  * function onERC20Received(address _from, address _who, uint256 _amount) external returns (bytes4);
  * In the body of this function, process the event and send back the magic ID of the interface.
  *
  * If the contract does not implement the IERC20Receiver interface, or if the event handling throws an exception
  * this function will be ignored and the transaction will continue.
  *
  * In order to roll back the entire transaction, the outer contract must return false
  * magic id.
  *
  * Valid magic ID: return bytes4(keccak256("onERC20Received(address,address,uint256)"));
  * Invalid magic ID: return bytes4(keccak256("anything_else"));
  */
 function _onERC20Received(address _from, address _to, uint256 _amount) private {
     if (Address.isContract(_to)) {
         bytes memory data = abi.encodeWithSelector(ERC20ReceivedMagic, _from, _msgSender(), _amount);

         (bool success, bytes memory returnData) = _to.call(data);

         if (success && returnData.length > 0) {
             bytes4 retval = abi.decode(returnData, (bytes4));
             require(retval == ERC20ReceivedMagic, "Anhydrite: An invalid magic ID was returned");
             emit AnhydriteTokensReceivedProcessed(_from, _msgSender(), _to, _amount);
         }
     }
 }

 // Redefined function _afterTokenTransfer, to which the execution of the function _onERC20Received was added,
 // if the sender and receiver of the tokens are not a address(0)
 function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual override {
     if(from != address(0) && to != address(0)) {
     _onERC20Received(from, to, amount);
     }
 }

 // The _mint function has been redefined, to which a limit on the maximum supply of tokens has been added
 function _mint(address account, uint256 amount) internal virtual override {
     require(totalSupply() + amount <= MAX_SUPPLY, "Anhydrite: MAX_SUPPLY limit reached");
     super._mint(account, amount);
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

interface IERC20Receiver {
 function onERC20Received(address _from, address _who, uint256 _amount) external returns (bytes4);
}
