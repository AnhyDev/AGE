// SPDX-License-Identifier: All rights reserved
// Anything related to the Anhydrite project, except for the OpenZeppelin library code, is protected.
// Copying, modifying, or using without proper attribution to the Anhydrite project and a link to https://anh.ink is strictly prohibited.

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


abstract contract NFTSales is ERC721Enumerable, Ownable {

    Price private _price;

    event NFTPurchased(address indexed purchaser);

    struct Price {
        address tokenAddress;
        uint256 amount;
    }

    function setPriceNFT(uint256 payAmount) external onlyOwner {
        _setPrice(address(0), payAmount);
    }

    function setPriceNFTWithTokens(address tokenAddress, uint256 payAmount) external onlyOwner {
       _setPrice(tokenAddress, payAmount);
    }

    function _setPrice(address tokenAddress, uint256 payAmounts) internal {
        _price = Price({
            tokenAddress: tokenAddress,
            amount: payAmounts
        });
    }

    function buyNFT() external payable {
        _buyNFT();
    }

    function buyNFTWithTokens() external {
        _buyNFT();
    }
  
    function _buyNFT() internal {
        require(totalSupply() > 0, "Token with ID 0 has already been minted");
        _buyService();
        _newMint(msg.sender, tokenURI(0));
    }
    
    function _buyService() internal {
        uint256 paymentAmount = _price.amount;
        address paymentToken = _price.tokenAddress;
        if(paymentToken == address(0)) {
            // If paying with ether
            require(msg.value == paymentAmount, "The amount of ether sent does not match the required amount.");
        } else {
            // If paying with tokens
            IERC20 token = IERC20(paymentToken);
            require(token.balanceOf(msg.sender) >= paymentAmount, "Your token balance is not enough.");
            require(token.allowance(msg.sender, address(this)) >= paymentAmount, "The contract does not permit the transfer of tokens on behalf of the user.");
            token.transferFrom(msg.sender, address(this), paymentAmount);
        }

        emit NFTPurchased(msg.sender);
    }

    function _newMint(address to, string memory uri) internal virtual;

}

interface IIModulesMC {
    function deployModule(string memory name, uint256 moduleType) external;
    function removeModule(string memory name, uint256 moduleType) external;
    function getModuleAddress(string memory name, uint256 moduleId) external view returns (address);
    function isModuleInstalled(string memory name, uint256 moduleType) external view returns (bool);

    event DeployModule(address indexed contractAddress, string moduleName, uint256 moduleId);
}

abstract contract IModulesMC is Ownable, IIModulesMC {
    IProxy internal immutable _proxyContract;

    enum ModuleType {
        Server, Voting, Lottery, Raffle, Game, ItemShop, Advertisement, AffiliateProgram, Event,
        RatingSystem, SocialFunctions, Auction, Charity
    }
    
    struct Module {
        string moduleName; ModuleType moduleType; address contractAddress;
    }

    Module[] private _moduleList;
    mapping(bytes32 => Module) private _modules;

    constructor(address proxyContractAddress) {
        _proxyContract = IProxy(proxyContractAddress);
    }


    // Deploy a module
    function deployModule(string memory name, uint256 moduleId) external override onlyOwner {
        address factory = _proxyContract.getModuleAddress(name, moduleId);
        require(factory != address(0), "Invalid module address");
        ModuleType moduleType = ModuleType(moduleId);
        bytes32 hash = _getModuleHash(name, moduleType);
        require(!_isModuleInstalled(name, hash), "Module already installed");
        address contractAddress = _proxyContract.createAndHandleModule(name, moduleId, msg.sender);

        Module memory module = Module({
            moduleName: name,
            moduleType: moduleType,
            contractAddress: contractAddress
        });

        _modules[hash] = module;
        _moduleList.push(module);
        
        emit DeployModule(contractAddress, name, moduleId);
    }

    // Remove a module
    function removeModule(string memory moduleName, uint256 moduleId) external override  onlyOwner {
        ModuleType moduleType = ModuleType(moduleId);
        bytes32 hash = _getModuleHash(moduleName, moduleType);
        _modules[hash] = Module("", ModuleType.Voting, address(0));
        for (uint i = 0; i < _moduleList.length; i++) {
            if (
            keccak256(abi.encodePacked(_moduleList[i].moduleName)) ==
            keccak256(abi.encodePacked(moduleName)) &&
            _moduleList[i].moduleType == moduleType
        ) {
                _moduleList[i] = _moduleList[_moduleList.length - 1];
                _moduleList.pop();
                return;
            }
        }
    }
    
    // Get a module
    function getModuleAddress(string memory name, uint256 moduleId) external override view returns (address) {
        return _getModuleAddress(name, moduleId);
    }
    function _getModuleAddress(string memory name, uint256 moduleId) internal view returns (address) {
        bytes32 hash = _getModuleHash(name, ModuleType(moduleId));
        Module memory module = _modules[hash];
        return module.contractAddress;
    }

    // Check if a module Installed
    function isModuleInstalled(string memory name, uint256 moduleId) external override view returns (bool) {
        bytes32 hash = _getModuleHash(name, ModuleType(moduleId));
        return _isModuleInstalled(name, hash);
    }
    function _isModuleInstalled(string memory name, bytes32 hash) internal view returns (bool) {
        bool existModule = keccak256(abi.encodePacked(_modules[hash].moduleName)) == keccak256(abi.encodePacked(name));
        return existModule;
    }

    // Get a hsah 
    function _getModuleHash(string memory name, ModuleType moduleType) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(name, uint256(moduleType)));
    }

}

interface IFinances {
    function withdrawMoney(address payable recipient, uint256 amount) external;
    function transferERC20Tokens(address _tokenAddress, address _to, uint256 _amount) external;
    function transferERC721Token(address _tokenAddress, address _to, uint256 _tokenId) external;
}

abstract contract Finances is Ownable, IFinances {

   /// @notice Function for transferring Ether
    function withdrawMoney(address payable recipient, uint256 amount) external override onlyOwner {
        require(address(this).balance >= amount, "Contract has insufficient balance");
        recipient.transfer(amount);
    }

    /// @notice Function for transferring ERC20 tokens
    function transferERC20Tokens(address _tokenAddress, address _to, uint256 _amount) external override onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        require(token.balanceOf(address(this)) >= _amount, "Not enough tokens on contract balance");
        token.transfer(_to, _amount);
    }

    /// @notice Function for transferring ERC721 tokens
    function transferERC721Token(address _tokenAddress, address _to, uint256 _tokenId) external override onlyOwner {
        ERC721 token = ERC721(_tokenAddress);
        require(token.ownerOf(_tokenId) == address(this), "The contract is not the owner of this token");
        token.safeTransferFrom(address(this), _to, _tokenId);
    }

}


abstract contract Cashback is Ownable {

    struct StructCashback {
        string name;
        address contractCashbackAddress;
        uint256 price;
    }

    mapping(bytes32 => StructCashback) internal cashback;
    bytes32[] internal cashbackArreys;

    function upsertCashback(string memory name, address contractCashbackAddress, uint256 price) external onlyOwner {
        require(_supportsICashback(contractCashbackAddress), "Cashback: Address does not comply with ICashback interface");
        bytes32 key = keccak256(abi.encodePacked(name));

        if (!isCashbackExists(key)) {
            cashbackArreys.push(key);
        }
        
        StructCashback storage cb = cashback[key];
        cb.name = name;
        cb.contractCashbackAddress = contractCashbackAddress;
        cb.price = price;
    }

    function deleteCashback(bytes32 key) external onlyOwner {
        require(isCashbackExists(key), "Cashback: Key does not exist.");
        
        delete cashback[key];
        
        for (uint256 i = 0; i < cashbackArreys.length; i++) {
            if (cashbackArreys[i] == key) {
                cashbackArreys[i] = cashbackArreys[cashbackArreys.length - 1];
                cashbackArreys.pop();
                break;
            }
        }
    }

    function isCashbackExists(bytes32 source) internal view returns (bool) {
        return cashback[source].contractCashbackAddress != address(0);
    }

    function getCashback(string memory name) external view returns (address, uint256) {
        return _getCashback(keccak256(abi.encodePacked(name)));
    }

    function getCashback(bytes32 source) external view returns (address, uint256) {
        return _getCashback(source);
    }

    function _getCashback(bytes32 source) internal view returns (address, uint256) {
        return (cashback[source].contractCashbackAddress, cashback[source].price);
    }

    function getAllCashbacks() external view returns (StructCashback[] memory) {
        uint256 length = cashbackArreys.length;
        StructCashback[] memory cashbacksList = new StructCashback[](length);

        for (uint256 i = 0; i < length; i++) {
            bytes32 key = cashbackArreys[i];
            cashbacksList[i] = cashback[key];
        }

        return cashbacksList;
    }

    function _supportsICashback(address contractAddress) internal view returns (bool) {
        return IERC165(contractAddress).supportsInterface(type(ICashback).interfaceId);
    }
}
interface ICashback {
    function issueTokens(address _recipient, bytes32 source) external;
    function isAddressApproved(address module) external view returns (bool);
    function toggleAddressApproval(address address_) external;
}


interface IServerContract {
    function setServerDetails(bytes4 newServerIpAddress, uint16 newServerPort, string calldata newServerName, string calldata newServerAddress) external;
    function setServerIpAddress(bytes4 newIpAddress) external;
    function setServerIpAddress(string calldata ipString) external;
    function getServerIpAddress() external view returns (bytes4);
    function getIpAddressFromString(string calldata ipString) external pure returns (bytes4);
    function setServerPort(uint16 newPort) external;
    function getServerPort() external view returns (uint16);
    function setServerName(string calldata newName) external;
    function getServerName() external view returns (string memory);
    function setServerAddress(string calldata newAddress) external;
    function getServerAddress() external view returns (string memory);
}

/// @custom:security-contact support@anh.ink
contract AGEMinecraftServer is ERC721, ERC721URIStorage, ERC721Burnable, IERC721Receiver, IModulesMC, NFTSales, Finances, IServerContract {
    using Counters for Counters.Counter;
    

    Counters.Counter internal _tokenIdCounter;
    bytes4 internal _serverIpAddress;
    uint16 internal _serverPort;
    string internal _serverName;
    string internal _serverAddress;
    Module[] internal _moduleList;
    mapping(bytes32 => Module) internal _modules;

    IERC20 public _tokenServer;

    constructor(address proxyContractAddress,
     address creator, 
     string memory name, 
     string memory symbol) 
     ERC721(name, symbol) IModulesMC(proxyContractAddress) {
        _newMint(creator, "ipfs://bafkreiahrn7kxg244pnzm5cv5y7oyja54tyn2f3ao3b62tcxqv44hlj4ru");
    }

    receive() external payable { }
    fallback() external payable { }

    function _newMint(address to, string memory uri) internal override {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    /// @custom:info The following functions are overrides IServerContract.

    function setServerDetails(
        bytes4 newServerIpAddress, uint16 newServerPort, string calldata newServerName, string calldata newServerAddress) external override onlyOwner {
            _setServerDetails(newServerIpAddress, newServerPort, newServerName, newServerAddress);
    }

    function _setServerDetails(
        bytes4 newServerIpAddress, uint16 newServerPort, string calldata newServerName, string calldata newServerAddress) internal {
        require(
            !(!_isValidIPv4(newServerIpAddress) && newServerPort == 0 && 
              keccak256(abi.encodePacked(newServerName)) == keccak256(abi.encodePacked("")) && 
              keccak256(abi.encodePacked(newServerAddress)) == keccak256(abi.encodePacked(""))),
            "All parameters cannot be zero or empty"
        );

        if (_isValidIPv4(newServerIpAddress)) {
            _serverIpAddress = newServerIpAddress;
        }

        if (newServerPort != 0) {
            _serverPort = newServerPort;
        }

        if (keccak256(abi.encodePacked(newServerName)) != keccak256(abi.encodePacked(""))) {
            _serverName = newServerName;
        }

        if (keccak256(abi.encodePacked(newServerAddress)) != keccak256(abi.encodePacked(""))) {
            _serverAddress = newServerAddress;
        }
    }

    function setServerIpAddress(bytes4 newIpAddress) external override onlyOwner {
        require(_isValidIPv4(newIpAddress), "Invalid IP address");
        _serverIpAddress = newIpAddress;
    }
    
    function setServerIpAddress(string calldata ipString) external override onlyOwner {
        bytes4 newIpAddress = _getIpAddressFromString(ipString);
        require(_isValidIPv4(newIpAddress), "Invalid IP address");

        _serverIpAddress = newIpAddress;
    }

    function getServerIpAddress() external override view returns (bytes4) {
        return _serverIpAddress;
    }
    
    function getIpAddressFromString(string calldata ipString) external override pure returns (bytes4) {
        return _getIpAddressFromString(ipString);
    }
    
    function _getIpAddressFromString(string calldata ipString) internal pure returns (bytes4) {
        require(bytes(ipString).length >= 7 && bytes(ipString).length <= 15, "Invalid IP string length");
        
        bytes memory ipBytes = bytes(ipString);
        uint8 dotCount = 0;
        bytes4 ipBytesTemp;
        uint8 currentOctet = 0;

        for (uint256 i = 0; i < ipBytes.length; i++) {
            require((ipBytes[i] >= "0" && ipBytes[i] <= "9") || ipBytes[i] == ".", "Invalid IP character");

            if (ipBytes[i] == ".") {
                require(currentOctet <= 255, "Invalid IP octet value");
                ipBytesTemp |= bytes4(bytes1(currentOctet & 0xFF)) >> (dotCount * 8);
                currentOctet = 0;
                dotCount++;
            } else {
                currentOctet = currentOctet * 10 + uint8(ipBytes[i]) - 48;
            }
        }

        require(dotCount == 3, "IP should have exactly 3 dots");
        require(currentOctet <= 255, "Invalid IP octet value");
        ipBytesTemp |= bytes4(bytes1(currentOctet & 0xFF));
        
        return ipBytesTemp;
    }

    function _isValidIPv4(bytes4 ip) internal pure returns (bool) {
        if (ip == bytes4(0)) {
            return false; // 0.0.0.0 is not valid
        }

        uint8 a = uint8(ip[0]);
        uint8 b = uint8(ip[1]);

        // Check for private IP ranges
        if (a == 10) {
            return false; // 10.0.0.0/8
        }
        if (a == 172 && (b >= 16 && b <= 31)) {
            return false; // 172.16.0.0/12
        }
        if (a == 192 && b == 168) {
            return false; // 192.168.0.0/16
        }

        return true; 
    }

    function setServerPort(uint16 newPort) external override onlyOwner {
        _serverPort = newPort;
    }

    function getServerPort() external override view returns (uint16) {
        return _serverPort;
    }

    function setServerName(string calldata newName) external override onlyOwner {
        _serverName = newName;
    }

    function getServerName() external view override returns (string memory) {
        return _serverName;
    }

    function setServerAddress(string calldata newAddress) external override onlyOwner {
        _serverAddress = newAddress;
    }

    function getServerAddress() external view override returns (string memory) {
        return _serverAddress;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override (ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override (ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override (ERC721, ERC721Enumerable, ERC721URIStorage) returns (bool) {
        return  interfaceId == type(IERC721Receiver).interfaceId ||
                interfaceId == type(IServerContract).interfaceId ||
                super.supportsInterface(interfaceId);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

}

// Anhydrite Minecraft server contract, ANHMC

interface IFactory {

    struct Deployed {
        address moduleAddress;
        address ownerAddress;
    }

    function deployModule(string memory name, string memory symbol, address serverContractAddress, address ownerAddress) external returns (address);
    function getDeployedModules() external view returns (Deployed[] memory);
    function getNumberOfDeployedModules() external view returns (uint256);
}

contract FactoryContract is IFactory {

    Deployed[] private _deployedModules;
    mapping(address => bool) public isDeploy;
    address private immutable _proxyAddress;

    event ModuleCreated(address indexed moduleAddress, address indexed owner);

    constructor(address proxyAddress) {
        _proxyAddress = proxyAddress;
    }

    function deployModule(string memory name, string memory symbol, address ownerAddress, address) external override onlyAllowed(ownerAddress) returns (address) {
        // unusedAddress not used but retained for compatibility with the standard
        AGEMinecraftServer newModule = new AGEMinecraftServer(_proxyAddress, ownerAddress, name, symbol);
        newModule.transferOwnership(ownerAddress);
        
        Deployed memory newDeployedModule = Deployed({
            moduleAddress: address(newModule),
            ownerAddress: ownerAddress
        });
        isDeploy[ownerAddress] = true;

        _deployedModules.push(newDeployedModule);
        emit ModuleCreated(address(newModule), msg.sender);
        
        return address(newModule);
    }

    function getDeployedModules() external override view returns (Deployed[] memory) {
        return _deployedModules;
    }

    function getNumberOfDeployedModules() external override view returns (uint256) {
        return _deployedModules.length;
    }

    modifier onlyAllowed(address ownerAddress) {
        IProxy proxy = IProxy(_proxyAddress);
        require(msg.sender == proxy.getImplementation(), "Caller is not the implementation");
        require(!proxy.isStopped(), "Deploying is stopped");
        require(!isDeploy[ownerAddress], "This address has already deployed this module");
        _;
    }

    receive() external payable {
        Address.sendValue(payable(IProxy(_proxyAddress).getImplementation()), msg.value);
    }
}

interface IAnhydriteGlobal {
    function getVersion() external pure returns (uint256);
    function getPrice(string memory name) external view returns (uint256);
    function getModuleAddress(string memory name, uint256 moduleType) external view returns (address);
    function isModuleExists(string memory name, uint256 moduleId) external view returns (bool);
    function createAndHandleModule(string memory factoryName, uint256 moduleId, address ownerAddress) external returns (address);
}

interface IProxy is IAnhydriteGlobal {
    function getToken() external view returns (IERC20);
    function getImplementation() external view returns (address);
    function isStopped() external view returns (bool);
}