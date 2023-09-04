# Full implementation of the Anhydrite smart contract
---

## BaseProxyVoting


## Functions

### `getProxyAddress() -> address`

#### Description

- Returns the address of the `_proxyContract` currently set in the smart contract.

#### Parameters

- None

#### Returns

- `address`: The address of the `_proxyContract`.

---

### `renounceOwnership()`

#### Description

- This function is overridden from the `Ownable` contract to deactivate its functionality. It will revert if called.

#### Parameters

- None

#### Returns

- Reverts with the message "ProxyOwner: this function is deactivated" if called.

---
---

## OwnableManager
---

## Public Functions

---

### `transferOwnership(address proposedOwner)`

#### Description

- Initiates the voting process for transferring the ownership of the contract to a proposed new owner.

#### Parameters

- **`proposedOwner`**: Address of the proposed new owner.

#### Conditions

- Can only be called by the proxy owner or the contract owner.
- No active voting for a new owner should be ongoing.
- If `_proxyContract` is set, the proposed owner should not be blacklisted and must be an owner of the proxy contract.

#### Effects

- Sets `_proposedOwner` and initiates the voting process.

---

### `voteForNewOwner(bool vote)`

#### Description

- Casts a vote for the proposed new owner of the contract.

#### Parameters

- **`vote`**: A boolean representing the vote; `true` for approval and `false` for disapproval.

#### Conditions

- Can only be called by the proxy owner or the contract owner.

---

### `closeVoteForNewOwner()`

#### Description

- Closes the ongoing voting process for the new proposed owner.

#### Conditions

- Can only be called by the current contract owner.
- There must be an active vote (`_proposedOwner` should not be zero address).

#### Effects

- Closes the voting and resets `_proposedOwner`.

---

### `getActiveForVoteOwner() -> (bool, address)`

#### Description

- Checks if there is active voting for a new owner and returns the proposed new owner's address.

#### Conditions

- An active voting session must be ongoing.

#### Returns

- A boolean indicating if voting is active and the address of the proposed new owner.
