// SPDX-License-Identifier: All rights reserved
// Anything related to the Anhydrite project, except for the OpenZeppelin library code, is protected.
// Copying, modifying, or using without proper attribution to the Anhydrite project and a link to https://anh.ink is strictly prohibited.

pragma solidity ^0.8.19;

/// @custom:info Глобальний смарт контракт

interface IGameServerMetadata { 
    /* 01. */ function gameServerToString(uint256 gameId) external pure returns (string memory, string memory);
}

interface IVotingOwner {
    /* 02. */ function proposedVoteForOwner(address proposed) external;
    /* 03. */ function voteForNewOwner(bool vote) external;
    /* 04. */ function getActiveForVoteOwner() external view returns (bool, address);

    event VotingForOwner(address indexed voter, address votingSubject, bool vote);
    event VotingOwnerCompleted(address indexed voter, address votingSubject, bool vote, uint votesFor, uint votesAgainst);
}

interface IMonitorings {
    /* 05. */ function addMonitoring(address newAddress) external;
    /* 06. */ function getMonitoring() external view returns (uint256, address);
    /* 07. */ function getNumberOfMonitorings() external view returns (uint256);
    /* 08. */ function getMonitoringAddresses() external view returns (uint256[] memory, address[] memory);
    /* 09. */ function removeMonitoringAddress(address addressToRemove) external;
    /* 10. */ function isServerMonitored(address serverAddress) external view returns (bool);
    /* 11. */ function voteForServer(address serverAddress) external;
    /* 12. */ function getTotalServerVotes(address serverAddress) external view returns (uint256);
}

interface IModules {
    /* 13. */ function addModule(string memory moduleName, uint256 uintType, address contractAddress) external;
    /* 14. */ function addGameServerModule(uint256 gameId, address contractAddress) external;
    /* 15. */ function removeModule(string memory moduleName, uint256 uintType) external;
    /* 16. */ function getModuleAddress(string memory name, uint256 uintType) external view returns (address);
    /* 17. */ function isModuleExists(string memory name, uint256 uintType) external view returns (bool);
    /* 18. */ function isGameModuleExists(uint256 gameId, uint256 uintType) external view returns (bool);
    /* 19. */ function createAndHandleModule(string memory factoryName, uint256 uintType, address ownerAddress) external returns (address);
    /* 20. */ function deployServerContract(uint256 gameId) external returns (address);
}

interface IFinances {
    /* 21. */ function withdrawMoney(address payable recipient, uint256 amount) external;
    /* 22. */ function transferERC20Tokens(address _tokenAddress, address _to, uint256 _amount) external;
    /* 23. */ function transferERC721Token(address _tokenAddress, address _to, uint256 _tokenId) external;
}

interface IAnhydriteGlobal {
    /* 24. */ function getVersion() external pure returns (uint256);
    /* 25. */ function addPrice(string memory name, uint256 count) external;
    /* 26. */ function getPrice(string memory name) external view returns (uint256);
    /* 27. */ function getServerFromTokenId(uint256 tokenId) external view returns (address);
    /* 28. */ function getTokenIdFromServer(address serverAddress) external view returns (uint256);
    /* 29. */ function setTokenURI(uint256 tokenId, string memory newURI) external;
}



/// @custom:info смарт контракт моніторинга

interface IVotingOwner_ {
    /* 01. */ function proposedVoteForOwner(address proposed) external;
    /* 02. */ function voteForNewOwner(bool vote) external;
    /* 03. */ function getActiveForVoteOwner() external view returns (bool, address);

    event VotingForOwner(address indexed voter, address votingSubject, bool vote);
    event VotingOwnerCompleted(address indexed voter, address votingSubject, bool vote, uint votesFor, uint votesAgainst);
}

interface IAnhydriteMonitoring {
    /* 04. */ function addServerAddress(uint256 gameId, address serverAddress) external;
    /* 05. */ function removeServerAddress(address serverAddress) external;
    /* 06. */ function voteForServer(address voterAddress, address serverAddress) external;
    /* 07. */ function blockServer(address serverAddress) external;
    /* 08. */ function getServerVotes(address serverAddress) external view returns (uint256);
    /* 09. */ function getGameServerAddresses(uint256 gameId, uint256 startIndex, uint256 endIndex) external view returns (address[] memory);
    /* 10. */ function isServerExist(address serverAddress) external view returns (bool);
    /* 11. */ function isServerBlocked(address serverAddress) external view returns (bool, uint256);
    /* 12. */ function getPriceVotes() external view returns (uint256);
    /* 13. */ function stopContract() external;

    event Voted(address indexed voter, address indexed serverAddress, uint256 indexed game, uint256 amount);
    event ServerBlocked(address indexed serverAddress);
    event ContractStopped();
}

interface IFinances_ {
    /* 14. */ function withdrawMoney(address payable recipient, uint256 amount) external;
    /* 15. */ function transferERC20Tokens(address _tokenAddress, address _to, uint256 _amount) external;
    /* 16. */ function transferERC721Token(address _tokenAddress, address _to, uint256 _tokenId) external;
}



/// @custom:info Серверний смарт контракт Minecraft

interface INFTSales {
    /* 01. */ function setPriceNFT(uint256 payAmount) external;
    /* 02. */ function setPriceNFTWithTokens(address tokenAddress, uint256 payAmount) external;
    /* 03. */ function buyNFT() external payable;
    /* 04. */ function buyNFTWithTokens() external;
}

interface IModulesMC {
    /* 05. */ function deployModule(string memory name, uint256 moduleType) external;
    /* 06. */ function removeModule(string memory name, uint256 moduleType) external;
    /* 07. */ function getModuleAddress(string memory name, uint256 moduleId) external view returns (address);
    /* 08. */ function isModuleInstalled(string memory name, uint256 moduleType) external view returns (bool);
    
    event DeployModule(address indexed contractAddress, string moduleName, uint256 moduleId);
}

interface IFinances__ {
    /* 09. */ function withdrawMoney(address payable recipient, uint256 amount) external;
    /* 10. */ function transferERC20Tokens(address _tokenAddress, address _to, uint256 _amount) external;
    /* 11. */ function transferERC721Token(address _tokenAddress, address _to, uint256 _tokenId) external;
}

interface IServerContract {
    /* 12. */ function setServerDetails(bytes4 newServerIpAddress, uint16 newServerPort, string calldata newServerName, string calldata newServerAddress) external;
    /* 13. */ function setServerIpAddress(bytes4 newIpAddress) external;
    /* 14. */ function setServerIpAddress(string calldata ipString) external;
    /* 15. */ function getServerIpAddress() external view returns (bytes4);
    /* 16. */ function getIpAddressFromString(string calldata ipString) external pure returns (bytes4);
    /* 17. */ function setServerPort(uint16 newPort) external;
    /* 18. */ function getServerPort() external view returns (uint16);
    /* 19. */ function setServerName(string calldata newName) external;
    /* 20. */ function getServerName() external view returns (string memory);
    /* 21. */ function setServerAddress(string calldata newAddress) external;
    /* 22. */ function getServerAddress() external view returns (string memory);
}

interface IFactory {
    struct Deployed {
        address moduleAddress;
        address ownerAddress;
    }
    
    /* 23. */ function createModule(string memory name, string memory symbol, address serverContractAddress, address ownerAddress) external returns (address);
    /* 24. */ function getDeployedModules() external view returns (Deployed[] memory);
    /* 25. */ function getNumberOfDeployedModules() external view returns (uint256);
}
