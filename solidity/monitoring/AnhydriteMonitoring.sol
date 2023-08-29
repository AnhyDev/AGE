// SPDX-License-Identifier: All rights reserved
// Anything related to the Anhydrite project, except for the OpenZeppelin library code, is protected.
// Copying, modifying, or using without proper attribution to the Anhydrite project and a link to https://anh.ink is strictly prohibited.

pragma solidity ^0.8.19;


import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @custom:security-contact support@anh.ink

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

        if (votestrue * 100 / _totalOwners >= 60) {
            _transferOwnership(_proposedOwner);
            _resetVote(_votesForNewOwner);
            emit VotingOwnerCompleted(msg.sender, _proposedOwner, vote, votestrue, votesfalse);
            _proposedOwner = address(0);
        } else if (votesfalse * 100 / _totalOwners > 40) {
            _resetVote(_votesForNewOwner);
            emit VotingOwnerCompleted(msg.sender, _proposedOwner, vote, votestrue, votesfalse);
            _proposedOwner = address(0);
        }
    }

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

    function _isProxyOwner(address tokenAddress) internal view returns (bool) {
        return _proxyContract.isProxyOwner(tokenAddress);
    }

    modifier onlyProxyOwner(address tokenAddress) {
        require(_isProxyOwner(tokenAddress), "VotingOwner: caller is not the proxy owner");
        _;
    }

    function renounceOwnership() public override onlyOwner onlyProxyOwner(msg.sender) {
        bool deact = false;
        require(deact, "VotingOwner: this function is deactivated");
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public override onlyOwner onlyProxyOwner(msg.sender) {
        bool deact = false;
        require(deact, "VotingOwner: this function is deactivated");
        require(newOwner != address(0), "VotingOwner: new owner is the zero address");
        _transferOwnership(newOwner);
    }
}

interface IFinances {
    function withdrawMoney(address payable recipient, uint256 amount) external;
    function transferERC20Tokens(address _tokenAddress, address _to, uint256 _amount) external;
    function transferERC721Token(address _tokenAddress, address _to, uint256 _tokenId) external;
}

abstract contract Finances is VotingOwner, IFinances {

   /// @notice Function for transferring Ether
    function withdrawMoney(address payable recipient, uint256 amount) external override onlyOwner onlyProxyOwner(msg.sender) {
        require(address(this).balance >= amount, "Contract has insufficient balance");
        recipient.transfer(amount);
    }

    /// @notice Function for transferring ERC20 tokens
    function transferERC20Tokens(address _tokenAddress, address _to, uint256 _amount) external override onlyOwner onlyProxyOwner(msg.sender) {
        IERC20 token = IERC20(_tokenAddress);
        require(token.balanceOf(address(this)) >= _amount, "Not enough tokens on contract balance");
        token.transfer(_to, _amount);
    }

    /// @notice Function for transferring ERC721 tokens
    function transferERC721Token(address _tokenAddress, address _to, uint256 _tokenId) external override onlyOwner onlyProxyOwner(msg.sender) {
        IERC721 token = IERC721(_tokenAddress);
        require(token.ownerOf(_tokenId) == address(this), "The contract is not the owner of this token");
        token.safeTransferFrom(address(this), _to, _tokenId);
    }

}

interface IAnhydriteMonitoring {
    function addServerAddress(uint256 gameId, address serverAddress) external;
    function removeServerAddress(address serverAddress) external;
    function voteForServer(address voterAddress, address serverAddress) external;
    function blockServer(address serverAddress) external;
    function getServerVotes(address serverAddress) external view returns (uint256);
    function getGameServerAddresses(uint256 gameId, uint256 startIndex, uint256 endIndex) external view returns (address[] memory);
    function isServerExist(address serverAddress) external view returns (bool);
    function isServerBlocked(address serverAddress) external view returns (bool, uint256);
    function getPriceVotes() external view returns (uint256);
    function stopContract() external;

    event Voted(address indexed voter, address indexed serverAddress, string game, string indexed symbol, uint256 amount);
    event ServerBlocked(address indexed serverAddress);
    event ContractStopped();
}

contract AnhydriteMonitoring is Finances, IAnhydriteMonitoring, IERC721Receiver {

    ERC20Burnable public votingToken;

    struct ServerInfo {
        uint256 gameId;
        uint256 votes;
        bool isBlocked;
    }

    mapping(address => ServerInfo) public serversInfo;
    mapping(address => bool) public servers;
    mapping(uint256 => address[]) public gameServers;
    mapping(address => uint256[]) public serverIndex;

    string private _priceName;
    bool public isContractStopped = false;

    constructor(address proxyAddress) VotingOwner(proxyAddress) {
        require(proxyAddress != address(0), "Invalid proxy address");
        votingToken = ERC20Burnable(address(_proxyContract.getToken()));

        _priceName = "The price of voting on monitoring";
    }

    function addServerAddress(uint256 gameId, address serverAddress) external override onlyGlobal notStopped {
        _addServerAddress(gameId, serverAddress);
    }

    function _addServerAddress(uint256 gameId, address serverAddress) internal {
        require(gameId < uint256(GameServers.END_OF_LIST), "Invalid game ID");
        require(serverAddress != address(0), "Invalid server address");
        require(!servers[serverAddress], "Server address already added");

        serverIndex[serverAddress] = [gameId, gameServers[gameId].length];
        gameServers[gameId].push(serverAddress);

        serversInfo[serverAddress] = ServerInfo({
            gameId: gameId,
            votes: 1,
            isBlocked: false
        });

        servers[serverAddress] = true;
    }

    function removeServerAddress(address serverAddress) external override onlyGlobal notStopped {
        require(servers[serverAddress], "Server address not found");

        gameServers[serverIndex[serverAddress][0]][serverIndex[serverAddress][1]] = address(0);
        delete servers[serverAddress];
        delete serversInfo[serverAddress];
        delete serverIndex[serverAddress];
    }

    function voteForServer(address voterAddress, address serverAddress) external override onlyGlobal notStopped {
        require(serverAddress != address(0), "Invalid server address");
        uint256 amount = _proxyContract.getPrice(_priceName);
        
        if(amount > 0) {
            uint256 senderBalance = votingToken.balanceOf(voterAddress);
            require(senderBalance >= amount, "Insufficient token balance");
            uint256 allowance = votingToken.allowance(voterAddress, address(this));
            require(allowance >= amount, "Token allowance too small");
            votingToken.burnFrom(voterAddress, amount);
        }

        if (!servers[serverAddress]) {
            _addServerAddress(serversInfo[serverAddress].gameId, serverAddress);
        } else {
            serversInfo[serverAddress].votes++;
        }
        (string memory gameName, string memory gameSymbol) = _proxyContract.gameServerToString(serversInfo[serverAddress].gameId);

        emit Voted(voterAddress, serverAddress, gameName, gameSymbol, serversInfo[serverAddress].votes);
    }

    function blockServer(address serverAddress) external override onlyOwner onlyProxyOwner(msg.sender) notStopped {
        require(servers[serverAddress], "Server address not found");
        require(!serversInfo[serverAddress].isBlocked, "Server is already blocked");
        serversInfo[serverAddress].isBlocked = true;
        emit ServerBlocked(serverAddress);
    }

    function getServerVotes(address serverAddress) external override view returns (uint256) {
        if(serversInfo[serverAddress].isBlocked) {
            return 0;
        }
        return serversInfo[serverAddress].votes;
    }

    function getGameServerAddresses(uint256 gameId, uint256 startIndex, uint256 endIndex) external override view returns (address[] memory) {
        require(gameId < uint256(GameServers.END_OF_LIST), "Invalid game ID");
        require(startIndex <= endIndex, "Invalid start or end index");

        address[] storage originalList = gameServers[gameId];
        uint256 length = originalList.length;

        if (length == 0) {
            return new address[](0);
        }

        require(startIndex < length, "Start index out of bounds.");

        // Обмежити endIndex максимально доступним індексом
        if (endIndex >= length) {
            endIndex = length - 1;
        }

        uint256 resultLength = endIndex - startIndex + 1;
        address[] memory resultList = new address[](resultLength);

        for (uint256 i = 0; i < resultLength; i++) {
            resultList[i] = originalList[startIndex + i];
        }

        return resultList;
    }

    function isServerExist(address serverAddress) external override view returns (bool) {
        return servers[serverAddress];
    }

    function isServerBlocked(address serverAddress) external override view returns (bool, uint256) {
        return (serversInfo[serverAddress].isBlocked, serversInfo[serverAddress].votes);
    }

    function getPriceVotes() external view returns (uint256) {
        return _proxyContract.getPrice(_priceName);
    }

    function stopContract() external onlyOwner {
        require(!isContractStopped, "Contract is already stopped.");
        isContractStopped = true;
        emit ContractStopped();
    }

    modifier onlyGlobal() {
        require(_proxyContract.getImplementation() == msg.sender, "This function is only available from a global smart contract.");
        _;
    }

    modifier notStopped() {
        require(!isContractStopped, "Contract is stopped.");
        _;
    }

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

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

interface IAnhydriteGlobal {
    function gameServerToString(uint256 gameId) external pure returns (string memory, string memory);
    function getNumberOfMonitorings() external view returns (uint256);
    function getPrice(string memory name) external view returns (uint256);
}

interface IProxy is IAnhydriteGlobal {
    function getTotalOwners() external view returns (uint256);
    function isBlacklisted(address account) external view returns (bool);
    function isProxyOwner(address tokenAddress) external view returns (bool);
    function getToken() external view returns (IERC20);
    function getImplementation() external view returns (address);
    function isStopped() external view returns (bool);
}