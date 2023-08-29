/*
 * Copyright (C) 2023 Anhydrite Gaming Ecosystem
 *
 * This code is part of the Anhydrite Gaming Ecosystem.
 *
 * ERC-20 Token: Anhydrite ANH 0x578b350455932aC3d0e7ce5d7fa62d7785872221
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
* The abstract proxy smart contract that implements the IProxy interface,
* the main goal here is to delegate calls to the global smart contract,
* to set the project's main token.
*
* In addition, the possibility of depositing tokens by owners to their account in a smart contract,
* withdrawing excess tokens, as well as voluntary exit from owners is realized here.
* There is also an opportunity to get information about the global token, about the owners,
* their deposits, to find out whether the address is among the owners, as well as whether it has the right to vote.
*/

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
abstract contract Proxy is IProxy, IERC721Receiver {

    struct VoteResult {
        address[] isTrue;
        address[] isFalse;
        uint256 timestamp;
    }

    IERC20 internal immutable _token;
    address internal _implementation;
    bool internal _stopped = false;

    uint256 internal _totalOwners;
    mapping(address => bool) internal _owners;
    mapping(address => uint256) internal _balanceOwner;
    
    uint256 internal _tokensNeededForOwnership;

    mapping(address => uint256) internal _initiateOwners;
    mapping(address => bool) internal _isOwnerVotedOut;
    mapping(address => bool) internal _blackList;

    address internal _proposedImplementation;
    VoteResult internal _votesForNewImplementation;

    bool internal _proposedStopped = false;
    VoteResult internal _votesForStopped;

    uint256 internal _proposedTokensNeeded;
    VoteResult internal _votesForTokensNeeded;

    address internal _proposedOwner;
    VoteResult internal _votesForNewOwner;
    
    address internal _proposedRemoveOwner;
    VoteResult internal _votesForRemoveOwner;
    
    constructor() {
        _implementation = address(0);
        _owners[msg.sender] = true;
        _totalOwners++;
        _token = IERC20(0x578b350455932aC3d0e7ce5d7fa62d7785872221);
        _tokensNeededForOwnership = 1 * 10 **18;
    }

    // Returns an ERC20 standard token, which is the main token of the project
    function getToken() external override view returns (IERC20) {
        return _token;
    }

    // A function for obtaining the address of a global smart contract
    function getImplementation() external override view returns (address) {
        return _implementation;
    }

    // A function to obtain information about whether the basic functions of the smart contract are stopped
    function isStopped() external override view returns (bool) {
        return _stopped;
    }

    // Function for obtaining information about the total number of owners
    function getTotalOwners() external override view returns (uint256) {
        return _totalOwners;
    }

    // The function for obtaining information whether the address is among the owners and whether it has the right to vote
    function isProxyOwner(address tokenAddress) external override view returns (bool) {
        return _owners[tokenAddress] 
        && !_isOwnerVotedOut[tokenAddress]
        && _balanceOwner[tokenAddress] >= _tokensNeededForOwnership;
    }

    // Function for obtaining information whether the address is among the owners
    function isOwner(address account) external override view returns (bool) {
        return _owners[account];
    }

    // Function for obtaining information about the balance of the owner
    function getBalanceOwner(address owner) external override view returns (uint256) {
        return _balanceOwner[owner];
    }

    // A function to obtain information about the number of Master Tokens required on the owner's balance to be eligible to vote
    function getTokensNeededForOwnership() external override view returns (uint256) {
        return _tokensNeededForOwnership;
    }

    // Checks if the address is blacklisted
    function isBlacklisted(address account) external override view returns (bool) {
        return _blackList[account];
    }

    // Function for obtaining information about whether the address is in the black list
    function depositTokens(uint256 amount) external override onlyOwner {
        require(amount > 0, "Proxy: Invalid amount");
        require(_token.transferFrom(msg.sender, address(this), amount), "Proxy: Transfer failed");
        _balanceOwner[msg.sender] += amount;
    }

    /*
    * A function for voluntary resignation of the owner from his position.
    * At the same time, his entire deposit is returned to his balance.
    */
    function voluntarilyExit() external override onlyOwner {
        require(!_isOwnerVotedOut[msg.sender], "Proxy: You have been voted out");
        
        uint256 balance = _balanceOwner[msg.sender];
        if (balance > 0) {
            _transferTokens(msg.sender, balance);
        }

        _owners[msg.sender] = false;
        _totalOwners--;

        emit VoluntarilyExit(msg.sender, balance);
    }
    
    // A function for the owner to withdraw excess tokens from his deposit
    function withdrawExcessTokens() external override onlyOwner {
        require(!_isOwnerVotedOut[msg.sender], "Proxy: You have been voted out");
        uint256 ownerBalance = _balanceOwner[msg.sender];
        uint256 excess = 0;

        if (ownerBalance > _tokensNeededForOwnership) {
            excess = ownerBalance - _tokensNeededForOwnership;
            _transferTokens(msg.sender, excess);
        }
    }

    function _transferTokens(address recepient, uint256 amount) internal {
            _balanceOwner[recepient] -= amount;

            if(_token.balanceOf(address(this)) >= amount) {
                require(_token.transfer(recepient, amount), "Proxy: Failed to transfer tokens");
            } else {
                IAnhydriteGlobal implementation = IAnhydriteGlobal(_implementation);
                require(implementation.getTokens(recepient, amount), "Proxy: Failed to get transfer tokens");
            }
    }

    /*
    * Function to transfer tokens from the balance of the proxy smart contract to the balance of the global smart contract.
    * At the same time, it is impossible to transfer the global token
    */
    function rescueTokens(address tokenAddress) external override onlyOwner {
        require(tokenAddress != address(_token), "Proxy: Cannot rescue the main token");
    
        IERC20 rescueToken = IERC20(tokenAddress);
        uint256 balance = rescueToken.balanceOf(address(this));
    
        require(balance > 0, "Proxy: No tokens to rescue");
    
        require(rescueToken.transfer(_implementation, balance), "Proxy: Transfer failed");
    }

    // Internal functions and modifiers
    
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

    // Modifier for checking whether 3 days have passed since the start of voting and whether it can be closed
    modifier canClose(uint256 timestamp) {
        require(block.timestamp >= timestamp + 3 days, "Owners: Voting is still open");
        _;
    }

    // Modifier to check if the owner has the right to vote on this issue,
    // that is, whether he has not voted before, and whether his deposit corresponds to the amount required for the right to vote
    modifier canYouVote(VoteResult memory result) {
        require(!_hasOwnerVoted(result, msg.sender), "Owners: Already voted");
        require(_balanceOwner[msg.sender] >= _tokensNeededForOwnership, "Votes: Insufficient tokens in staking balance");
        _;
    }

    // A modifier that checks whether an address is in the list of owners, and whether a vote for exclusion is open for this address
    modifier onlyOwner() {
        require(_owners[msg.sender], "Owners: Not an owner");
        require(!_isOwnerVotedOut[msg.sender], "Owners: This owner is being voted out");
        _;
    }

    // A function for delegating calls to a global smart contract

    function _delegate() internal virtual {
        require(!_stopped, "Proxy: Contract is currently _stopped.");
        address _impl = _implementation;
        require(_impl != address(0), "Proxy: Implementation == address(0)");

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    function _fallback() internal virtual {
        _delegate();
    }

    fallback() external payable virtual {
        _fallback();
    }

    receive() external payable {
        Address.sendValue(payable(address(_implementation)), msg.value);
    }

    function onERC721Received(address, address, uint256 tokenId, bytes calldata) external override returns (bytes4) {
        IERC721(msg.sender).safeTransferFrom(address(this), _implementation, tokenId);
        return this.onERC721Received.selector;
    }


    // A function to verify the identity of a global smart contract
    function _checkContract(address contractAddress) internal view returns (bool) {
        // We bring the address to the IERC165 interface
        IERC165 targetContract = IERC165(contractAddress);

        // We use the supportsInterface method to check interface support
        return targetContract.supportsInterface(type(IAnhydriteGlobal).interfaceId);
    }
}
