# Public Functions in BaseProxyVoting Smart Contract

## Overview

This document outlines the public functions available in the `BaseProxyVoting` smart contract.

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

Feel free to add this to your project documentation!
