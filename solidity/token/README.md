
# 🔗 Full implementation of the Anhydrite Smart Contract
---
<br>



### 📜 BaseProxyVoting Smart Contract Documentation
***


#### `getProxyAddress() -> address`

##### Description

- Returns the address of the `_proxyContract` currently set in the smart contract.

##### Parameters

- None

#### Returns

- `address`: The address of the `_proxyContract`.

---

#### `renounceOwnership()`

##### Description

- This function is overridden from the `Ownable` contract to deactivate its functionality. It will revert if called.

##### Parameters

- None

##### Returns

- Reverts with the message "ProxyOwner: this function is deactivated" if called.

---
<br>


### 📜 OwnableManager Smart Contract Documentation
***


#### `transferOwnership(address proposedOwner)`

##### Description

- Initiates the voting process for transferring the ownership of the contract to a proposed new owner.

##### Parameters

- **`proposedOwner`**: Address of the proposed new owner.

##### Conditions

- Can only be called by the proxy owner or the contract owner.
- No active voting for a new owner should be ongoing.
- If `_proxyContract` is set, the proposed owner should not be blacklisted and must be an owner of the proxy contract.

##### Effects

- Sets `_proposedOwner` and initiates the voting process.

---

#### `voteForNewOwner(bool vote)`

##### Description

- Casts a vote for the proposed new owner of the contract.

#### Parameters

- **`vote`**: A boolean representing the vote; `true` for approval and `false` for disapproval.

#### Conditions

- Can only be called by the proxy owner or the contract owner.

---

#### `closeVoteForNewOwner()`

##### Description

- Closes the ongoing voting process for the new proposed owner.

##### Conditions

- Can only be called by the current contract owner.
- There must be an active vote (`_proposedOwner` should not be zero address).

##### Effects

- Closes the voting and resets `_proposedOwner`.

---

#### `getActiveForVoteOwner() -> (bool, address)`

##### Description

- Checks if there is active voting for a new owner and returns the proposed new owner's address.

##### Conditions

- An active voting session must be ongoing.

##### Returns

- A boolean indicating if voting is active and the address of the proposed new owner.

---
<br>


### 📜 TokenManager Smart Contract Documentation
***


#### `initiateTransfer(address recepient, uint256 amount)`

Initiates a new voting process to transfer a certain amount of tokens to a specified recipient address.

##### Parameters

- `recepient`: The address of the recipient to whom the tokens will be transferred.
- `amount`: The number of tokens to transfer.

##### Conditions

- The function can only be called by the owner or a proxy owner.
- The `amount` parameter must not be zero.
- There should not be an active voting process already in place.

---

### `voteForTransfer(bool vote)`

#### Description

Casts a vote for or against the proposed token transfer.

##### Parameters

- `vote`: A boolean value where `true` stands for a vote in favor and `false` stands for a vote against.

##### Conditions

- The function can only be called by the owner or a proxy owner.
- An active vote for a token transfer must be in place.

---

### `closeVoteForTransfer()`

#### Description

Closes the active voting process for the token transfer.

##### Conditions

- The function can only be called by the owner.
- An active vote for a token transfer must be in place.

---

### `getActiveForVoteTransfer() -> (address, uint256)`

#### Description

Checks if there is an active voting process for a token transfer and returns the recipient and amount proposed.

##### Conditions

- An active vote for a token transfer must be in place.

##### Returns

- The recipient address and the amount of tokens proposed for the transfer.
---
<br>


### 📜 ProxyManager Smart Contract Documentation
***


#### `initiateNewProxy(address proposedNewProxy)`

##### Description
- Starts a new voting process to set a new proxy contract address.

##### Parameters
- **proposedNewProxy**: The proposed new proxy contract address.

##### Conditions
- Can only be called by the proxy owner.
- Voting for a new proxy must not already be active.

---

#### `voteForNewProxy(bool vote)`

##### Description
- Allows owners to cast their vote for or against setting a new proxy contract.

##### Parameters
- **vote**: A boolean value indicating a vote for (`true`) or against (`false`) the proposed new proxy.

##### Conditions
- Can only be called by the proxy owner.
- An active voting process must be in place.

---

#### `closeVoteForNewProxy()`

##### Description
- Closes the active voting process for setting a new proxy contract.

##### Conditions
- Can only be called by the contract owner.
- An active voting process must be in place.

---

#### `getActiveForVoteNewProxy() -> (bool, address)`

##### Description
- Checks if there's an active voting process for setting a new proxy contract and returns the proposed address.

##### Returns
- A boolean indicating whether a vote is active and the address of the proposed new proxy.

##### Conditions
- An active voting process must be in place.

---
<br>


### 📜 FinanceManager Smart Contract Documentation
***


#### `withdrawMoney(uint256 amount)`

##### Description
- Allows the contract owner to withdraw a specified amount of Ether from the contract.

##### Parameters
- **amount**: The amount of Ether to withdraw.

##### Conditions
- Can only be called by the contract owner.
- The contract must have sufficient balance.

---

#### `withdrawERC20Tokens(address _tokenAddress, uint256 _amount)`

##### Description
- Allows the contract owner to withdraw a specified amount of ERC20 tokens from the contract.

##### Parameters
- **_tokenAddress**: The contract address of the ERC20 token.
- **_amount**: The number of tokens to withdraw.

##### Conditions
- Can only be called by the contract owner.
- The contract must have sufficient token balance.

---

#### `withdrawERC721Token(address _tokenAddress, uint256 _tokenId)`

##### Description
- Allows the contract owner to transfer ownership of a specified ERC721 token from the contract to another address.

##### Parameters
- **_tokenAddress**: The contract address of the ERC721 token.
- **_tokenId**: The ID of the ERC721 token to withdraw.

##### Conditions
- Can only be called by the contract owner.
- The contract must be the owner of the specified ERC721 token.

---
<br>



## 💎 Anhydrite Smart Contract Documentation
***

The Anhydrite smart contract is an ERC20 token contract with additional functionalities for managing finances and token burning.

### Table of Contents

- [Constants](#constants)
- [Constructor](#constructor)
- [Public Functions](#public-functions)
- [Internal Functions](#internal-functions)
- [Interfaces](#interfaces)

---

### Constants

#### `MAX_SUPPLY`

- **Type**: `uint256`
- **Description**: The maximum supply for the Anhydrite token. Set at 360,000,000 tokens.

#### `ERC20ReceivedMagic`

- **Type**: `bytes4`
- **Description**: A magic value for validating ERC20 token transfers to contract addresses.

---

### Constructor

#### `constructor()`

- **Description**: Initializes the token with the name "Anhydrite" and symbol "ANH". Mints 70,000,000 tokens.

---

### Public Functions

#### `getMaxSupply() -> uint256`

- **Description**: Returns the maximum possible supply of the Anhydrite token.
  
---

#### `transferForProxy(uint256 amount)`

- **Parameters**: 
  - `amount`: The amount of tokens to transfer.
  
- **Description**: Allows the proxy smart contract to activate this feature to transfer a specified amount of tokens.

- **Conditions**: 
  - Can only be called by the proxy smart contract.
  
---

#### `transfer(address to, uint256 amount) -> bool`

- **Parameters**:
  - `to`: Recipient address.
  - `amount`: The amount to transfer.

- **Description**: Transfers tokens to the specified address and invokes `_onERC20Received` function.

- **Returns**: 
  - `true`: If the operation is successful.

---

#### `transferFrom(address from, address to, uint256 amount) -> bool`

- **Parameters**:
  - `from`: Source address.
  - `to`: Destination address.
  - `amount`: The amount to transfer.

- **Description**: Transfers tokens from one address to another and invokes `_onERC20Received` function.

- **Returns**: 
  - `true`: If the operation is successful.

---

### Internal Functions

#### `_transferFor(address recipient, uint256 amount)`

- **Description**: Handles token transfers internally. Prioritizes transferring from contract's balance; if insufficient, mints new tokens.

- **Conditions**:
  - The total minted tokens must not exceed `MAX_SUPPLY`.

---

#### `_mint(address account, uint256 amount)`

- **Description**: Overrides the `_mint` function from the ERC20 standard. Ensures the total minted tokens do not exceed `MAX_SUPPLY`.

---

#### `_onERC20Received(address _to, uint256 _amount)`

- **Description**: Validates if the receiving contract can handle ERC20 tokens using ERC165.

---

### Interfaces

- `IProxy`
- `IERC20Receiver`


