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

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

abstract contract BaseUtility {

    // Main project token (ANH) address
    IANH public constant ANHYDRITE = IANH(0x47E0CdCB3c7705Ef6fA57b69539D58ab5570799F);

    IERC1820Registry constant internal erc1820Registry = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

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
        require(_owner == msg.sender, "Ownable: caller is not the owner");
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        IProxy proxy = _proxyContract();
        if (address(proxy) != address(0) && proxy.getTotalOwners() > 0) {
            require(_isProxyOwner(msg.sender), "BaseUtility: caller is not the proxy owner");
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

// Interface for interacting with the Anhydrite contract.
interface IANH {
    // Returns the interface address of the proxy contract
    function getProxyAddress() external view returns (address);
}

interface IProxy {
    // Returns the total number of owners
    function getTotalOwners() external view returns (uint256);
    // Checks if an address is a proxy owner (has voting rights)
    function isProxyOwner(address tokenAddress) external view returns (bool);
    // Checks if an address is blacklisted
    function isBlacklisted(address account) external view returns (bool);
    // Increases interest for voting participants
    function increase(address[] memory addresses) external;
}


/**
 * @title FinanceManager
 * @dev The FinanceManager contract is an abstract contract that extends Ownable.
 * It provides a mechanism to transfer Ether, ERC20 tokens, and ERC721 tokens from
 * the contract's balance, accessible only by the owner.
 */
abstract contract FinanceManager is Ownable, IERC721Receiver {

    /**
     * @notice Transfers Ether from the contract's balance to a specified recipient.
     * @dev Can only be called by the contract owner.
     * @param recipient The address to receive the transferred Ether.
     * @param amount The amount of Ether to be transferred in wei.
     */
    function transferMoney(address payable recipient, uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "FinanceManager: Contract has insufficient balance");
        require(recipient != address(0), "FinanceManager: Recipient address is the zero address");
        recipient.transfer(amount);
    }
    
    /**
     * @notice Transfers ERC20 tokens from the contract's balance to a specified address.
     * @dev Can only be called by the contract owner.
     * @param _tokenAddress The address of the ERC20 token contract.
     * @param _to The recipient address to receive the transferred tokens.
     * @param _amount The amount of tokens to be transferred.
     */
    function transferERC20Tokens(address _tokenAddress, address _to, uint256 _amount) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        require(token.balanceOf(address(this)) >= _amount, "FinanceManager: Not enough tokens on contract balance");
        token.transfer(_to, _amount);
    }

    /**
     * @notice Transfers an ERC721 token from the contract's balance to a specified address.
     * @dev Can only be called by the contract owner.
     * @param _tokenAddress The address of the ERC721 token contract.
     * @param _to The recipient address to receive the transferred token.
     * @param _tokenId The unique identifier of the token to be transferred.
     */
    function transferERC721Token(address _tokenAddress, address _to, uint256 _tokenId) external onlyOwner {
        IERC721 token = IERC721(_tokenAddress);
        require(token.ownerOf(_tokenId) == address(this), "FinanceManager: The contract is not the owner of this token");
        token.safeTransferFrom(address(this), _to, _tokenId);
    }

    /**
     * @notice The onERC721Received function is used to process the receipt of ERC721 tokens.
     */
    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    
    receive() external payable {}
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
    function _checkOwnerVoted(VoteResult memory result) internal view {
        bool voted;
        for (uint256 i = 0; i < result.isTrue.length; i++) {
            if (result.isTrue[i] == msg.sender) {
                voted = true;
            }
        }
        for (uint256 i = 0; i < result.isFalse.length; i++) {
            if (result.isFalse[i] == msg.sender) {
                voted = true;
            }
        }
        if (voted) {
            revert("VoteUtility: Already voted");
        }
    }

    // Modifier to check if enough time has passed to close the voting
    modifier canClose(uint256 timestamp) {
        require(block.timestamp >= timestamp + 3 days, "VoteUtility: Voting is still open");
        _;
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
    function transferOwnership(address proposedOwner) public {
        _checkProxyOwner();
        require(_proposedOwner == address(0), "OwnableManager: voting is already activated");
        require(!_proxyContract().isBlacklisted(proposedOwner),"OwnableManager: this address is blacklisted");
        require(_isProxyOwner(proposedOwner), "OwnableManager: caller is not the proxy owner");

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
    function _voteForNewOwner(bool vote) internal {
        _checkOwnerVoted(_votesForNewOwner);
        _checkActiveForVote();

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
    function _completionVotingNewOwner(bool vote, uint256 votestrue, uint256 votesfalse) internal {
        emit VotingOwnerCompleted(msg.sender, _proposedOwner, vote, votestrue, votesfalse);
        _completionVoting(_votesForNewOwner);
        _proposedOwner = address(0);
    }

    // A function to close a vote on which a decision has not been made for three or more days
    function closeVoteForNewOwner() public {
        _checkProxyOwner();
        _checkActiveForVote();
        require(block.timestamp >= _votesForNewOwner.timestamp + 3 days, "OwnableManager: Voting is still open");
        emit CloseVoteForNewOwner(msg.sender, _proposedOwner, _votesForNewOwner.isTrue.length, _votesForNewOwner.isFalse.length);
        _resetVote(_votesForNewOwner);
        _proposedOwner = address(0);
    }

    // Check if voting is enabled for new contract owner and their address.
    function getActiveForVoteOwner() external view returns (address) {
        _checkActiveForVote();
        return _proposedOwner;
    }

    // Function to check if the proposed Owner address is valid
    function _checkActiveForVote() private view {
        require(_proposedOwner != address(0), "OwnableManager: re is no active voting");
    }
}

/*
 * The Monitorings smart contract is designed to work with monitoring,
 * add, delete, vote for the server, get the number of votes, and more.
 */
abstract contract MonitoringManager is Ownable {
    enum ServerStatus {
        NotFound,
        Monitored,
        Blocked
    }

    address[] private _monitoring;

    struct Monitoring {
        uint256 version;
        address addr;
    }

    // Add a new address to the monitoring list.
    function addMonitoring(address newAddress) external onlyOwner {
        _monitoring.push(newAddress);
    }

    // Get the last non-zero monitoring address and its index.
    function getMonitoring() external view returns (Monitoring memory) {
        return _getMonitoring();
    }

    // Get the list of non-zero monitoring addresses.
    function getMonitoringAddresses() external view returns (Monitoring[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < _monitoring.length; i++) {
            if (_monitoring[i] != address(0)) {
                count++;
            }
        }

        Monitoring[] memory result = new Monitoring[](count);

        uint256 index = 0;
        for (uint256 i = 0; i < _monitoring.length; i++) {
            if (_monitoring[i] != address(0)) {
                result[index] = Monitoring({
                    version: i,
                    addr: _monitoring[i]
                });
                index++;
            }
        }
        return result;
    }

    // Remove an address from the monitoring list by replacing it with the zero address.
    function removeMonitoringAddress(address addressToRemove) external onlyOwner {
        bool found = false;
        // Find the address to be removed and replace it with the zero address.
        for (uint256 i = 0; i < _monitoring.length; i++) {
            if (_monitoring[i] == addressToRemove) {
                _monitoring[i] = address(0);
                found = true;
                break;
            }
        }
        require(found, "Monitorings: Address not found");
    }

    // Check whether the specified address is monitored and not blocked or not found
    function getServerMonitoringStatus(address serverAddress) external view returns (string memory) {
        (ServerStatus status,) = _getVotesMonitoredOrBlocked(serverAddress, false);
        string memory stringStatus = "NotFound";
        if (status == ServerStatus.Monitored) {
            stringStatus = "Monitored";
        } else if (status == ServerStatus.Blocked) {
            stringStatus = "Blocked";
        }
        return stringStatus;
    }

    // Get the number of votes on monitorings for the specified address
    function getTotalServerVotes(address serverAddress) external view returns (uint256) {
        (, uint256 totalVotes) = _getVotesMonitoredOrBlocked(serverAddress, true);
        return totalVotes;
    }

    // Vote on monitoring for the address
    function voteForServer(address serverAddress, address voterAddress) external {
        _voteForServer(serverAddress, voterAddress);
    }

    /**
     * @dev Retrieves the monitoring status and optionally the total votes for a given server address.
     * This function iterates through the `_monitoring` array and checks each monitoring contract to determine
     * whether the server exists, and if it does, whether it is blocked or simply being monitored.
     *
     * @param serverAddress The address of the server to be checked.
     * @param getVotes A boolean flag indicating whether to retrieve the total votes for the server.
     *
     * @return A tuple containing the ServerStatus enum value (NotFound, Monitored, Blocked) and the total votes.
     *         - ServerStatus: Indicates the final monitoring status of the server.
     *         - totalVotes: The total number of votes for this server across all monitoring contracts.
     *                       This value is only meaningful if `getVotes` is true and the server is not blocked.
     *
     * Requirements:
     * - serverAddress must not be the zero address.
     */
    function _getVotesMonitoredOrBlocked(address serverAddress, bool getVotes) private view returns (ServerStatus, uint256) {
        ServerStatus status = ServerStatus.NotFound;
        uint256 totalVotes = 0;
        for (uint256 i = 0; i < _monitoring.length; i++) {
            if (address(_monitoring[i]) == address(0)) {
                continue;
            }
            IAGEMonitoring monitoring = IAGEMonitoring(_monitoring[i]);
            if (monitoring.isServerExist(serverAddress)) {
                status = ServerStatus.Monitored;
                if (getVotes) {
                    totalVotes += monitoring.getServerVotes(serverAddress);
                }
                (bool blocked,) = monitoring.getServerBlocked(serverAddress);
                if (blocked) {
                    status = ServerStatus.Blocked;
                    totalVotes = 0;
                    break;
                }
            }
        }
        return (status, totalVotes);
    }

    function _isServerMonitored(address serverAddress) internal view returns (bool) {
        (ServerStatus status,) = _getVotesMonitoredOrBlocked(
            serverAddress,
            false
       );
        return status == ServerStatus.Monitored;
    }

    function _voteForServer(address serverAddress, address voterAddress) private {
        require(_isServerMonitored(serverAddress), "Monitorings: This address is not monitored or blocked");
        address monitoringAddress = _getMonitoring().addr;

        if (msg.sender != serverAddress) {
            voterAddress = msg.sender;
        }
        IAGEMonitoring(monitoringAddress).voteForServer(voterAddress, serverAddress);
    }

    function _getMonitoring() private view returns (Monitoring memory) {
        for (uint256 i = _monitoring.length; i > 0; i--) {
            if (_monitoring[i - 1] != address(0)) {
                return Monitoring({version: i - 1, addr: _monitoring[i - 1]});
            }
        }
        revert("Monitorings: no found");
    }

    function _addServerToMonitoring(uint256 gameId, address serverAddress) internal {
        address monitoringAddress = _getMonitoring().addr;

        IAGEMonitoring(monitoringAddress).addServerAddress(gameId, serverAddress);
    }
}

interface IAGEMonitoring {
    function addServerAddress(uint256 gameId, address serverAddress) external;
    function voteForServer(address voterAddress, address serverAddress) external;
    function getServerVotes(address serverAddress) external view returns (uint256);
    function isServerExist(address serverAddress) external view returns (bool);
    function getServerBlocked(address serverAddress) external view returns (bool, uint256);
}

abstract contract GameData is Ownable {

    // This contract is responsible for storing metadata related to various gaming servers.
    IGameData internal _gameData;

    // Utility function to get string representation of a ModuleType enum.
    function getModuleTypeString(IGameData.ModuleType moduleType) external view returns (string memory) {
        return _getModuleTypeString(moduleType);
    }

    function _getModuleTypeString(IGameData.ModuleType moduleType) internal view returns (string memory) {
        return _gameData.getModuleTypeString(moduleType);
    }

    // This function sets the address of the contract that will store game server metadata
    function setGameServerMetadata(address contracrAddress) external onlyOwner {
        _gameData = IGameData(contracrAddress);
    }

    // This function gets the address of the game server metadata contract
    function getGameServerMetadata() external view returns (address) {
        return address(_gameData);
    }

    // This function gets the game server data based on a given ID
    function getServerData(uint256 gameId) external view returns (string memory, string memory) {
        return _getServerData(gameId);
    }

    // This internal function actually retrieves the game server data
    function _getServerData(uint256 gameId) internal view returns (string memory, string memory) {
        string memory name = "";
        string memory symbol = "";
        if (address(_gameData) != address(0)) {
            (name, symbol) = _gameData.getServerData(gameId);
        }
        return (name, symbol);
    }
}
// Returns the contract name and symbol of a game based on its ID.
interface IGameData {

    // Enum representing the various types of modules that can be interacted with via the proxy.
    enum ModuleType {
        Server, // Represents a server module.
        Token, // Represents a token module.
        NFT, // Represents a NFT module.
        Shop, // Represents a shop or item shop module.
        Voting, // Represents a voting module.
        Lottery, // Represents a lottery module.
        Raffle, // Represents a raffle module.
        Game, // Represents a game module.
        Advertisement, // Represents an advertisement module.
        AffiliateProgram, // Represents an affiliate program module.
        Event, // Represents an event module.
        RatingSystem, // Represents a rating system module.
        SocialFunctions, // Represents a social functions module.
        Auction, // Represents an auction module.
        Charity // Represents a charity module.
    }
    function getServerData(uint256 gameId) external view returns (string memory, string memory);
    // Internal utility function to get string representation of a ModuleType enum.
    function getModuleTypeString(ModuleType moduleType) external view returns (string memory);
}


/*
 * This smart contract handles a modular system for managing various modules that can be added, updated, and removed.
 * It is an extension of a "Monitorings" contract and provides functionality to add new types of modules,
 * update existing ones, and query the state of these modules.
 */
abstract contract ModuleManager is MonitoringManager, GameData {
    
    // Structure defining a Module with a name, type, type as a string, and the address of its factory contract.
    struct Module {
        string moduleName;
        IGameData.ModuleType moduleType;
        string moduleTypeString;
        address moduleFactory;
    }

    // Store hashes of all modules.
    bytes32[] private _moduleList;
    // Mapping to store Module structs.
    mapping(bytes32 => Module) private _modules;

    // Adds a new module or updates an existing module
    function addOrUpdateModule(string memory moduleName, uint256 uintType,  address contractAddress, bool update) external onlyOwner {
        _addModule(moduleName, uintType, contractAddress, update);
    }

    // Adds a new Game Server module or pdates an existing Game Server module.
    function addOrUpdateGameServerModule(uint256 gameId, address contractAddress, bool update) external onlyOwner {
        (string memory moduleName,) = _getServerData(gameId);
        uint256 uintType = uint256(IGameData.ModuleType.Server);
        _addModule(moduleName, uintType, contractAddress, update);
    }

    // Internal function to add or update a module.
    function _addModule(string memory moduleName, uint256 uintType, address contractAddress, bool update) private {
        bytes32 hash = _getModuleHash(moduleName, uintType);
        bool exist = _modules[hash].moduleFactory != address(0);
        bool isRevert = true;
        IGameData.ModuleType moduleType = IGameData.ModuleType(uintType);
        Module memory module  = Module({
            moduleName: moduleName,
            moduleType: moduleType,
            moduleTypeString: _getModuleTypeString(moduleType),
            moduleFactory: contractAddress
        });

        if (update) {
            if (exist) {
                _modules[hash] = module;
                delete isRevert;
            }
        } else {
            if (!exist) {
                _modules[hash] = module;
                _moduleList.push(hash);
                delete isRevert;
            }
        }
        if (isRevert) {
            revert("Modules: Such a module already exists");
        }
    }

    // Removes an existing module.
    function removeModule(string memory moduleName, uint256 uintType) external  onlyOwner {
        bytes32 hash = _getModuleHash(moduleName, uintType);
        if (_modules[hash].moduleFactory != address(0)) {
            _modules[hash] = Module("", IGameData.ModuleType.Server, "", address(0));
            for (uint256 i = 0; i < _moduleList.length; i++) {
                if (_moduleList[i] == hash) {
                    _moduleList[i] = _moduleList[_moduleList.length - 1];
                    _moduleList.pop();
                    return;
                }
            }
        } else {
                revert("Modules: Such a module does not exist");
        }
    }

    // Retrieves all modules without any filtering.
    function getAllModules() external view returns (Module[] memory) {
        return _getFilteredModules(0xFFFFFFFF);
    }

    // Retrieves modules filtered by a specific type.
    function getModulesByType(IGameData.ModuleType moduleType) external view returns (Module[] memory) {
        return _getFilteredModules(uint256(moduleType));
    }

    // Internal function to get modules filtered by type.
    function _getFilteredModules(uint256 filterType) private view returns (Module[] memory) {
        uint256 count = 0;
        IGameData.ModuleType filteredType = IGameData.ModuleType(filterType);

        for (uint256 i = 0; i < _moduleList.length; i++) {
            bytes32 hash = _moduleList[i];
            if (filterType == 0xFFFFFFFF || _modules[hash].moduleType == filteredType) {
                count++;
            }
        }

        Module[] memory filteredModules = new Module[](count);

        uint256 j = 0;
        for (uint256 i = 0; i < _moduleList.length; i++) {
            bytes32 hash = _moduleList[i];
            if (filterType == 0xFFFFFFFF || _modules[hash].moduleType == filteredType) {
                filteredModules[j] = _modules[hash];
                j++;
            }
        }

        return filteredModules;
    }

    // Internal function to check if a module exists.
    function _isModuleExists(bytes32 hash) private view returns (bool) {
        bool existModule = _modules[hash].moduleFactory != address(0);
        return existModule;
    }

    // Deploys a module on a server. 
    // Checks if the server is authorized to deploy the module.
    function deployModuleOnServer(string memory factoryName, uint256 uintType, address ownerAddress)
      external onlyServerAutorised(msg.sender) returns (address) {
        uint256 END_OF_LIST = 1000;
        return _deploy(END_OF_LIST, factoryName, uintType, ownerAddress);
    }

    // Deploys a new game server contract and adds it to monitoring.
    function deployServerContract(uint256 gameId) external returns (address) {
        uint256 uintType = uint256(IGameData.ModuleType.Server);
        (string memory contractName,) = _getServerData(gameId);

        address minecraftServerAddress = _deploy(gameId, contractName, uintType, address(0));

        _mintTokenForServer(minecraftServerAddress);
        _addServerToMonitoring(gameId, minecraftServerAddress);

        return minecraftServerAddress;
    }

    // Abstract function to mint a token for a server.
    // Implementation is supposed to be provided by a derived contract.
    function _mintTokenForServer(address serverAddress) internal virtual;

    // Internal function to handle the actual deployment of modules or servers.
    function _deploy(uint256 gameId, string memory factoryName, uint256 uintType, address ownerAddress) private returns (address) {
        bytes32 hash = _getModuleHash(factoryName, uintType);

        (string memory name, string memory symbol) = _getServerData(gameId);
        return IFactory(_getModule(hash).moduleFactory).deployModule(name, symbol, msg.sender, ownerAddress);
    }

    // Internal utility function to fetch a module's data.
    function _getModule(bytes32 hash) private view returns (Module memory) {
        require(_isModuleExists(hash), "Modules: The module with this name and type does not exist");
        return _modules[hash];
    }

    // Internal utility function to calculate hash for a module.
    function _getModuleHash(string memory name, uint256 uintType) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(name, uintType));
    }

    // Modifier to check if the address is an authorized server.
    modifier onlyServerAutorised(address contractAddress) {
        require(_isServerMonitored(contractAddress), "Modules: This address is not monitored or blocked");
        _;
    }
}

interface IFactory {
    function deployModule(string memory name, string memory symbol, address serverAddress,
        address ownerAddress) external returns (address);
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
abstract contract ERC20Receiver is IERC20Receiver, BaseUtility {

    // Event emitted when Anhydrite tokens are deposited.
    event DepositAnhydrite(address indexed from, address indexed who, uint256 amount);
    // An event to track from which address the tokens were transferred, who transferred, to which address and the number of tokens
    event ChallengeIERC20Receiver(address indexed from, address indexed who, address indexed token, uint256 amount);

    constructor() {
        erc1820Registry.setInterfaceImplementer(address(this), keccak256("IERC20Receiver"), address(this));
    }

    // Implementation of IERC20Receiver, for receiving ERC20 tokens.
    function onERC20Received(address _from, address _who, uint256 _amount) external override returns (bytes4) {
        bytes4 validID = this.onERC20Received.selector;
        bytes4 returnValue = bytes4(keccak256("anything_else")); // Default value
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

// An interface declaring functions for the Anhydrite Gaming Ecosystem (AGE).
interface IAGE {
    function VERSION() external pure returns (uint256);
    function addPrice(string memory name, uint256 count) external;
    function getPrice(bytes32 key) external view returns (uint256);
    function getServerFromTokenId(uint256 tokenId) external view returns (address);
    function getTokenIdFromServer(address serverAddress) external view returns (uint256);
}

// The main contract for the Anhydrite Gaming Ecosystem (AGE).
// This contract integrates various functionalities including Ownership, Finance, Modules, ERC721, and more.
contract AGE is
    OwnableManager,
    FinanceManager,
    ModuleManager,
    IAGE,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Burnable,
    ERC20Receiver
{
    using Counters for Counters.Counter;

    // Defines the current version of the contract.
    uint256 public constant VERSION = 0;
    
    // A counter to manage unique token IDs.
    Counters.Counter private _tokenIdCounter;
    
    // Mapping between token IDs and corresponding contract addresses.
    mapping(uint256 => address) private _tokenContract;
    
    // Mapping between contract addresses and their corresponding token IDs.
    mapping(address => uint256) private _contractToken;

    struct Price {
        string name;
        uint256 price;
    }
    
    // Mapping to store the price associated with each service name.
    mapping(bytes32 => Price) internal _prices;
    bytes32[] internal _priceArray;

    constructor() ERC721("Anhydrite Gaming Ecosystem", "AGE") {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, "ipfs://bafkreif66z2aeoer6lyujghufat3nxtautrza3ucemwcwgfiqpajjlcroy");
        _tokenContract[tokenId] = msg.sender;
    }

    // Allows the owner to set the price for a specific service.
    function addPrice(string memory name, uint256 count) public override onlyOwner {
        bytes32 key = keccak256(abi.encodePacked(name));
        if (bytes(_prices[key].name).length == 0) {
            _priceArray.push(key);
        }
        _prices[key] = Price(name, count);
    }

    // Retrieves the price for a given service name.
    function getPrice(bytes32 key) public view override returns (uint256) {
        return _prices[key].price;
    }
    
    function getPrices() public view returns (Price[] memory) {
        uint256 length = _priceArray.length;
        Price[] memory prices = new Price[](length);
        
        for (uint256 i = 0; i < length; i++) {
            prices[i] = _prices[_priceArray[i]];
        }
        
        return prices;
    }

    // Retrieves the address of the server associated with a given token ID.
    function getServerFromTokenId(uint256 tokenId) public view override returns (address) {
        return _tokenContract[tokenId];
    }

    // Retrieves the token ID associated with a given server address.
    function getTokenIdFromServer(address serverAddress) public view override returns (uint256) {
        return _contractToken[serverAddress];
    }

    // Overrides the tokenURI function to provide the URI for each token.
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    // Checks if the contract supports a specific interface.
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC721URIStorage) returns (bool) {
        return interfaceId == type(IAGE).interfaceId ||
               interfaceId == type(IERC20Receiver).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    // Internal function to mint a token for a given server.
    function _mintTokenForServer(address serverAddress) internal override {
        require(_contractToken[serverAddress] == 0, "AnhydriteGamingEcosystem: This contract has already used safeMint");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _tokenContract[tokenId] = serverAddress;
        _contractToken[serverAddress] = tokenId;

        _mint(serverAddress, tokenId);
        _setTokenURI(tokenId, tokenURI(0));
    }

    // Internal function that is called before a token is transferred.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // Internal function to burn a token.
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
}
