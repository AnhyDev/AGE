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
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract BaseUtility is Ownable {
    // Main project token (ANH) address
    IANH public constant ANHYDRITE = IANH(0x9a9a0EB311E937C7D75d3468C8b0135d4976DAa7);

    // This contract is responsible for storing metadata related to various gaming servers.
    IGameData internal _gameData;
    
    // Mapping to store the price associated with each service name.
    mapping(string => uint256) internal _prices;

    // Voting structure
    struct VoteResult {
        address[] isTrue;
        address[] isFalse;
        uint256 timestamp;
    }

    // Returns the interface address of the proxy contract
    function getProxyAddress() public view returns (address) {
        return ANHYDRITE.getProxyAddress();
    }

    // This function returns the IProxy interface for the Anhydrite token's proxy contract
    function _proxyContract() internal view returns (IProxy) {
        return IProxy(ANHYDRITE.getProxyAddress());
    }

    // Checks whether the address is among the owners of the proxy contract
    function _isProxyOwner(address senderAddress) internal view returns (bool) {
        return _proxyContract().isProxyOwner(senderAddress);
    }

    // This function sets the address of the contract that will store game server metadata
    function setGameServerMetadata(address contracrAddress) external onlyOwner onlyProxyOwner {
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
        string memory name = "Anhydrite server module ";
        string memory symbol = "AGE_";
        if (address(_gameData) != address(0)) {
            (name, symbol) = _gameData.getServerData(gameId);
        }
        return (name, symbol);
    }

    // Internal function for handling votes, updating the VoteResult structure
    function _votes(VoteResult storage result, bool vote) internal returns (uint256, uint256, uint256) {
        uint256 _totalOwners = 1;
        if (address(_proxyContract()) != address(0)) {
            _totalOwners = _proxyContract().getTotalOwners();
        }
        if (vote) {
            result.isTrue.push(msg.sender);
        } else {
            result.isFalse.push(msg.sender);
        }
        return (result.isTrue.length, result.isFalse.length, _totalOwners);
    }

    // Internal function to reset a vote after completion or expiration
    function _resetVote(VoteResult storage vote) internal {
        vote.isTrue = new address[](0);
        vote.isFalse = new address[](0);
        vote.timestamp = 0;
    }

    // Internal function to finalize the voting process
    function _completionVoting(VoteResult storage result) internal {
        _increaseArrays(result);
        _resetVote(result);
    }

    // Internal function to increase some kind of interest for the voting participants
    function _increaseArrays(VoteResult memory result) internal {
        if (address(_proxyContract()) != address(0)) {
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
    }

    // Calls the 'increase' method on the proxy contract to handle voting participants
    function _increase(address[] memory owners) internal {
        _proxyContract().increase(owners);
    }

    // Checks if a given address has already voted in a specific VoteResult
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
    modifier onlyProxyOwner() {
        IProxy proxy = _proxyContract();
        if (address(proxy) != address(0) && proxy.getTotalOwners() > 0) {
            require(_isProxyOwner(msg.sender), "BaseUtility: caller is not the proxy owner");
        } else {
            _checkOwner();
        }
        _;
    }

    // A modifier that returns true if the given address has not yet been voted
    modifier hasNotVoted(VoteResult memory result) {
        require(!_hasOwnerVoted(result, msg.sender), "BaseUtility: Already voted");
        _;
    }

    // This override function and is deactivated
    function renounceOwnership() public view override onlyOwner {
        revert("BaseUtility: this function is deactivated");
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

// Returns the contract name and symbol of a game based on its ID.
interface IGameData {
    function getServerData(uint256 gameId) external view returns (string memory, string memory);
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
abstract contract OwnableManager is BaseUtility {
    // Proposed new owner
    address internal _proposedOwner;
    // Structure for counting votes
    VoteResult internal _votesForNewOwner;

    // Event about the fact of voting, parameters: voter, proposedOwner, vote
    event VotingForOwner(address indexed voter, address proposedOwner, bool vote);
    // Event about the fact of making a decision on voting, parameters: voter, proposedOwner, vote, votesFor, votesAgainst
    event VotingOwnerCompleted(address indexed voter, address proposedOwner,  bool vote, uint256 votesFor, uint256 votesAgainst);
    // Event to close a poll that has expired
    event CloseVoteForNewOwner(address indexed decisiveVote, address indexed votingObject, uint256 votesFor, uint256 votesAgainst);

    // Overriding the transferOwnership function, which now triggers the start of a vote to change the owner of a smart contract
    function transferOwnership(address proposedOwner) public virtual override onlyProxyOwner {
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

    // Vote For New Owner
    function voteForNewOwner(bool vote) external onlyProxyOwner {
        _voteForNewOwner(vote);
    }

    // Votes must reach a 60% threshold to pass. If over 40% are downvotes, the measure fails.
    function _voteForNewOwner(bool vote) internal hasNotVoted(_votesForNewOwner) {
        require(_isActiveForVoteOwner(), "OwnableManager: there are no votes at this address");

        (uint256 votestrue, uint256 votesfalse, uint256 _totalOwners) = _votes(_votesForNewOwner, vote);

        emit VotingForOwner(msg.sender, _proposedOwner, vote);

        if (votestrue * 100 >= _totalOwners * 60) {
            _transferOwnership(_proposedOwner);
            _completionVotingNewOwner(vote, votestrue, votesfalse);
        } else if (votesfalse * 100 > _totalOwners * 40) {
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
    function closeVoteForNewOwner() public onlyOwner {
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
    function _isActiveForVoteOwner() internal view returns (bool) {
        return _proposedOwner != address(0) && _proposedOwner != owner();
    }
}

/*
 * The Monitorings smart contract is designed to work with monitoring,
 * add, delete, vote for the server, get the number of votes, and more.
 */
abstract contract Monitorings is BaseUtility {
    enum ServerStatus {
        NotFound,
        Monitored,
        Blocked
    }

    address[] internal _monitoring;

    struct Monitoring {
        uint256 version;
        address addr;
    }

    // Add a new address to the monitoring list.
    function addMonitoring(address newAddress) external onlyOwner onlyProxyOwner {
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
    function removeMonitoringAddress(address addressToRemove) external onlyOwner onlyProxyOwner {
        bool found = false;
        // Find the address to be removed and replace it with the zero address.
        for (uint256 i = 0; i < _monitoring.length; i++) {
            if (_monitoring[i] == addressToRemove) {
                _monitoring[i] = address(0);
                found = true;
                break;
            }
        }
        require(found, "Monitorings: Address not found in monitoring list");
    }

    // Check whether the specified address is monitored and not blocked or not found
    function getServerMonitoringStatus(address serverAddress) external view returns (string memory) {
        (ServerStatus status, ) = _getVotesMonitoredOrBlocked(serverAddress, false);
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
        (, uint256 totalVotes) = _getVotesMonitoredOrBlocked( serverAddress, true );
        return totalVotes;
    }

    // Vote on monitoring for the address
    function voteForServer(address serverAddress) external {
        _voteForServer(serverAddress);
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
    function _getVotesMonitoredOrBlocked(address serverAddress, bool getVotes) internal view returns (ServerStatus, uint256) {
        require( serverAddress != address(0), "Monitorings: Server address cannot be zero address" );
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
                (bool blocked, ) = monitoring.isServerBlocked(serverAddress);
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
        (ServerStatus status, ) = _getVotesMonitoredOrBlocked(
            serverAddress,
            false
        );
        return status == ServerStatus.Monitored;
    }

    function _voteForServer(address serverAddress) internal {
        require( _isServerMonitored(serverAddress), "Monitorings: This address is not monitored or blocked" );
        address monitoringAddress = _getMonitoring().addr;

        IAGEMonitoring(monitoringAddress).voteForServer( msg.sender, serverAddress );
    }

    function _getMonitoring() internal view returns (Monitoring memory) {
        require( _monitoring.length > 0, "Monitorings: Monitoring list is empty" );

        for (uint256 i = _monitoring.length; i > 0; i--) {
            if (_monitoring[i - 1] != address(0)) {
                return Monitoring({ version: i - 1, addr: _monitoring[i - 1] });
            }
        }
        revert( "Monitorings: No non-zero addresses found in the monitoring list" );
    }

    function _addServerToMonitoring(uint256 gameId, address serverAddress) internal {
        address monitoringAddress = _getMonitoring().addr;

        IAGEMonitoring(monitoringAddress).addServerAddress(
            gameId,
            serverAddress
        );
    }
}

interface IAGEMonitoring {
    function addServerAddress(uint256 gameId, address serverAddress) external;
    function voteForServer(address voterAddress, address serverAddress) external;
    function isServerExist(address serverAddress) external view returns (bool);
    function isServerBlocked(address serverAddress) external view returns (bool, uint256);
    function getServerVotes(address serverAddress) external view returns (uint256);
}

/*
 * This smart contract handles a modular system for managing various modules that can be added, updated, and removed.
 * It is an extension of a "Monitorings" contract and provides functionality to add new types of modules,
 * update existing ones, and query the state of these modules.
 */
abstract contract Modules is Monitorings {

    // Define types of modules available.
    enum ModuleType {
        Server,
        Shop,
        Voting,
        Lottery,
        Raffle,
        Game,
        Advertisement,
        AffiliateProgram,
        Event,
        RatingSystem,
        SocialFunctions,
        Auction,
        Charity
    }

    // Define the structure of a Module.
    struct Module {
        string moduleName;
        ModuleType moduleType;
        string moduleTypeString;
        address moduleFactory;
    }

    // Store hashes of all modules.
    bytes32[] private _moduleHash;
    // Mapping to store Module structs.
    mapping(bytes32 => Module) private _modules;

    // Adds a new module or updates an existing module
    function addOrUpdateModule(string memory moduleName, uint256 uintType,  address contractAddress, bool update) external onlyOwner onlyProxyOwner {
        _addModule(moduleName, uintType, contractAddress, update);
    }

    // Adds a new Game Server module or pdates an existing Game Server module.
    function addOrUpdateGameServerModule(uint256 gameId, address contractAddress, bool update) external onlyOwner onlyProxyOwner {
        (string memory moduleName, ) = _getServerData(gameId);
        uint256 uintType = uint256(ModuleType.Server);
        _addModule(moduleName, uintType, contractAddress, update);
    }

    // Internal function to add or update a module.
    function _addModule( string memory moduleName, uint256 uintType, address contractAddress, bool update ) internal {
        bytes32 hash = _getModuleHash(moduleName, uintType);
        ModuleType moduleType = ModuleType(uintType);

        if (update) {
            if (_modules[hash].moduleFactory != address(0)) {
                _modules[hash] = Module({
                    moduleName: moduleName,
                    moduleType: moduleType,
                    moduleTypeString: _getModuleTypeString(moduleType),
                    moduleFactory: contractAddress
                });
            } else {
                revert("Modules: Such a module does not exist");
            }
        } else {
            if (_modules[hash].moduleFactory == address(0)) {
                _modules[hash] = Module({
                    moduleName: moduleName,
                    moduleType: moduleType,
                    moduleTypeString: _getModuleTypeString(moduleType),
                    moduleFactory: contractAddress
                });
                _moduleHash.push(hash);
            } else {
                revert("Modules: Such a module already exists");
            }
        }
    }

    // Removes an existing module.
    function removeModule(string memory moduleName, uint256 uintType) external  onlyOwner onlyProxyOwner {
        bytes32 hash = _getModuleHash(moduleName, uintType);
        if (_modules[hash].moduleFactory != address(0)) {
            _modules[hash] = Module("", ModuleType.Server, "", address(0));
            for (uint256 i = 0; i < _moduleHash.length; i++) {
                if (_moduleHash[i] == hash) {
                    _moduleHash[i] = _moduleHash[_moduleHash.length - 1];
                    _moduleHash.pop();
                    return;
                }
            }
        } else {
                revert("Modules: Such a module does not exist");
        }
    }

    // Returns the contract address of a module.
    function getModuleAddress(string memory name, uint256 uintType)
        external
        view
        returns (address)
    {
        Module memory module = _getModule(_getModuleHash(name, uintType));
        return module.moduleFactory;
    }

    // Retrieves all modules without any filtering.
    function getAllModules() external view returns (Module[] memory) {
        return _getFilteredModules(0xFFFFFFFF);
    }

    // Retrieves modules filtered by a specific type.
    function getModulesByType(ModuleType moduleType) external view returns (Module[] memory) {
        return _getFilteredModules(uint256(moduleType));
    }

    // Utility function to get string representation of a ModuleType enum.
    function getModuleTypeString(ModuleType moduleType) external pure returns (string memory) {
        return _getModuleTypeString(moduleType);
    }

    // Internal function to get modules filtered by type.
    function _getFilteredModules(uint256 filterType) internal view returns (Module[] memory) {
        uint256 count = 0;
        ModuleType filteredType = ModuleType(filterType);

        for (uint256 i = 0; i < _moduleHash.length; i++) {
            bytes32 hash = _moduleHash[i];
            if (filterType == 0xFFFFFFFF || _modules[hash].moduleType == filteredType) {
                count++;
            }
        }

        Module[] memory filteredModules = new Module[](count);

        uint256 j = 0;
        for (uint256 i = 0; i < _moduleHash.length; i++) {
            bytes32 hash = _moduleHash[i];
            if (filterType == 0xFFFFFFFF || _modules[hash].moduleType == filteredType) {
                filteredModules[j] = _modules[hash];
                j++;
            }
        }

        return filteredModules;
    }

    // Internal function to check if a module exists.
    function _isModuleExists(bytes32 hash) internal view returns (bool) {
        bool existModule = _modules[hash].moduleFactory != address(0);
        return existModule;
    }

    // Deploys a module on a server. 
    // Checks if the server is authorized to deploy the module.
    function deployModuleOnServer(
        string memory factoryName,
        uint256 uintType,
        address ownerAddress
    ) external onlyServerAutorised(msg.sender) returns (address) {
        uint256 END_OF_LIST = 1000;
        return _deploy(END_OF_LIST, factoryName, uintType, ownerAddress);
    }

    // Deploys a new game server contract and adds it to monitoring.
    function deployServerContract(uint256 gameId) external returns (address) {
        uint256 uintType = uint256(ModuleType.Server);
        (string memory contractName, ) = _getServerData(gameId);

        address minecraftServerAddress = _deploy(
            gameId,
            contractName,
            uintType,
            address(0)
        );

        _mintTokenForServer(minecraftServerAddress);
        _addServerToMonitoring(gameId, minecraftServerAddress);

        return minecraftServerAddress;
    }

    // Abstract function to mint a token for a server.
    // Implementation is supposed to be provided by a derived contract.
    function _mintTokenForServer(address serverAddress) internal virtual;

    // Internal function to handle the actual deployment of modules or servers.
    function _deploy( uint256 gameId, string memory factoryName, uint256 uintType, address ownerAddress ) internal returns (address) {
        bytes32 hash = _getModuleHash(factoryName, uintType);

        (string memory name, string memory symbol) = _getServerData(gameId);
        return IFactory(_getModule(hash).moduleFactory).deployModule(name, symbol, msg.sender, ownerAddress);
    }

    // Internal utility function to fetch a module's data.
    function _getModule(bytes32 hash) internal view returns (Module memory) {
        require(_isModuleExists(hash), "Modules: The module with this name and type does not exist");
        return _modules[hash];
    }

    // Internal utility function to calculate hash for a module.
    function _getModuleHash(string memory name, uint256 uintType) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(name, uintType));
    }

    // Internal utility function to get string representation of a ModuleType enum.
    function _getModuleTypeString(ModuleType moduleType) internal pure returns (string memory) {
        if (moduleType == ModuleType.Server) {
            return "Server";
        } else if (moduleType == ModuleType.Shop) {
            return "Shop";
        } else if (moduleType == ModuleType.Voting) {
            return "Voting";
        } else if (moduleType == ModuleType.Lottery) {
            return "Lottery";
        } else if (moduleType == ModuleType.Raffle) {
            return "Raffle";
        } else if (moduleType == ModuleType.Game) {
            return "Game";
        } else if (moduleType == ModuleType.Advertisement) {
            return "Advertisement";
        } else if (moduleType == ModuleType.AffiliateProgram) {
            return "AffiliateProgram";
        } else if (moduleType == ModuleType.Event) {
            return "Event";
        } else if (moduleType == ModuleType.RatingSystem) {
            return "RatingSystem";
        } else if (moduleType == ModuleType.SocialFunctions) {
            return "SocialFunctions";
        } else if (moduleType == ModuleType.Auction) {
            return "Auction";
        } else if (moduleType == ModuleType.Charity) {
            return "Charity";
        } else {
            return "Unknown";
        }
    }

    // Modifier to check if the address is an authorized server.
    modifier onlyServerAutorised(address contractAddress) {
        require( _isServerMonitored(contractAddress), "Modules: This address is not monitored or blocked." );
        _;
    }
}

interface IFactory {function deployModule( string memory name, string memory symbol, address serverContractAddress,
        address ownerAddress ) external returns (address);
}

abstract contract Finances is BaseUtility {
    // Function for transferring Ether
    function transferMoney(address payable recipient, uint256 amount) external onlyOwner onlyProxyOwner {
        require( address(this).balance >= amount, "Finances: Contract has insufficient balance" );
        recipient.transfer(amount);
    }

    // Function for transferring ERC20 tokens
    function transferERC20Tokens( address _tokenAddress, address _to, uint256 _amount ) external onlyOwner onlyProxyOwner {
        IERC20 token = IERC20(_tokenAddress);
        require( token.balanceOf(address(this)) >= _amount, "Finances: Not enough tokens on contract balance" );
        token.transfer(_to, _amount);
    }

    // Function for transferring ERC721 tokens
    function transferERC721Token( address _tokenAddress, address _to, uint256 _tokenId ) external onlyOwner onlyProxyOwner {
        ERC721 token = ERC721(_tokenAddress);
        require( token.ownerOf(_tokenId) == address(this), "Finances: The contract is not the owner of this token" );
        token.safeTransferFrom(address(this), _to, _tokenId);
    }
}

// Interface for contracts that are capable of receiving ERC20 (ANH) tokens.
interface IERC20Receiver {
    // Function that is triggered when ERC20 (ANH) tokens are received.
    function onERC20Received(address _from, address _who, uint256 _amount) external returns (bytes4);
    // An event to track from which address the tokens were transferred, who transferred, to which address and the number of tokens
    event ChallengeIERC20Receiver(address indexed from, address indexed who, address indexed token, uint256 amount);
}

// An interface declaring functions for the Anhydrite Gaming Ecosystem (AGE).
interface IAGE {
    function VERSION() external pure returns (uint256);
    function setPrice(string memory name, uint256 count) external;
    function getPrice(string memory name) external view returns (uint256);
    function getServerFromTokenId(uint256 tokenId) external view returns (address);
    function getTokenIdFromServer(address serverAddress) external view returns (uint256);
}

// The main contract for the Anhydrite Gaming Ecosystem (AGE).
// This contract integrates various functionalities including Ownership, Finance, Modules, ERC721, and more.
contract AnhydriteGamingEcosystem is
    OwnableManager,
    Finances,
    Modules,
    IAGE,
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Burnable,
    IERC20Receiver
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

    // Event emitted when Anhydrite tokens are deposited.
    event DepositAnhydrite(address indexed from, address indexed who, uint256 amount);

    constructor() ERC721("Anhydrite Gaming Ecosystem", "AGE") {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, "ipfs://bafkreif66z2aeoer6lyujghufat3nxtautrza3ucemwcwgfiqpajjlcroy");
        _tokenContract[tokenId] = msg.sender;
        IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24).setInterfaceImplementer(
            address(this), keccak256("IERC20Receiver"), address(this));
    }

    // Allows the owner to set the price for a specific service.
    function setPrice(string memory name, uint256 count) public override onlyOwner onlyProxyOwner {
        _prices[name] = count;
    }

    // Retrieves the price for a given service name.
    function getPrice(string memory name) public view override returns (uint256) {
        return _prices[name];
    }

    // Retrieves the address of the server associated with a given token ID.
    function getServerFromTokenId(uint256 tokenId) public view override returns (address) {
        return _tokenContract[tokenId];
    }

    // Retrieves the token ID associated with a given server address.
    function getTokenIdFromServer(address serverAddress) public view override returns (uint256) {
        return _contractToken[serverAddress];
    }

    // Handles received ERC20 tokens.
    function onERC20Received(address _from, address _who, uint256 _amount) external override returns (bytes4) {
        bytes4 fakeID = bytes4(keccak256("anything_else"));
        bytes4 validID = this.onERC20Received.selector;
        bytes4 returnValue = fakeID; // Default value
        if (Address.isContract(msg.sender)) {
            if (msg.sender == address(ANHYDRITE)) {
                emit DepositAnhydrite(_from, _who, _amount);
                returnValue = validID;
            } else {
                try IERC20(msg.sender).balanceOf(address(this)) returns (
                    uint256 balance
                ) {
                    if (balance >= _amount) {emit ChallengeIERC20Receiver( _from, _who, msg.sender, _amount);
                        returnValue = validID;
                    }
                } catch {
                    // No need to change returnValue, it's already set to fakeID
                }
            }
        }
        return returnValue;
    }

    // Overrides the tokenURI function to provide the URI for each token.
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    // Checks if the contract supports a specific interface.
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC721URIStorage) returns (bool) {
        return interfaceId == type(IAGE).interfaceId || super.supportsInterface(interfaceId);
    }

    // Overrides the transferOwnership function.
    function transferOwnership(address proposedOwner) public override(Ownable, OwnableManager) {
        OwnableManager.transferOwnership(proposedOwner);
    }

    // Internal function to mint a token for a given server.
    function _mintTokenForServer(address serverAddress) internal override {
        require( _contractToken[serverAddress] == 0, "AnhydriteGamingEcosystem: This contract has already used safeMint" );
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _tokenContract[tokenId] = serverAddress;
        _contractToken[serverAddress] = tokenId;

        _mint(serverAddress, tokenId);
        _setTokenURI(tokenId, tokenURI(0));
    }

    // Internal function that is called before a token is transferred.
    function _beforeTokenTransfer( address from, address to, uint256 tokenId, uint256 batchSize ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // Internal function to burn a token.
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
}

// Interface for the ERC1820 Registry.
interface IERC1820Registry {
    function setInterfaceImplementer(address account, bytes32 interfaceHash, address implementer ) external;
}
