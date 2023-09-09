## AnhydriteProxyOwners Smart Contract Documentation

### Overview

The AnhydriteProxyOwners smart contract is designed to manage ownership, voting, and token interaction within the Anhydrite Gaming Ecosystem. This contract is part of a larger system and operates on the Binance Smart Chain. It primarily focuses on implementing a system for managing owners, allowing voluntary exit of an owner, transferring the native Anhydrite (ANH) tokens, and rescuing accidentally sent tokens. The contract also incorporates multiple voting mechanisms related to governance.

### Components

The contract is built by extending multiple contracts and interfaces:
- [**Proxy**: Manages the current logic implementation address for upgradeable contracts.](#proxy)
- [**VotingStopped**: Mechanism to stop services.](#votingstopped)
- [**VotingNeededForOwnership**: Voting logic for becoming an owner.](#votingneededforownership)
- [**VotingNewImplementation**: Voting logic for changing the logic implementation of the Proxy.](#votingnewimplementation)
- [**VotingNewOwner**: Voting logic for adding a new owner.](#votingnewowner)
- [**VotingRemoveOwner**: Voting logic for removing an existing owner.](#votingremoveowner)
- [**IERC20Receiver**: Interface for contracts capable of receiving ERC20 tokens.](#ierc20receiver)

### Functionalities

#### Initialization

The constructor sets the initial implementation address to zero, designates the contract creator as the first owner, and sets the number of tokens needed for ownership to `100000 * 10 ** 18`.

#### Voluntary Exit (`voluntarilyExit`)

Owners can voluntarily exit from their position. On exiting, if the owner has any Anhydrite tokens deposited, those tokens will be returned. The function will also emit an `VoluntarilyExit` event. If there are no remaining owners, the remaining balance of Anhydrite tokens will be sent back to the ANHYDRITE contract.

#### Withdraw Excess Tokens (`withdrawExcessTokens`)

Owners can withdraw excess tokens from their deposit. Excess tokens are the tokens that exceed the minimum required for ownership. 

#### Internal Token Transfer (`_transferTokens`)

A helper function for handling the internal mechanics of transferring tokens. It takes care of the transfer process and ensures that the balances are updated accordingly.

#### Rescue Tokens (`rescueTokens`)

This function enables an owner to rescue any ERC20 tokens that are accidentally sent to the contract. However, it does not allow the rescue of Anhydrite tokens (native token).

#### Receiving Tokens (`onERC20Received`)

Implements the `IERC20Receiver` interface and handles received ERC20 tokens. If the sender is the Anhydrite token contract and the receiver is an owner, the owner's balance will be updated.

### Events

- **VoluntarilyExit**: Emitted when an owner voluntarily exits. Provides the address of the exiting owner and the number of tokens returned.
- **DepositAnhydrite**: Emitted when Anhydrite tokens are deposited. Provides the sender and receiver addresses and the amount of tokens.

### Limitations and Risks

The contract is provided as-is, without any warranties. Use it at your own risk.

## Contact

For detailed terms and more information, please contact the Anhydrite Gaming Ecosystem team at their official website [https://anh.ink](https://anh.ink).

### License

MIT License. See the source code for detailed licensing information.
***

<br>
<br>

## BaseUtilityAndOwnable

### Table of Contents

1. [Overview](#overview)
2. [Constants and State Variables](#constants-and-state-variables)
3. [Structs](#structs)
4. [Methods](#methods)
5. [Modifiers](#modifiers)

---

### Overview

The `BaseUtilityAndOwnable` contract serves as the foundational layer for a smart contract system that integrates various functionalities like utility services, ownership, and interface compatibility. This contract handles ownership rights based on token balances, implements voting mechanisms, and supports specific interface checks.

---

### Constants and State Variables

#### Constants

- `ANHYDRITE`: The main project token (IANH interface), used primarily for determining ownership rights.

#### State Variables

- `_implementAGE`: Address of the Global contract (AGE).
- `_tokensNeededForOwnership`: Amount of tokens required to attain ownership status.
- `_totalOwners`: Total number of owners.
- `_owners`: Mapping to track ownership status.
- `_balanceOwner`: Mapping to track token balance for each owner.
- `_isOwnerVotedOut`: Mapping to track whether an owner is under exclusion vote.
- `_blackList`: Mapping of blacklisted addresses.
- `_stopped`: Boolean flag indicating the service status.
- `_votesForStopped`: Struct to hold vote outcomes for stopping the service.

---

### Structs

- `VoteResult`: Stores the result of a vote with arrays for addresses that voted true or false and the timestamp when the vote was initiated.

---

### Methods

#### Public and External Methods

- `supportsInterface`: Implementation of the ERC165 standard to check supported interfaces.
- `onERC721Received`: Handles received NFTs and forwards them to the implementation contract.

#### Internal Methods

- `_implementation`: Returns the Global contract (AGE) address.
- `_votes`: Adds a vote and returns the current vote counts.
- `_getVote`: Returns details of a vote.
- `_resetVote`: Resets vote counts.
- `_closeVote`: Closes voting after 3 days.
- `_increaseByPercent`: Increases the interest rate for specific owners or arrays of owners.
- `_hasOwnerVoted`: Checks if an owner has voted in a particular vote.
- `_isProxyOwner`: Validates if an address is a proxy owner based on certain conditions.
- `_checkContract`: Checks if a contract implements a specific IAGE interface.

---

### Modifiers

- `canClose`: Checks if 3 days have passed since the vote started.
- `hasNotVoted`: Ensures an owner has not voted on the issue.
- `onlyOwner`: Restricts access to proxy owners.

---


***

<br>
<br>

## VotingStopped

### Overview

The `VotingStopped` contract is an abstract contract that extends `BaseUtilityAndOwnable`. This contract is specifically designed for initiating, managing, and finalizing votes to stop or resume services within a given ecosystem.

### Contract Events

- `VotingForStopped`: Emitted when an owner votes for stopping/resuming services.
- `VotingCompletedForStopped`: Emitted when the vote is completed with a decisive outcome.
- `CloseVoteForStopped`: Emitted when the voting period has expired and the vote is manually closed.

### Functionalities

#### `initiateVotingForStopped(bool _proposed)`

- Initiates a vote for stopping or resuming services.
- Only an owner can call this function.
- Requires that the proposed state is different from the current state and no other similar vote is active.
- Sets the `_proposedStopped` flag and the timestamp for the vote.

#### `voteForStopped(bool vote)`

- Allows an owner to vote for stopping or resuming services.
- Calls the internal function `_voteForStopped`.

#### `_voteForStopped(bool vote)`

- Handles the logic for the voting mechanism.
- Updates vote counts in the `_votesForStopped` struct.
- Emits the `VotingForStopped` event.
- Checks if a decisive outcome is reached to either stop or resume services, then emits `VotingCompletedForStopped` event.

#### `closeVoteForStopped()`

- Manually closes the vote if the voting period is expired.
- Resets `_votesForStopped` and sets `_proposedStopped` to `_stopped`.
- Emits `CloseVoteForStopped` event.

### `getVoteForStopped()`

- Returns the current status of the vote including:
  - Whether a vote is currently active (`_proposedStopped != _stopped`).
  - The number of votes for and against the proposal.
  - The timestamp when the vote was initiated.


***

<br>
<br>

## VotingNeededForOwnership

### Overview

The `VotingNeededForOwnership` contract is an abstract extension of `BaseUtilityAndOwnable`. This contract is designed to initiate, manage, and finalize voting rounds aimed at changing the required token count needed for ownership rights.

### Contract Events

- `VotingForTokensNeeded`: Emitted when an owner casts their vote.
- `VotingCompletedForTokensNeeded`: Emitted when a decisive outcome has been reached in a voting round.
- `CloseVoteForTokensNeeded`: Emitted when a voting round is manually closed.

### Functionalities

#### `initiateVotingForNeededForOwnership(uint256 _proposed)`

- Initiates a voting round for setting a new required token count for ownership rights.
- Access restricted to contract owners.
- Pre-requisites:
  - Proposed token count must be greater than zero.
  - Proposed token count must differ from the current token count.
  - No active voting on the same issue should be occurring.
- Sets `_proposedTokensNeeded` and marks the timestamp.

#### `voteForNeededForOwnership(bool vote)`

- Allows an owner to cast their vote.
- Invokes `_voteForNeededForOwnership` internally to handle voting logic.

#### `_voteForNeededForOwnership(bool vote)`

- Internal function that handles vote counting and resolution.
- Conditions:
  - Voting round must be active (`_proposedTokensNeeded != 0`).
- Emits `VotingForTokensNeeded` upon a cast vote.
- Checks whether a decisive majority is reached:
  - If yes, updates `_tokensNeededForOwnership` and resets the vote.
  - If no, resets the vote without making changes.
  
#### `closeVoteForTokensNeeded()`

- Allows an owner to manually close the voting round.
- Preconditions:
  - Voting must be active (`_proposedTokensNeeded != 0`).
- Resets the voting round and emits `CloseVoteForTokensNeeded`.

#### `getVoteForNewTokensNeeded()`

- Returns:
  - The proposed new token count (`_proposedTokensNeeded`).
  - The number of affirmative and negative votes.
  - The timestamp of when the voting round was initiated.


***

<br>
<br>

## VotingNewImplementation

### Overview

The `VotingNewImplementation` smart contract is an abstract extension of `BaseUtilityAndOwnable`. It allows owners to initiate, participate in, and finalize voting rounds to change the current contract implementation.

### Contract Events

- `VotingForNewImplementation`: Emitted when a vote has been cast by an owner.
- `VotingCompletedForNewImplementation`: Emitted when the voting has been completed.
- `CloseVoteForNewImplementation`: Emitted when the voting has been manually closed.

### Functionalities

#### `initiateVotingForNewImplementation(address _proposed)`

- Initiates a new round of voting for a new implementation.
- Access restricted to owners only.
- Pre-requisites:
  - The proposed address should not be null.
  - Should be different from the current implementation.
  - There should not be an active vote for a new implementation.
  - The proposed address must meet certain standards (`_checkContract`).
- Sets `_proposedImplementation` and the voting timestamp.

#### `voteForNewImplementation(bool vote)`

- Allows an owner to cast their vote for or against the proposed implementation.
- Invokes `_voteForNewImplementation()` internally.

#### `_voteForNewImplementation(bool vote)`

- Internal function that handles the voting logic.
- Pre-requisites:
  - An active voting round should exist.
- Emits `VotingForNewImplementation` event.
- Checks for voting outcome:
  - If in favor, updates the implementation.
  - If against, resets the voting round.
  
#### `closeVoteForNewImplementation()`

- Allows an owner to manually close an active voting round.
- Pre-requisites:
  - An active voting round should exist.
- Resets the voting state and emits `CloseVoteForNewImplementation`.

#### `getVoteForNewImplementationStatus()`

- Returns the current status of voting.
- Returns:
  - Proposed new implementation address.
  - Number of affirmative and negative votes.
  - Timestamp of the initiation of the voting round.


***

<br>
<br>

## VotingNewOwner

### Overview

The `VotingNewOwner` smart contract is an abstract extension of `BaseUtilityAndOwnable`. The contract aims to facilitate a democratic approach to adding new owners to the contract. Existing owners can vote for or against a proposed new owner.

### Contract Events

- `InitiateOwnership`: Emitted when someone initiates a request to become an owner.
- `VotingForNewOwner`: Emitted when an owner casts a vote for or against the proposed new owner.
- `VotingCompletedForNewOwner`: Emitted when the voting round has been decided.
- `CloseVoteForNewOwner`: Emitted when an owner manually closes the voting.

### Functionalities

#### `initiateOwnershipRequest()`

- Any address can initiate a request to become an owner.
- Restrictions:
  - The address should not already be an owner.
  - Should not be on a blacklist.
  - Voting on this issue shouldn't already be underway, or if it is, it should be past its expiry.
  - There should be a gap of 30 days since the last initiation by the same address.
- Sets `_proposedOwner` and initializes the votes.

#### `voteForNewOwner(bool vote)`

- Allows an existing owner to vote for or against adding the proposed new owner.
- Access restricted to current owners only.
- Pre-requisites:
  - An active voting round should exist.
- Updates the votes and checks if a decision has been reached.

#### `closeVoteForNewOwner()`

- Manually closes the active voting round.
- Access restricted to current owners.
- Pre-requisites:
  - An active voting round should exist.
- Resets the voting status.

#### `getVoteForNewOwnerStatus()`

- Returns the current status of the voting round.
- Provides:
  - Proposed new owner's address.
  - Number of affirmative and negative votes.
  - Timestamp of the voting round initiation.


***

<br>
<br>

## VotingRemoveOwner

### Overview

The `VotingRemoveOwner` contract is an abstract extension of `BaseUtilityAndOwnable`. The contract facilitates a democratic process for removing existing owners. Only current owners have the ability to initiate the voting process and cast votes.

## Contract Events

- `VotingForRemoveOwner`: Triggered when an owner casts a vote to remove the proposed owner.
- `VotingCompletedForRemoveOwner`: Triggered when a decision has been made through voting.
- `CloseVoteForRemoveOwner`: Triggered when a vote is forcibly closed before reaching a decision.

### Functionalities

#### `initiateVotingForRemoveOwner(address _proposed)`

- Initiates a voting process to remove an owner.
- Parameters:
  - `_proposed`: The address proposed to be removed from ownership.
- Access restricted to current owners.
- Pre-conditions:
  - The proposed address must not be null.
  - The proposed address must be an existing owner.
- Automatically casts a "Yes" vote from the initiator.

#### `voteForRemoveOwner(bool vote)`

- Allows an existing owner to vote for or against removing the proposed owner.
- Parameters:
  - `vote`: A boolean value representing the vote (`true` for removal, `false` for retention).
- Access restricted to current owners.
- Pre-conditions:
  - A voting round must be active.
  - The owner cannot vote to remove themselves.
  
#### `_voteForRemoveOwner(bool vote)`

- Internal function that handles the voting logic.
- Parameters:
  - `vote`: A boolean value representing the vote (`true` for removal, `false` for retention).
- Updates the votes and checks if a decision has been reached.

#### `closeVoteForRemoveOwner()`

- Allows an existing owner to forcibly close an open voting round without reaching a decision.
- Access restricted to current owners.
- Pre-conditions:
  - A voting round must be active.

#### `getVoteForRemoveOwnerStatus()`

- Returns the current status of the active voting round.
- Provides:
  - Address proposed for removal.
  - Number of "Yes" and "No" votes.
  - Timestamp of the voting round initiation.


***

<br>
<br>

## Proxy

### Overview

The `Proxy` contract is an abstract implementation that extends the functionalities of `BaseUtilityAndOwnable` and `IProxy` interfaces. This contract serves as a proxy that forwards calls and Ether to an underlying implementation contract. It also adds utility functions for checking contract states and ownership details.

### Contract Features

- Delegation of calls to the implementation contract.
- Checking contract state and ownership status.
- Transfer of Ether to the implementation contract.

### Functions

#### Internal Functions

##### `_delegate()`

- Delegates incoming calls to the implementation contract.
- Pre-conditions:
  - Contract should not be in the `_stopped` state.
  - The implementation contract address should not be null.

##### `_fallback()`

- Internal fallback function that further delegates the call using `_delegate()`.

#### Public and External Functions

##### Fallback Function

- Handles incoming calls that don't match any function in the contract by invoking `_fallback()`.

##### `receive()`

- Forwards received Ether to the implementation contract.
  
##### `getCoreToken()`

- Returns the main ERC20 token (`ANHYDRITE`) associated with the project.

##### `implementation()`

- Returns the address of the current implementation contract.

##### `isStopped()`

- Checks and returns whether the contract's basic functionalities are stopped.

##### `getTotalOwners()`

- Returns the total number of owners.

##### `isProxyOwner(address ownerAddress)`

- Checks if a given address has proxy ownership rights.

##### `isOwner(address account)`

- Checks if a given address is an owner.

##### `getBalanceOwner(address owner)`

- Returns the balance of an owner address.

##### `getTokensNeededForOwnership()`

- Returns the number of tokens needed to acquire ownership.

##### `isBlacklisted(address account)`

- Checks if a given address is blacklisted.








