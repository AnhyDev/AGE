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


import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

abstract contract BaseUtility {

    // Main project token (ANH) address
    IANH public constant ANHYDRITE = IANH(0x47E0CdCB3c7705Ef6fA57b69539D58ab5570799F);

    // This function returns the IProxy interface for the Anhydrite token's proxy contract
    function _proxyContract() internal view returns (IProxy) {
        return IProxy(ANHYDRITE.getProxyAddress());
    }

    // Checks whether the address is among the owners of the proxy contract
    function _isProxyOwner(address senderAddress) internal view returns (bool) {
        return _proxyContract().isProxyOwner(senderAddress);
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkProxyOwner() internal view virtual {
        if (address(_proxyContract()) != address(0) && _proxyContract().getTotalOwners() > 0) {
            require(_isProxyOwner(msg.sender), "BaseUtility: caller is not the proxyOwner");
        } else {
            _checkOwner();
        }
    }

    function _checkOwner() internal view virtual;
}

// Interface for interacting with the Anhydrite contract.
interface IANH is IERC20 {
    // Returns the interface address of the proxy contract
    function getProxyAddress() external view returns (address);
    /**
     * ERC20Burnable function burnFrom.
     */
    function burnFrom(address account, uint256 amount) external;
}

interface IProxy {
    // Returns the address of the current implementation (logic contract)
    function implementation() external view returns (address);
    // Returns the total number of owners
    function getTotalOwners() external view returns (uint256);
    // Checks if an address is a proxy owner (has voting rights)
    function isProxyOwner(address tokenAddress) external view returns (bool);
    // Checks if an address is blacklisted
    function isBlacklisted(address account) external view returns (bool);
    // Increases interest for voting participants
    function increase(address[] memory addresses) external;

// contract AnhydriteGamingEcosystem:  _proxyContract().implementation() functions

    // Get the price of the service
    function getPrice(bytes32 key) external view returns (uint256);
    // This function gets the address of the game server metadata contract
    function getGameServerMetadata() external view returns (address);
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is BaseUtility {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual override {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        if (address(_proxyContract()) != address(0) && _proxyContract().getTotalOwners() > 0) {
            _checkProxyOwner();
        }
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


/*
 * A smart contract serving as a utility layer for voting and ownership management.
 * It extends Ownable contract and interfaces with an external Proxy contract.
 * The contract provides:
 * 1. Vote management with upvotes and downvotes, along with vote expiration checks.
 * 2. Owner checks that allow both the contract owner and proxy contract owners to execute privileged operations.
 * 3. Interface compatibility checks for connected proxy contracts.
 * 4. Renunciation of ownership is explicitly disabled.
 */
abstract contract VoteUtility is Ownable {

    // Enum for vote result clarity
    enum VoteResultType { None, Approved, Rejected }

    // Voting structure
    struct VoteResult {
        address[] isTrue;
        address[] isFalse;
        uint256 timestamp;
    }

    // Internal function to increases interest for VoteResult participants
    function _increaseArrays(VoteResult memory result) internal {
        address[] memory isTrue = result.isTrue;
        address[] memory isFalse = result.isFalse;

        uint256 length1 = isTrue.length;
        uint256 length2 = isFalse.length;
        uint256 totalLength = length1 + length2;

        address[] memory merged = new address[](totalLength);
        for (uint256 i = 0; i < length1; i++) {
            merged[i] = isTrue[i];
        }

        for (uint256 j = 0; j < length2; j++) {
            merged[length1 + j] = isFalse[j];
        }

        _increase(merged);
    }

    // Calls the 'increase' method on the proxy contract to handle voting participants
    function _increase(address[] memory owners) internal {
        if (address(_proxyContract()) != address(0)) {
            _proxyContract().increase(owners);
        }
    }

    /*
     * Internal Function: _votes
     * - Purpose: Records an individual vote, updates the overall vote counts, and evaluates the current voting outcome.
     * - Arguments:
     *   - result: The VoteResult storage object that tracks the current state of both favorable ("true") and opposing ("false") votes.
     *   - vote: A Boolean value representing the stance of the vote (true for in favor, false for against).
     * - Returns:
     *   - The number of favorable votes.
     *   - The number of opposing votes.
     *   - An enum (VoteResultType) that represents the current status of the voting round based on the accumulated favorable and opposing votes.
     */
    function _votes(VoteResult storage result, bool vote) internal returns (uint256, uint256, VoteResultType) {
        if (vote) {
            result.isTrue.push(msg.sender);
        } else {
            result.isFalse.push(msg.sender);
        }
        uint256 votestrue = result.isTrue.length;
        uint256 votesfalse = result.isFalse.length;
        return (votestrue, votesfalse, _voteResult(votestrue, votesfalse));
    }

    /*
     * Internal Function: _voteResult
     * - Purpose: Evaluates the outcome of a voting round based on the current numbers of favorable and opposing votes.
     * - Arguments:
     *   - votestrue: The number of favorable votes.
     *   - votesfalse: The number of opposing votes.
     * - Returns:
     *   - An enum (VoteResultType) representing the voting outcome: None if the vote is still inconclusive, Approved if the vote meets or exceeds a 60% approval rate, and Rejected if the opposing votes exceed a 40% threshold.
     */
    function _voteResult(uint256 votestrue, uint256 votesfalse) private view returns (VoteResultType) {
        VoteResultType result = VoteResultType.None;
        uint256 VOTE_THRESHOLD_FOR = 60;
        uint256 VOTE_THRESHOLD_AGAINST = 40;
        if (votestrue * 100 >= _totalOwners() * VOTE_THRESHOLD_FOR) {
            result = VoteResultType.Approved;
        } else if (votesfalse * 100 > _totalOwners() * VOTE_THRESHOLD_AGAINST) {
            result = VoteResultType.Rejected;
        }
        return result;
    }

    /*
     * Internal Function: _totalOwners
     * - Purpose: Calculates the total number of owners, taking into account any proxy owners if present.
     * - Arguments: None
     * - Returns:
     *   - An unsigned integer representing the total number of owners.
     */
    function _totalOwners() private view returns (uint256) {
        uint256 _tOwners = 1;
        if (address(_proxyContract()) != address(0)) {
            _tOwners = _proxyContract().getTotalOwners();
        }
        return _tOwners;
    }

    // Internal function to reset the voting result to its initial state
    function _resetVote(VoteResult storage vote) internal {
        vote.isTrue = new address[](0);
        vote.isFalse = new address[](0);
        vote.timestamp = 0;
    }
    
    /*
     * Internal Function: _completionVoting
     * - Purpose: Marks the end of a voting process by increasing vote counts and resetting the VoteResult.
     * - Arguments:
     *   - result: The voting result to complete.
     */
    function _completionVoting(VoteResult storage result) internal {
        _increaseArrays(result);
        _resetVote(result);
    }

    /*
     * Internal Function: _closeVote
     * - Purpose: Closes the voting process after a set period and resets the voting structure.
     * - Arguments:
     *   - vote: The voting result to close.
     */
    function _closeVote(VoteResult storage vote) internal canClose(vote.timestamp) {
        if (address(_proxyContract()) != address(0)) {
            address[] memory newArray = new address[](1);
            newArray[0] = msg.sender;
            _increase(newArray);
        }
        _resetVote(vote);
    }
    
    // Internal function to check if an address has already voted in a given VoteResult
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

    // Modifier to check if enough time has passed to close the voting
    modifier canClose(uint256 timestamp) {
        require(block.timestamp >= timestamp + 3 days, "VoteUtility: Voting is still open");
        _;
    }

    // Modifier to ensure an address has not voted before in a given VoteResult
    modifier hasNotVoted(VoteResult memory result) {
        require(!_hasOwnerVoted(result, msg.sender), "VoteUtility: Already voted");
        _;
    }
}


/*
 * A smart contract that extends the UtilityVotingAndOwnable contract to provide financial management capabilities.
 * The contract allows for:
 * 1. Withdrawal of BNB to a designated address, which is the implementation address of an associated Proxy contract.
 * 2. Withdrawal of ERC20 tokens to the same designated address.
 * 3. Transfer of ERC721 tokens (NFTs) to the designated address.
 * All financial operations are restricted to the contract owner.
 */
abstract contract FinanceManager is Ownable {

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
    function _recepient() internal view returns (address) {
        address recepient = owner();
        if (address(_proxyContract()) != address(0)) {
            recepient = _proxyContract().implementation();
        }
        return recepient;
    }
}


/*
 * This abstract contract extends the UtilityVotingAndOwnable contract to manage the ownership of the smart contract.
 * Key features include:
 * 1. Initiating a proposal for changing the owner of the smart contract.
 * 2. Allowing current proxy owners to vote on the proposed new owner.
 * 3. Automatic update of the contract's owner if a 60% threshold of affirmative votes is reached.
 * 4. Automatic cancellation of the proposal if over 40% of the votes are against it.
 * 5. Functionality to manually close an open vote that has been pending for more than three days without a conclusive decision.
 * 6. Events to log voting actions and outcomes for transparency and auditing purposes.
 * 7. Utility functions to check the status of the active vote and the validity of the proposed new owner.
 * 8. Override of the standard 'transferOwnership' function to initiate the voting process, with additional checks against a blacklist and validation of the proposed owner.
 */
abstract contract OwnableManager is VoteUtility {
    // Proposed new owner
    address private _proposedOwner;
    // Structure for counting votes
    VoteResult private _votesForNewOwner;

    // Event about the fact of voting, parameters: voter, proposedOwner, vote
    event VotingForOwner(address indexed voter, address proposedOwner, bool vote);
    // Event about the fact of making a decision on voting, parameters: voter, proposedOwner, vote, votesFor, votesAgainst
    event VotingOwnerCompleted(address indexed voter, address proposedOwner,  bool vote, uint256 votesFor, uint256 votesAgainst);
    // Event to close a poll that has expired
    event CloseVoteForNewOwner(address indexed decisiveVote, address indexed votingObject, uint256 votesFor, uint256 votesAgainst);

    // Overriding the transferOwnership function, which now triggers the start of a vote to change the owner of a smart contract
    function transferOwnership(address proposedOwner) external {
        _checkProxyOwner();
        require(!_isActiveForVoteOwner(), "OwnableManager: voting is already activated");
        require(!_proxyContract().isBlacklisted(proposedOwner),"OwnableManager: this address is blacklisted");
        require( _isProxyOwner(proposedOwner), "OwnableManager: caller is not the proxy owner");

        _proposedOwner = proposedOwner;
        _votesForNewOwner = VoteResult(
            new address[](0),
            new address[](0),
            block.timestamp
        );
        _voteForNewOwner(true);
    }

    // Vote to change the owner of a smart contract
    function voteForNewOwner(bool vote) external {
        _checkProxyOwner();
        _voteForNewOwner(vote);
    }

    // Votes must reach a 60% threshold to pass. If over 40% are downvotes, the measure fails.
    function _voteForNewOwner(bool vote) private hasNotVoted(_votesForNewOwner) {
        require(_isActiveForVoteOwner(), "OwnableManager: there are no votes at this address");

        (uint256 votestrue, uint256 votesfalse, VoteResultType result) = _votes(_votesForNewOwner, vote);

        emit VotingForOwner(msg.sender, _proposedOwner, vote);

        if (result == VoteResultType.Approved) {
            _transferOwnership(_proposedOwner);
            _completionVotingNewOwner(vote, votestrue, votesfalse);
        } else if (result == VoteResultType.Rejected) {
            _completionVotingNewOwner(vote, votestrue, votesfalse);
        }
    }

    // Completion of voting
    function _completionVotingNewOwner(bool vote, uint256 votestrue, uint256 votesfalse) private {
        emit VotingOwnerCompleted(msg.sender, _proposedOwner, vote, votestrue, votesfalse);
        _completionVoting(_votesForNewOwner);
        _proposedOwner = address(0);
    }

    // A function to close a vote on which a decision has not been made for three or more days
    function closeVoteForNewOwner() external {
        _checkProxyOwner();
        require(_proposedOwner != address(0), "OwnableManager: There is no open vote" );
        require(block.timestamp >= _votesForNewOwner.timestamp + 3 days, "BaseUtility: Voting is still open");
        emit CloseVoteForNewOwner( msg.sender, _proposedOwner, _votesForNewOwner.isTrue.length, _votesForNewOwner.isFalse.length );
        _resetVote(_votesForNewOwner);
        _proposedOwner = address(0);
    }

    // Check if voting is enabled for new contract owner and their address.
    function getActiveForVoteOwner() external view returns (address) {
        require( _isActiveForVoteOwner(), "OwnableManager: re is no active voting" );
        return _proposedOwner;
    }

    // Function to check if the proposed Owner address is valid
    function _isActiveForVoteOwner() private view returns (bool) {
        return _proposedOwner != address(0) && _proposedOwner != owner();
    }
}

abstract contract ServerBlockingManager is VoteUtility {

    // Proposed new owner
    address internal _proposedBlocking;
    // Structure for counting votes
    VoteResult internal _votesForServerBlocking;

    // Event about the fact of voting, 
    event VotingForServerBlocking(address indexed voter, address proposedOwner, bool vote);
    // Event about the fact of making a decision on voting, 
    event ServerBlockingCompleted(address indexed voter, address proposedOwner,  bool vote, uint256 votesFor, uint256 votesAgainst);
    // Event to close a poll that has expired
    event CloseVoteForServerBlocking(address indexed decisiveVote, address indexed votingObject, uint256 votesFor, uint256 votesAgainst);

    function _isServer(address serverAddress) internal view virtual returns (bool);
    function _isBlocked(address serverAddress) internal view virtual returns (bool);
    function _setBlocked(address serverAddress) internal virtual;

    function blockServer(address proposedBlocking) external {
        _checkProxyOwner();
        require(_isServer(proposedBlocking), "Server address not found");
        require(_isBlocked(proposedBlocking), "Server is already blocked");
        require(proposedBlocking == address(0), "ServerBlockingManager: voting is already activated");
        require(!_proxyContract().isBlacklisted(proposedBlocking),"ServerBlockingManager: this address is blacklisted");

        _proposedBlocking = proposedBlocking;
        _votesForServerBlocking = VoteResult(
            new address[](0),
            new address[](0),
            block.timestamp
        );
        _voteForServerBlocking(true);
    }

    // Vote to change the owner of a smart contract
    function voteForServerBlocking(bool vote) external {
        _checkProxyOwner();
        _voteForServerBlocking(vote);
    }

    // Votes must reach a 60% threshold to pass. If over 40% are downvotes, the measure fails.
    function _voteForServerBlocking(bool vote) internal hasNotVoted(_votesForServerBlocking) {
        require(_proposedBlocking != address(0), "ServerBlockingManager: there are no votes at this address");

        (uint256 votestrue, uint256 votesfalse, VoteResultType result) = _votes(_votesForServerBlocking, vote);

        emit VotingForServerBlocking(msg.sender, _proposedBlocking, vote);

        if (result == VoteResultType.Approved) {
            _setBlocked(_proposedBlocking);
            _completionVotingServerBlocking(vote, votestrue, votesfalse);
        } else if (result == VoteResultType.Rejected) {
            _completionVotingServerBlocking(vote, votestrue, votesfalse);
        }
    }

    // Completion of voting
    function _completionVotingServerBlocking(bool vote, uint256 votestrue, uint256 votesfalse) private {
        emit ServerBlockingCompleted(msg.sender, _proposedBlocking, vote, votestrue, votesfalse);
        _completionVoting(_votesForServerBlocking);
        _proposedBlocking = address(0);
    }

    // A function to close a vote on which a decision has not been made for three or more days
    function closeVoteForServerBlockingr() external {
        _checkProxyOwner();
        require(_proposedBlocking != address(0), "ServerBlockingManager: There is no open vote" );
        require(block.timestamp >= _votesForServerBlocking.timestamp + 3 days, "BaseUtility: Voting is still open");
        emit CloseVoteForServerBlocking( msg.sender, _proposedBlocking, _votesForServerBlocking.isTrue.length, _votesForServerBlocking.isFalse.length );
        _resetVote(_votesForServerBlocking);
        _proposedBlocking = address(0);
    }

    // Check if voting is enabled for new contract owner and their address.
    function getActiveForVoteBlocking() external view returns (address) {
        require(_proposedBlocking != address(0), "ServerBlockingManager: re is no active voting" );
        return _proposedBlocking;
    }
}

/**
 * @title GameData
 * @dev This contract serves as the game data management layer.
 * It extends Ownable for basic authorization control and interfaces
 * with a proxy contract to retrieve game-related data.
 */
abstract contract GameData is Ownable {

    /**
     * @dev A constant that represents a sentinel value indicating the end of the list of games.
     * This can be used to mark the last element in a linked list or similar data structures.
     */
    uint256 internal constant END_OF_LIST = 1000;

    /**
     * @dev Internal function to get the interface of the Game Server Metadata contract.
     * @return An instance of IGameData interface.
     */
    function _getGameServerMetadata() internal view returns (IGameData) {
        return IGameData(_proxyContract().getGameServerMetadata());
    }

    /**
     * @dev Internal function to check if the game ID is not empty.
     * @param gameId The ID of the game to check.
     * @return True if the game ID exists, false otherwise.
     */
    function _checkGameIdNotEmpty(uint256 gameId) internal view returns (bool) {
        return _getGameServerMetadata().checkGameIdNotEmpty(gameId) != END_OF_LIST;
    }

    /**
     * @dev Private function to actually retrieve the server data of a game.
     * @param gameId The ID of the game.
     * @return name The name of the game server.
     * @return symbol The symbol of the game server.
     */
    function _getServerData(uint256 gameId) private view returns (string memory, string memory) {
        string memory name = "Anhydrite server module ";
        string memory symbol = "AGE_";
        if (address(_getGameServerMetadata()) != address(0)) {
            (name, symbol) = _getGameServerMetadata().getServerData(gameId);
        }
        return (name, symbol);
    }
}

/**
 * @title IGameData
 * @dev Interface for the GameData contract.
 */
interface IGameData {
    /**
     * @dev Returns the name and symbol of the server for a specific game.
     * @param gameId The ID of the game.
     * @return name The name of the game server.
     * @return symbol The symbol of the game server.
     */
    function getServerData(uint256 gameId) external view returns (string memory, string memory);

    /**
     * @dev Checks if the game ID is not empty and returns the game ID or a sentinel value accordingly.
     * @param gameId The ID of the game to check.
     * @return The gameId if it's not empty, otherwise returns a sentinel value.
     */
    function checkGameIdNotEmpty(uint256 gameId) external view returns (uint256);
}


// Declares an abstract contract ERC165 that implements the IERC165 interface
abstract contract ERC165 is IERC165 {

    // Internal mapping to store supported interfaces
    mapping(bytes4 => bool) internal supportedInterfaces;

    // Constructor to initialize the mapping of supported interfaces
    constructor() {
        // 0x01ffc9a7 is the interface identifier for ERC165 according to the standard
        supportedInterfaces[0x01ffc9a7] = true;
    }

    // Implements the supportsInterface method from the IERC165 interface
    // The function checks if the contract supports the given interface
    function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
        return supportedInterfaces[interfaceId];
    }
}

// Interface for contracts that are capable of receiving ERC20 (ANH) tokens.
interface IERC20Receiver {
    // Function that is triggered when ERC20 (ANH) tokens are received.
    function onERC20Received(address _from, address _who, uint256 _amount) external returns (bytes4);
}

/**
 * @title ERC20Receiver Abstract Contract
 * @dev This contract extends from IERC20Receiver, BaseUtility, and ERC165 interfaces.
 *      It provides functionalities for receiving ERC20 (ANHYDRITE) tokens and responding with a magic identifier.
 *      It uses the IERC1820Registry for handling standardized contract interface detection.
 * 
 *      Events:
 *      - DepositAnhydrite: Emitted when ANHYDRITE tokens are deposited.
 *      - ChallengeIERC20Receiver: Emitted to track from which address the tokens were transferred,
 *          who transferred them, to which address and the number of tokens.
 * 
 *      Functions include:
 *      - onERC20Received: Overridden from IERC20Receiver, handles incoming ERC20 token transfers.
 */
abstract contract ERC20Receiver is IERC20Receiver, BaseUtility, ERC165 {

    IERC1820Registry constant internal erc1820Registry = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    // Event emitted when Anhydrite tokens are deposited.
    event DepositAnhydrite(address indexed from, address indexed who, uint256 amount);
    // An event to track from which address the tokens were transferred, who transferred, to which address and the number of tokens
    event ChallengeIERC20Receiver(address indexed from, address indexed who, address indexed token, uint256 amount);

    constructor() {
        supportedInterfaces[type(IERC20Receiver).interfaceId] = true;
        erc1820Registry.setInterfaceImplementer(address(this), keccak256("IERC20Receiver"), address(this));
    }

    /**
     * @dev Handles the receipt of ERC20 tokens. Implements the IERC20Receiver interface.
     * @param _from The address from which the tokens are sent.
     * @param _who The address that triggered the sending of tokens.
     * @param _amount The amount of tokens received.
     * @return bytes4 The interface identifier, to confirm contract adherence.
     */
    function onERC20Received(address _from, address _who, uint256 _amount) external override returns (bytes4) {
        bytes4 fakeID = bytes4(keccak256("anything_else"));
        bytes4 validID = this.onERC20Received.selector;
        bytes4 returnValue = fakeID;  // Default value
        if (msg.sender.code.length > 0) {
            if (msg.sender == address(ANHYDRITE)) {
                emit DepositAnhydrite(_from, _who, _amount);
                returnValue = validID;
            } else {
                try IERC20(msg.sender).balanceOf(address(this)) returns (uint256 balance) {
                    if (balance >= _amount) {
                        emit ChallengeIERC20Receiver(_from, _who, msg.sender, _amount);
                        returnValue = validID;
                    }
                } catch {
                    // No need to change returnValue, it's already set to fakeID
                }
            }
            return returnValue;
        } else {
            revert ("ERC20Receiver: This function is for handling token acquisition");
        }
    }
}

/**
 * @title IERC1820Registry Interface
 * @dev This is an interface for the ERC1820 Registry contract, a central registry 
 *      used to discover which interface a particular address supports.
 * 
 *      The ERC1820 standard is a meta-standard that defines a universal registry smart contract 
 *      where any address (contract or regular account) can indicate which interface it supports.
 *
 *      Functions:
 *      - setInterfaceImplementer: Sets the contract which implements a specific interface for an address.
 */
interface IERC1820Registry {
    function setInterfaceImplementer(address account, bytes32 interfaceHash, address implementer) external;
}


// Interface defining the essential functions for the AnhydriteMonitoring smart contract.
interface IAGEMonitoring {
    // Functions to add or remove server addresses.
    function addServerAddress(uint256 gameId, address serverAddress) external;
    function removeServerAddress(address serverAddress) external;
    
    // Voting mechanism handlers
    function voteForServer(address voterAddress, address serverAddress) external;
    function voteForServerWith10(address voterAddress, address serverAddress) external;
    function voteForServerWith100(address voterAddress, address serverAddress) external;
    function voteForServerWith1000(address voterAddress, address serverAddress) external;
    function voteForServerWith10000(address voterAddress, address serverAddress) external;
    function voteForServerWith100000(address voterAddress, address serverAddress) external;
    function voteForServerWith1000000(address voterAddress, address serverAddress) external;
    
    // Transaction burn fee calculators
    function getBurnFeeFor1Vote() external view returns (uint256);
    function getBurnFeeFor10Votes() external view returns (uint256);
    function getBurnFeeFor100Votes() external view returns (uint256);
    function getBurnFeeFor1000Votes() external view returns (uint256);
    function getBurnFeeFor10000Votes() external view returns (uint256);
    function getBurnFeeFor100000Votes() external view returns (uint256);
    function getBurnFeeFor1000000Votes() external view returns (uint256);
    
    // Functions to get information about servers.
    function getServerVotes(address serverAddress) external view returns (uint256);
    function getGameServerAddresses(uint256 gameId, uint256 startIndex, uint256 endIndex) external view returns (address[] memory);
    function isServerExist(address serverAddress) external view returns (bool);
    function getServerBlocked(address serverAddress) external view returns (bool, uint256);
}


/**
 * @title ServerDelegator
 * @author Your Name or Organization
 * @notice Контракт ServerDelegator розроблений для делегування серверів та обчислення плати за використання ресурсів.
 * Контракт надає можливість голосування для вибору сервера та забезпечує транспарентність та правильність обчислення плати.
 */
contract AGEMonitoring is IAGEMonitoring,
    OwnableManager,
    ServerBlockingManager,
    FinanceManager,
    GameData,
    ERC20Receiver,
    IERC721Receiver {

    // Constant for pricing model.
    bytes32 private constant _priceVotingBytes  = keccak256(
        abi.encodePacked("The price of voting on monitoring")
    );

    // The base price is the fundamental unit of ether (wei) expressed in its decimal form (10^18).
    uint256 private constant _basePrice = 1 * 10 ** 18;
    
    // The following constants represent the percentage of tokens to be burnt when voting, 
    // varying based on the number of votes cast in a single transaction.
    // The higher the number of votes, the lower the percentage of tokens burnt.
    uint256 private constant PERCENTAGE_1_VOTES = 100;
    uint256 private constant PERCENTAGE_10_VOTES = 90;
    uint256 private constant PERCENTAGE_100_VOTES = 80;
    uint256 private constant PERCENTAGE_1000_VOTES = 70;
    uint256 private constant PERCENTAGE_10000_VOTES = 60;
    uint256 private constant PERCENTAGE_100000_VOTES = 50;
    uint256 private constant PERCENTAGE_1000000_VOTES = 40;

    // State variable to check if the contract is operational or not.
    bool public isContractStopped = false;

    // Mappings and struct to manage server-related data.
    // serversInfo stores metadata about each server including its index, game ID, vote count, and block status.
    mapping(address => ServerInfo) internal serversInfo;
    // servers is a quick lookup table to check if a server already exists.
    mapping(address => bool) internal servers;
    // gameServers maps game IDs to an array of server addresses.
    mapping(uint256 => address[]) internal gameServers;

    struct ServerInfo {
        uint256 index;
        uint256 gameId;
        uint256 votes;
        bool isBlocked;
    }


    // Voted event is emitted when a user successfully votes for a server.
    event Voted(address indexed voter, address indexed serverAddress, string game, string indexed symbol, uint256 totalVotes, uint256 newVotes);
    // ContractStopped is emitted when the contract is manually halted by the owner.
    event ContractStopped();

    constructor() {
        supportedInterfaces[type(IAGEMonitoring).interfaceId] = true;
        erc1820Registry.setInterfaceImplementer(address(this), keccak256("IAGEMonitoring"), address(this));
    }

    // This modifier ensures that the function can only be executed if the contract is not stopped.
    modifier notStopped() {
        require(!isContractStopped, "AGEMonitoring: Contract is stopped.");
        _;
    }

    // This modifier ensures that the function can only be executed by the global smart contract.
    // This is verified by comparing the caller address to the implementation address of the proxy contract.
    modifier onlyGlobal() {
        require(_proxyContract().implementation() == msg.sender,
            "AGEMonitoring: This function is only available from a global smart contract."
        );
        _;
    }

    /**
     * This function allows a global contract to add a new server address for a specified game.
     * @param gameId: The ID of the game to which the server is to be added.
     * @param serverAddress: The address of the server that is to be added.
     */
    function addServerAddress(uint256 gameId, address serverAddress) external override onlyGlobal notStopped {
        _addServerAddress(gameId, serverAddress);
    }

    /**
     * This internal function performs the actual addition of the server address for a specified game.
     * @param gameId: The ID of the game to which the server is to be added.
     * @param serverAddress: The address of the server that is to be added.
     */
    function _addServerAddress(uint256 gameId, address serverAddress) internal {
        require(_checkGameIdNotEmpty(gameId), "AGEMonitoring: Invalid game ID");
        require(serverAddress != address(0), "AGEMonitoring: Invalid server address");
        require(!servers[serverAddress], "AGEMonitoring: Server address already added");

        gameServers[gameId].push(serverAddress);

        serversInfo[serverAddress] = ServerInfo({
            index: gameServers[gameId].length,
            gameId: gameId,
            votes: 1,
            isBlocked: false
        });

        servers[serverAddress] = true;
    }

    /**
     * This function allows a global contract to remove a server address.
     * @param serverAddress: The address of the server that is to be removed.
     */
    function removeServerAddress(address serverAddress) external override onlyGlobal notStopped {
        require(servers[serverAddress], "AGEMonitoring: Server address not found");

        uint256 gameId = serversInfo[serverAddress].gameId;
        uint256 index = serversInfo[serverAddress].index;
        gameServers[gameId][index] = address(0);
        delete servers[serverAddress];
        delete serversInfo[serverAddress];
    }

    /*
     * VOTING MECHANISM HANDLERS
     * These functions are responsible for handling 
     * all operations related to the voting process.
     */ 
    function voteForServer(address voterAddress, address serverAddress) external override notStopped {
        voterAddress = _getVoterAddress(voterAddress);
        _vote(voterAddress, serverAddress, 1, PERCENTAGE_1_VOTES);
    }
    function voteForServerWith10(address voterAddress, address serverAddress) external override notStopped {
        voterAddress = _getVoterAddress(voterAddress);
        _vote(voterAddress, serverAddress, 10, PERCENTAGE_10_VOTES);
    }
    function voteForServerWith100(address voterAddress, address serverAddress) external override notStopped {
        voterAddress = _getVoterAddress(voterAddress);
        _vote(voterAddress, serverAddress, 100, PERCENTAGE_100_VOTES);
    }
    function voteForServerWith1000(address voterAddress, address serverAddress) external override notStopped {
        voterAddress = _getVoterAddress(voterAddress);
        _vote(voterAddress, serverAddress, 1000, PERCENTAGE_1000_VOTES);
    }
    function voteForServerWith10000(address voterAddress, address serverAddress) external override notStopped {
        voterAddress = _getVoterAddress(voterAddress);
        _vote(voterAddress, serverAddress, 10000, PERCENTAGE_10000_VOTES);
    }
    function voteForServerWith100000(address voterAddress, address serverAddress) external override notStopped {
        voterAddress = _getVoterAddress(voterAddress);
        _vote(voterAddress, serverAddress, 100000, PERCENTAGE_100000_VOTES);
    }
    function voteForServerWith1000000(address voterAddress, address serverAddress) external override notStopped {
        voterAddress = _getVoterAddress(voterAddress);
        _vote(voterAddress, serverAddress, 1000000, PERCENTAGE_1000000_VOTES);
    }

    /*
     * TRANSACTION BURN FEE CALCULATORS
     * These functions are responsible for calculating the 
     * commission fees to be burned during a transaction.
     */
    function getBurnFeeFor1Vote() external view override returns (uint256) {
        return _calculateAmountToBurn(1, 100);
    }
    function getBurnFeeFor10Votes() external view override returns (uint256) {
        return _calculateAmountToBurn(10, PERCENTAGE_10_VOTES);
    }
    function getBurnFeeFor100Votes() external view override returns (uint256) {
        return _calculateAmountToBurn(100, PERCENTAGE_100_VOTES);
    }
    function getBurnFeeFor1000Votes() external view override returns (uint256) {
        return _calculateAmountToBurn(1000, PERCENTAGE_1000_VOTES);
    }
    function getBurnFeeFor10000Votes() external view override returns (uint256) {
        return _calculateAmountToBurn(10000, PERCENTAGE_10000_VOTES);
    }
    function getBurnFeeFor100000Votes() external view override returns (uint256) {
        return _calculateAmountToBurn(100000, PERCENTAGE_100000_VOTES);
    }
    function getBurnFeeFor1000000Votes() external view override returns (uint256) {
        return _calculateAmountToBurn(1000000, PERCENTAGE_1000000_VOTES);
    }

    /**
     * This internal function gets the address of the voter. 
     * If the sender is not the proxy contract implementation, 
     * the voter address is set to the sender's address. 
     * This function is mainly used in the voting mechanism handlers 
     * to ensure the correct voter address is used in the vote transactions.
     * @param voterAddress: The input address to be checked and possibly reassigned.
     * @return address: The address of the voter.
     */
    function _getVoterAddress(address voterAddress) internal view returns (address) {
        if (_proxyContract().implementation() != msg.sender) {
            voterAddress = msg.sender;
        }
        return voterAddress;
    }

    /**
     * This internal function handles the voting process, where votes are cast 
     * for a server, and the corresponding amount of tokens are burnt based on the 
     * number of votes and the specified percentage.
     * If the server does not exist, it gets added, and if it does, 
     * the number of votes it has received is updated.
     * An event is emitted with details of the vote transaction.
     * @param voterAddress: The address of the voter.
     * @param serverAddress: The address of the server being voted for.
     * @param numberOfVotes: The number of votes being cast.
     * @param percentage: The specified percentage to calculate the amount to burn.
     */
    function _vote(address voterAddress, address serverAddress, uint256 numberOfVotes, uint256 percentage) internal {
        require(serverAddress != address(0), "AGEMonitoring: Invalid server address");
        
        uint256 amountToBurn = _calculateAmountToBurn(numberOfVotes, percentage);

        if (amountToBurn > 0) {
            require(ANHYDRITE.balanceOf(voterAddress) >= amountToBurn, "AGEMonitoring: Insufficient token balance");
            require(ANHYDRITE.allowance(voterAddress, address(this)) >= amountToBurn, "AGEMonitoring: Token allowance too small");
            ANHYDRITE.burnFrom(voterAddress, amountToBurn);
        }

        uint256 gameId = serversInfo[serverAddress].gameId;
        if (!servers[serverAddress]) {
            _addServerAddress(gameId, serverAddress);
        } else {
            serversInfo[serverAddress].votes += numberOfVotes;
        }
        (string memory gameName, string memory gameSymbol) = _getGameServerMetadata().getServerData(gameId);

        emit Voted(voterAddress, serverAddress, gameName, gameSymbol, serversInfo[serverAddress].votes, numberOfVotes);
    }
 
    /**
     * This function calculates the amount of tokens to burn based on the number of votes and the specified percentage.
     * @param numberOfVotes: The number of votes.
     * @param percentage: The specified percentage.
     */
    function _calculateAmountToBurn(uint256 numberOfVotes, uint256 percentage) internal view returns (uint256) {
        uint256 burned = _proxyContract().getPrice(_priceVotingBytes) != 0 ? 
            _proxyContract().getPrice(_priceVotingBytes) : _basePrice;
            
        if (numberOfVotes == 1 && _proxyContract().getPrice(_priceVotingBytes) == 0) {
            return 0;
        } else {
            return (burned * numberOfVotes * percentage) / 100;
        }
    }

    /**
     * This function returns the vote count of a specified server.
     * @param serverAddress: The address of the server.
     */
    function getServerVotes(address serverAddress) external override view returns (uint256) {
        if(serversInfo[serverAddress].isBlocked) {
            return 0;
        }
        return serversInfo[serverAddress].votes;
    }

    /**
     * This function returns a list of server addresses for a specified game ID within a range of indices.
     * @param gameId: The ID of the game.
     * @param startIndex: The starting index of the range.
     * @param endIndex: The ending index of the range.
     */
    function getGameServerAddresses(uint256 gameId, uint256 startIndex, uint256 endIndex) external override view returns (address[] memory) {
        require(_checkGameIdNotEmpty(gameId), "AGEMonitoring: Invalid game ID");
        require(startIndex <= endIndex, "AGEMonitoring: Invalid start or end index");

        address[] storage originalList = gameServers[gameId];
        uint256 length = originalList.length;

        if (length == 0) {
            return new address[](0);
        }

        require(startIndex < length, "AGEMonitoring: Start index out of bounds.");

        if (endIndex >= length) {
            endIndex = length - 1;
        }

        uint256 resultLength = endIndex - startIndex + 1;

        // Create a dynamic memory array to hold the valid server addresses temporarily
        address[] memory tempResult = new address[](resultLength);
        uint256 count = 0;

        // Loop through the original list and only add non-zero addresses to tempResult
        for (uint256 i = 0; i < resultLength; i++) {
            address serverAddress = originalList[startIndex + i];
            if (serverAddress != address(0)) {
                tempResult[count] = serverAddress;
                count++;
            }
        }

        // Create a new array with the correct size and copy valid addresses from tempResult
        address[] memory resultList = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            resultList[i] = tempResult[i];
        }

        return resultList;
    }

    /**
     * This function checks whether a server exists given its address.
     * @param serverAddress: The address of the server.
     */
    function isServerExist(address serverAddress) external override view returns (bool) {
        return _isServer(serverAddress);
    }

    /**
     * This function checks whether a server is blocked and also returns its vote count.
     * @param serverAddress: The address of the server.
     */
    function getServerBlocked(address serverAddress) external override view returns (bool, uint256) {
        return (_isBlocked(serverAddress), serversInfo[serverAddress].votes);
    }

    /**
     * This function allows the contract owner to halt the contract operations.
     */
    function stopContract() external onlyOwner {
        require(!isContractStopped, "AGEMonitoring: Contract is already stopped.");
        isContractStopped = true;
        emit ContractStopped();
    }

    // Implements the ERC-721 standard for handling received tokens.
    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * This internal function checks whether a server exists.
     * @param serverAddress: The address of the server.
     */
    function _isServer(address serverAddress) internal override view virtual returns (bool) {
        return servers[serverAddress];
    }
    
    /**
     * This internal function checks whether a server is blocked.
     * @param serverAddress: The address of the server.
     */
    function _isBlocked(address serverAddress) internal override view virtual returns (bool) {
        return serversInfo[serverAddress].isBlocked;
    }

    /**
     * This internal function sets a server as blocked.
     * @param serverAddress: The address of the server.
     */
    function _setBlocked(address serverAddress) internal override virtual {
        serversInfo[serverAddress].isBlocked = true;
    }
}