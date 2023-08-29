// SPDX-License-Identifier: All rights reserved
// Anything related to the Anhydrite project, except for the OpenZeppelin library code, is protected.
// Copying, modifying, or using without proper attribution to the Anhydrite project and a link to https://anh.ink is strictly prohibited.

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/// @custom:security-contact support@anh.ink

/*
* GameServerMetadata is a smart contract that converts the elements of the GameServers enum to the name
* and symbol of the game server blockchain contract.
*
* It does not read or change the blockchain.
*/
interface IGameServerMetadata {
    function gameServerToString(uint256 gameId) external pure returns (string memory, string memory);
}

abstract contract GameServerMetadata is IGameServerMetadata {
        enum GameServers {
        /*  0. */ Minecraft,
        /*  1. */ CSGO,
        /*  2. */ GTA_Online,
        /*  3. */ ARK_Survival_Evolved,
        /*  4. */ Rust,
        /*  5. */ Team_Fortress_2,
        /*  6. */ Garrys_Mod,
        /*  7. */ DayZ,
        /*  8. */ Terraria,
        /*  9. */ Starbound,
        /* 10. */ Unturned,
        /* 11. */ Factorio,
        /* 12. */ Space_Engineers,
        /* 13. */ Conan_Exiles,
        /* 14. */ Empyrion_Galactic_Survival,
        /* 15. */ Battlefield_Series,
        /* 16. */ Call_of_Duty_Series,
        /* 17. */ Seven_Days_to_Die,
        /* 18. */ CS_1_6,
        /* 19. */ OtherServersGames,
        /* 20. */ CentralizedGames,
        /* 21. */ END_OF_LIST
    }

    // Checks if a given uint256 gameId is in the GameServers enum, and if so, returns the corresponding name and character.
    function gameServerToString(uint256 gameId) external override pure returns (string memory, string memory) {
        return _gameServerToString(gameId);
    }

    function _gameServerToString(uint256 gameId) internal pure returns (string memory, string memory) {
        GameServers game = GameServers(gameId);
        if (game == GameServers.Minecraft) {
            return ("Anhydrite Minecraft server contract", "ANH_MC");
        }
        if (game == GameServers.CSGO) {
            return ("Anhydrite CSGO server contract", "ANH_CSGO");
        }
        if (game == GameServers.GTA_Online) {
            return ("GTA Online server contract", "ANH_GTA");
        }
        if (game == GameServers.ARK_Survival_Evolved) {
            return ("Anhydrite ARK Survival Evolved server contract", "ANH_ARKS");
        }
        if (game == GameServers.Rust) {
            return ("Anhydrite Rust server contract", "ANH_RST");
        }
        if (game == GameServers.Team_Fortress_2) {
            return ("Anhydrite Team Fortress 2 server contract", "ANH_TF");
        }
        if (game == GameServers.Garrys_Mod) {
            return ("Anhydrite Garrys Mod server contract", "ANH_GM");
        }
        if (game == GameServers.DayZ) {
            return ("Anhydrite DayZ server contract", "ANH_DZ");
        }
        if (game == GameServers.Terraria) {
            return ("Anhydrite Terraria server contract", "ANH_TER");
        }
        if (game == GameServers.Starbound) {
            return ("Anhydrite Starbound server contract", "ANH_SB");
        }
        if (game == GameServers.Unturned) {
            return ("Anhydrite Unturned server contract", "ANH_UNT");
        }
        if (game == GameServers.Factorio) {
            return ("Anhydrite Factorio server contract", "ANH_FCT");
        }
        if (game == GameServers.Space_Engineers) {
            return ("Anhydrite Space Engineers server contract", "ANH_SPE");
        }
        if (game == GameServers.Conan_Exiles) {
            return ("Anhydrite Conan Exiles server contract", "ANH_CE");
        }
        if (game == GameServers.Empyrion_Galactic_Survival) {
            return ("Anhydrite Empyrion Galactic Survival server contract", "ANH_EGS");
        }
        if (game == GameServers.Battlefield_Series) {
            return ("Anhydrite Battlefield Series server contract", "ANH_BF");
        }
        if (game == GameServers.Call_of_Duty_Series) {
            return ("Anhydrite Call of Duty Series server contract", "ANH_CDS");
        }
        if (game == GameServers.Seven_Days_to_Die) {
            return ("Anhydrite Seven Days to Die server contract", "ANH_SDD");
        }
        if (game == GameServers.CS_1_6) {
            return ("Counter-Strike 1.6 server contract", "ANH_CS16");
        }
        if (game == GameServers.OtherServersGames) {
            return ("Anhydrite Other Games server contract", "ANH_OTHER");
        }
        if (game == GameServers.CentralizedGames) {
            return ("Anhydrite Centralized Games server contract", "ANH_CG");
        }
        return ("Anhydrite server module ", "ANH_");
    }
}

/*
* VotingOwner is the only way to change the owner of a smart contract.
* The standard Ownable owner change functions from OpenZeppelin are blocked.
*/
interface IVotingOwner {
    function proposedVoteForOwner(address proposed) external;
    function voteForNewOwner(bool vote) external;
    function getActiveForVoteOwner() external view returns (bool, address);

    event VotingForOwner(address indexed voter, address votingSubject, bool vote);
    event VotingOwnerCompleted(address indexed voter, address votingSubject, bool vote, uint votesFor, uint votesAgainst);
}

abstract contract VotingOwner is IVotingOwner, Ownable {
    
    IProxy internal immutable _proxyContract;

    struct VoteResult {
        address[] isTrue;
        address[] isFalse;
        uint256 timestamp;
    }

    address internal _proposedOwner;
    VoteResult internal _votesForNewOwner;

    constructor(address proxyAddress) {
        _proxyContract = IProxy(proxyAddress);
    }

    // Please provide the address of the new owner for the smart contract.
    function proposedVoteForOwner(address proposedOwner) external override onlyProxyOwner(msg.sender) {
        require(!_isActiveForVoteOwner(), "VotingOwner: voting is already activated");
        require(!_proxyContract.isBlacklisted(proposedOwner), "VotingOwner: this address is blacklisted");
        require(_isProxyOwner(proposedOwner), "VotingOwner: caller is not the proxy owner");

        _proposedOwner = proposedOwner;
        _votesForNewOwner = VoteResult(new address[](0), new address[](0), block.timestamp);
        _voteForNewOwner(true);
    }

    function voteForNewOwner(bool vote) external override onlyProxyOwner(_proposedOwner) {
        _voteForNewOwner(vote);
    }

    // Voting for the address of the new owner of the smart contract
    function _voteForNewOwner(bool vote) internal {
        require(_isActiveForVoteOwner(), "VotingOwner: there are no votes at this address");

        if (vote) {
            _votesForNewOwner.isTrue.push(msg.sender);
        } else {
            _votesForNewOwner.isFalse.push(msg.sender);
        }

        uint256 _totalOwners = _proxyContract.getTotalOwners();

        uint votestrue = _votesForNewOwner.isTrue.length;
        uint votesfalse = _votesForNewOwner.isFalse.length;

        emit VotingForOwner(msg.sender, _proposedOwner, vote);

        if (votestrue * 100 >= _totalOwners * 60) {
            _transferOwnership(_proposedOwner);
            _resetVote(_votesForNewOwner);
            emit VotingOwnerCompleted(msg.sender, _proposedOwner, vote, votestrue, votesfalse);
            _proposedOwner = address(0);
        } else if (votesfalse * 100 > _totalOwners * 40) {
            _resetVote(_votesForNewOwner);
            emit VotingOwnerCompleted(msg.sender, _proposedOwner, vote, votestrue, votesfalse);
            _proposedOwner = address(0);
        }
    }

    // Check if voting is enabled for new contract owner and their address.
    function getActiveForVoteOwner() external view returns (bool, address) {
        require(_isActiveForVoteOwner(), "VotingOwner: re is no active voting");
        return (_isActiveForVoteOwner(), _proposedOwner);
    }

    function _isActiveForVoteOwner() internal view returns (bool) {
        return _proposedOwner != address(0) && _proposedOwner !=  owner();
    }

    function _resetVote(VoteResult storage vote) internal {
        vote.isTrue = new address[](0);
        vote.isFalse = new address[](0);
        vote.timestamp = 0;
    }

    function _isProxyOwner(address senderAddress) internal view returns (bool) {
        return _proxyContract.isProxyOwner(senderAddress);
    }

    // Modifier that checks whether you are among the owners of the proxy smart contract and whether you have the right to vote
    modifier onlyProxyOwner(address senderAddress) {
        require(_isProxyOwner(senderAddress), "VotingOwner: caller is not the proxy owner");
        _;
    }

    // The renounceOwnership() function is blocked
    function renounceOwnership() public override onlyOwner onlyProxyOwner(msg.sender) {
        bool deact = false;
        require(deact, "VotingOwner: this function is deactivated");
        _transferOwnership(owner());
    }

    // The transferOwnership(address newOwner) function is blocked
    function transferOwnership(address newOwner) public override onlyOwner onlyProxyOwner(msg.sender) {
        bool deact = false;
        require(deact, "VotingOwner: this function is deactivated");
        require(newOwner != address(0), "VotingOwner: new owner is the zero address");
        _transferOwnership(owner());
    }
}

/*
* The Monitorings smart contract is designed to work with monitoring,
* add, delete, vote for the server, get the number of votes, and more.
*/
interface IMonitorings {
    function addMonitoring(address newAddress) external;
    function getMonitoring() external view returns (uint256, address);
    function getNumberOfMonitorings() external view returns (uint256);
    function getMonitoringAddresses() external view returns (uint256[] memory, address[] memory);
    function removeMonitoringAddress(address addressToRemove) external;
    function isServerMonitored(address serverAddress) external view returns (bool);
    function voteForServer(address serverAddress) external;
    function getTotalServerVotes(address serverAddress) external view returns (uint256);
}

abstract contract Monitorings is VotingOwner, IMonitorings {

    address[] internal _monitoring;

    // Add a new address to the monitoring list.
    function addMonitoring(address newAddress) external override onlyOwner onlyProxyOwner(msg.sender) {
        _monitoring.push(newAddress);
    }

    // Get the last non-zero monitoring address and its index.
    function getMonitoring() external view override returns (uint256, address) {
        return _getMonitoring();
    }

    function getNumberOfMonitorings() external view override returns (uint256) {
        return _monitoring.length;
    }

    // Get the list of non-zero monitoring addresses and their indices.
    function getMonitoringAddresses() external override view returns (uint256[] memory, address[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < _monitoring.length; i++) {
            if (_monitoring[i] != address(0)) {
                count++;
            }
        }

        uint256[] memory indices = new uint256[](count);
        address[] memory addresses = new address[](count);

        uint256 index = 0;
        for (uint256 i = 0; i < _monitoring.length; i++) {
            if (_monitoring[i] != address(0)) {
                indices[index] = i;
                addresses[index] = _monitoring[i];
                index++;
            }
        }

        return (indices, addresses);
    }

    // Remove an address from the monitoring list by replacing it with the zero address.
    function removeMonitoringAddress(address addressToRemove) external override onlyOwner  onlyProxyOwner(msg.sender) {
        bool found = false;

        // Find the address to be removed and replace it with the zero address.
        for (uint256 i = 0; i < _monitoring.length; i++) {
            if (_monitoring[i] == addressToRemove) {
                _monitoring[i] = address(0);
                found = true;
                break;
            }
        }

        require(found, "Address not found in monitoring list");
    }

    // Check whether the specified address is monitored
    function isServerMonitored(address serverAddress) external override view returns (bool) {
        return _isServerMonitored(serverAddress);
    }

    function _isServerMonitored(address serverAddress) internal view returns (bool) {
        require(serverAddress != address(0), "Server address cannot be zero address");

        bool exists = false;

        for(uint i = 0; i < _monitoring.length; i++) {
            if(address(_monitoring[i]) == address(0)) {
                continue;
            }

            if(IAnhydriteMonitoring(_monitoring[i]).isServerExist(serverAddress)) {
                exists = true;
                break;
            }
        }

        return exists;
    }

    function _isServerBlocked(address serverAddress) internal view returns (bool) {
        require(serverAddress != address(0), "Server address cannot be zero address");

        bool exists = false;

        for(uint i = 0; i < _monitoring.length; i++) {
            if(address(_monitoring[i]) == address(0)) {
                continue;
            }

            (bool blocked,) = IAnhydriteMonitoring(_monitoring[i]).isServerBlocked(serverAddress);
            if (blocked) {
                exists = true;
                break;
            }
        }

        return exists;
    }

    // Vote on monitoring for the address
    function voteForServer(address serverAddress) external override {
        _voteForServer(msg.sender, serverAddress);
    }

    function _voteForServer(address voterAddress, address serverAddress) internal {
        (, address monitoringAddress) = _getMonitoring();
        require(voterAddress != address(0), "Invalid voter address");
        require(monitoringAddress != address(0), "Invalid monitoring address");
        require(_isServerMonitored(serverAddress), "This address is not monitored.");
        require(!_isServerBlocked(serverAddress), "This address is not blocked.");

        IAnhydriteMonitoring(monitoringAddress).voteForServer(voterAddress, serverAddress);
    }

    function _getMonitoring() internal view returns (uint256, address) {
        require(_monitoring.length > 0, "Monitoring list is empty");
        for (uint256 i = _monitoring.length; i > 0; i--) {
            if (_monitoring[i - 1] != address(0)) {
                return (i - 1, _monitoring[i - 1]);
            }
        }
        revert("No non-zero addresses found in the monitoring list");
    }

    // Get the number of votes on monitorings for the specified address
    function getTotalServerVotes(address serverAddress) external override view returns (uint256) {
        require(serverAddress != address(0), "Server address cannot be zero address");

        uint256 totalVotes = 0;

        for(uint i = 0; i < _monitoring.length; i++) {
            if(address(_monitoring[i]) == address(0)) {
                continue;
            }

            if(IAnhydriteMonitoring(_monitoring[i]).isServerExist(serverAddress)) {

                (bool blocked,) = IAnhydriteMonitoring(_monitoring[i]).isServerBlocked(serverAddress);

                if (blocked) {
                    return 0;
                }

                totalVotes += IAnhydriteMonitoring(_monitoring[i]).getServerVotes(serverAddress);
            }
        }

        return totalVotes;
    }

    function _addServerToMonitoring(uint256 gameId, address serverAddress) internal {
        (, address monitoringAddress) = _getMonitoring();
        require(monitoringAddress != address(0), "Invalid monitoring address");

        IAnhydriteMonitoring(monitoringAddress).addServerAddress(gameId, serverAddress);
    }
}

/*
* The Modules smart contract is intended for adding various modules to the global smart contract,
* so that game servers can add these modules to themselves.
*
* Enum available module types: Server, ItemShop, Voting, Lottery, Raffle, Game, Advertisement,
* AffiliateProgram, Event, RatingSystem, SocialFunctions, Auction, Charity
*/
interface IModules {
    function addModule(string memory moduleName, uint256 uintType, address contractAddress) external;
    function addGameServerModule(uint256 gameId, address contractAddress) external;
    function removeModule(string memory moduleName, uint256 uintType) external;
    function getModuleAddress(string memory name, uint256 uintType) external view returns (address);
    function isModuleExists(string memory name, uint256 uintType) external view returns (bool);
    function isGameModuleExists(uint256 gameId, uint256 uintType) external view returns (bool);
    function deployModuleOnServer(string memory factoryName, uint256 uintType, address ownerAddress) external returns (address);
    function deployServerContract(uint256 gameId) external returns (address);
}

abstract contract Modules is Monitorings, GameServerMetadata, IModules {

    enum ModuleType {
        Server, ItemShop, Voting, Lottery, Raffle, Game, Advertisement, AffiliateProgram, Event,
        RatingSystem, SocialFunctions,  Auction, Charity
    }
    
    struct Module {
        string moduleName; ModuleType moduleType; address moduleFactory;
    }

    Module[] private _moduleList;
    mapping(bytes32 => Module) private _modules;

    // Add a module
    function addModule(string memory moduleName, uint256 uintType, address contractAddress) external override onlyOwner  onlyProxyOwner(msg.sender) {
        _addModule(moduleName, uintType, contractAddress);
    }

    // Add a Game Server Module
    function addGameServerModule(uint256 gameId, address contractAddress) external override onlyOwner  onlyProxyOwner(msg.sender) {
        (string memory moduleName,) = _gameServerToString(gameId);
        uint256 uintType = uint256(ModuleType.Server);
        _addModule(moduleName, uintType, contractAddress);
    }

    function _addModule(string memory moduleName, uint256 uintType, address contractAddress) internal {
        bytes32 hash = _getModuleHash(moduleName, uintType);
        int256 indexToUpdate = -1;
        ModuleType moduleType = ModuleType(uintType);

        if (_modules[hash].moduleFactory == address(0)) {
            _modules[hash] = Module({
                moduleName: moduleName,
                moduleType: moduleType,
                moduleFactory: contractAddress
            });
        } else if (_modules[hash].moduleFactory != contractAddress) {
            _modules[hash].moduleFactory = contractAddress;
            // We find the index of the element to update
            for (uint256 i = 0; i < _moduleList.length; i++) {
                if (
                    keccak256(abi.encodePacked(_moduleList[i].moduleName)) ==
                    keccak256(abi.encodePacked(moduleName)) &&
                    _moduleList[i].moduleType == moduleType
                ) {
                    indexToUpdate = int256(i);
                    break;
                }
            }
        }

        if (indexToUpdate >= 0) {
            if (_moduleList[uint256(indexToUpdate)].moduleFactory != contractAddress) {
                // We update the existing module
                _moduleList[uint256(indexToUpdate)].moduleFactory = contractAddress;
            }
        } else {
            // We add a new module
            Module memory newModule = Module({
                moduleName: moduleName,
                moduleType: moduleType,
                moduleFactory: contractAddress
            });

            _moduleList.push(newModule);
        }
    }

    // Remove a module
    function removeModule(string memory moduleName, uint256 uintType) external override onlyOwner  onlyProxyOwner(msg.sender) {
        bytes32 hash = _getModuleHash(moduleName, uintType);
        _modules[hash] = Module("", ModuleType.Voting, address(0));
        for (uint i = 0; i < _moduleList.length; i++) {
            if (
            keccak256(abi.encodePacked(_moduleList[i].moduleName)) ==
            keccak256(abi.encodePacked(moduleName)) &&
            _moduleList[i].moduleType == ModuleType(uintType)
        ) {
                _moduleList[i] = _moduleList[_moduleList.length - 1];
                _moduleList.pop();
                return;
            }
        }
    }
    
    // Get Module Address
    function getModuleAddress(string memory name, uint256 uintType) external override view returns (address) {
        Module memory module = _getModule(name, uintType);
        return module.moduleFactory;
    }

    // Check if a module exists
    function isModuleExists(string memory name, uint256 uintType) external override view returns (bool) {
        bytes32 hash = _getModuleHash(name, uintType);
        return _isModuleExists(hash);
    }
    function isGameModuleExists(uint256 gameId, uint256 uintType) external override view returns (bool) {
        (string memory name,) = _gameServerToString(gameId);
        bytes32 hash = _getModuleHash(name, uintType);
        return _isModuleExists(hash);
    }

    function _isModuleExists(bytes32 hash) internal view returns (bool) {
        bool existModule = _modules[hash].moduleFactory != address(0);
        return existModule;
    }
    
    // Deploy the module on the server
    function deployModuleOnServer(string memory factoryName, uint256 uintType, address ownerAddress) external override onlyServerAutorised(msg.sender) returns (address) {
        return _deploy(uint256(GameServers.END_OF_LIST), factoryName, uintType, ownerAddress);
    }
    
    // Deploy the server smart contract
    function deployServerContract(uint256 gameId) external override returns (address) {
        uint256 uintType = uint256(ModuleType.Server);
        (string memory contractName,) = _gameServerToString(gameId);

        address minecraftServerAddress = _deploy(gameId, contractName, uintType, address(0));

        _mintTokenForServer(minecraftServerAddress);
        _addServerToMonitoring(gameId, minecraftServerAddress);

        return minecraftServerAddress;
    }

    function _mintTokenForServer(address serverAddress) internal virtual;

    function _deploy(uint256 gameId, string memory factoryName, uint256 uintType, address ownerAddress) internal returns (address) {
        bytes32 hash = _getModuleHash(factoryName, uintType);
        require(_isModuleExists(hash), "The module with this name and type does not exist");
        
        (string memory name, string memory symbol) = _gameServerToString(gameId);
        return IFactory(_getModule(factoryName, uintType).moduleFactory)
            .createModule(name, symbol, msg.sender, ownerAddress);
    }

    // Get a module
    function _getModule(string memory factoryName, uint256 uintType) internal view returns (Module memory) {
        bytes32 hash = _getModuleHash(factoryName, uintType);
        require(_isModuleExists(hash), "The module with this name and type does not exist");
        return _modules[hash];
    }

    // Get a hsah 
    function _getModuleHash(string memory name, uint256 uintType) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(name, uintType));
    }

    // This modifier checks if the address trying to deploy the module is an authorized server
    modifier onlyServerAutorised(address contractAddress) {
        require(_isServerMonitored(contractAddress), "This address is not monitored.");
        require(!_isServerBlocked(contractAddress), "This address is not blocked.");
        _;
    }

}

interface IFinances {
    function withdrawMoney(address payable recipient, uint256 amount) external;
    function transferERC20Tokens(address _tokenAddress, address _to, uint256 _amount) external;
    function transferERC721Token(address _tokenAddress, address _to, uint256 _tokenId) external;
}

abstract contract Finances is Modules, IFinances {

   // Function for transferring Ether
    function withdrawMoney(address payable recipient, uint256 amount) external override onlyOwner onlyProxyOwner(msg.sender) {
        require(address(this).balance >= amount, "Contract has insufficient balance");
        recipient.transfer(amount);
    }

    // Function for transferring ERC20 tokens
    function transferERC20Tokens(address _tokenAddress, address _to, uint256 _amount) external override onlyOwner onlyProxyOwner(msg.sender) {
        IERC20 token = IERC20(_tokenAddress);
        require(token.balanceOf(address(this)) >= _amount, "Not enough tokens on contract balance");
        token.transfer(_to, _amount);
    }

    // Function for transferring ERC721 tokens
    function transferERC721Token(address _tokenAddress, address _to, uint256 _tokenId) external override onlyOwner onlyProxyOwner(msg.sender) {
        ERC721 token = ERC721(_tokenAddress);
        require(token.ownerOf(_tokenId) == address(this), "The contract is not the owner of this token");
        token.safeTransferFrom(address(this), _to, _tokenId);
    }

}

interface IAnhydriteGlobal {
    function getVersion() external pure returns (uint256);
    function addPrice(string memory name, uint256 count) external;
    function getPrice(string memory name) external view returns (uint256);
    function getServerFromTokenId(uint256 tokenId) external view returns (address);
    function getTokenIdFromServer(address serverAddress) external view returns (uint256);
    function setTokenURI(uint256 tokenId, string memory newURI) external;
    function gerTokens(address to, uint256 amount) external returns (bool);
}

// 
contract AnhydriteGlobal is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Burnable, Finances, IAnhydriteGlobal {
    using Counters for Counters.Counter;

    uint256 constant private _version = 0;
    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => address) private _tokenContract;
    mapping(address => uint256) private _contractToken;
    mapping(string => uint256) private _prices;

    constructor(address proxyAddress) ERC721("Anhydrite Global", "ANHG") VotingOwner(proxyAddress) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, "ipfs://bafkreif66z2aeoer6lyujghufat3nxtautrza3ucemwcwgfiqpajjlcroy");
        _tokenContract[tokenId] = msg.sender;
    }

    // Special functions of the global contract.

    function getVersion() public override pure returns (uint256) {
        return _version;
    }

    // Add the cost of the service. This value is the number of Anhydrite tokens that will be burned when receiving this service.
    function addPrice(string memory name, uint256 count) public override onlyOwner  onlyProxyOwner(msg.sender) {
        _prices[name] = count;
    }

    // Get the cost of the service.
    function getPrice(string memory name) public override view returns (uint256) {
        return _prices[name];
    }
    
    // Get the server smart contract address that received the token with the specified tokenId during deployment.
    function getServerFromTokenId(uint256 tokenId) public override view returns (address) {
        return _tokenContract[tokenId];
    }
    
    // Get the tokenId of the token received by the server's smart contract during deployment during its deployment
    function getTokenIdFromServer(address serverAddress) public override view returns (uint256) {
        return _contractToken[serverAddress];
    }

    // Owner can change tokenURI of his own token
    function setTokenURI(uint256 tokenId, string memory newURI) public override onlyTokenOwner(tokenId) {
        _setTokenURI(tokenId, newURI);
    }

    function gerTokens(address recepient, uint256 amount) public override returns (bool) {
        require(address(_proxyContract) == msg.sender, "AnhydriteGlobal: unauthorized call");
        require(_isProxyOwner(recepient), "AnhydriteGlobal: recepient has no right to receive tokens");
        return _gerTokens(recepient, amount);
    }

    function _gerTokens(address to, uint256 amount) private returns (bool) {
        IERC20 token = _proxyContract.getToken();
        ANH_ERC20 anhydrite = ANH_ERC20(address(token));
        uint256 amountToSend = amount / (10 ** 18);
        if (token.balanceOf(address(this)) < amount) {
            anhydrite.xContract(amountToSend);
        }
        return token.transfer(to, amount);
    }

    // During the deployment of the server smart contract, a new token is minted and sent to the address of this contract
    function _mintTokenForServer(address serverAddress) internal override {
        require(_contractToken[serverAddress] == 0, "This contract has already used safeMint");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _tokenContract[tokenId] = serverAddress;
        _contractToken[serverAddress] = tokenId;

        _mint(serverAddress, tokenId);
        _setTokenURI(tokenId, tokenURI(0));
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Not token owner");
        _;
    }
}

interface IProxy {
    function getToken() external view returns (IERC20);
    function getTotalOwners() external view returns (uint256);
    function isBlacklisted(address account) external view returns (bool);
    function isProxyOwner(address tokenAddress) external view returns (bool);
}

interface IFactory {
    function createModule(string memory name, string memory symbol, address serverContractAddress, address ownerAddress) external returns (address);
}

interface IAnhydriteMonitoring {
    function addServerAddress(uint256 gameId, address serverAddress) external;
    function voteForServer(address voterAddress, address serverAddress) external;
    function isServerExist(address serverAddress) external view returns (bool);
    function isServerBlocked(address serverAddress) external view returns (bool, uint256);
    function getServerVotes(address serverAddress) external view returns (uint256);
}

interface ANH_ERC20 {
    function xContract(uint256 amount) external;
}