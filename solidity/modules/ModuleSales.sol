// SPDX-License-Identifier: All rights reserved
// Anything related to the Anhydrite project, except for the OpenZeppelin library code, is protected.
// Copying, modifying, or using without proper attribution to the Anhydrite project and a link to https://anh.ink is strictly prohibited.

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


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

abstract contract ModuleCashback is ERC20, Ownable {
    uint256 internal _cashback;

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        _cashback = 10 * 10 ** decimals();
        _mint(owner(), 1000 * 10 ** decimals());
    }

    function getCashback() external view returns (uint256) {
        return _cashback;
    }

    function setCashback(uint256 cashback) external onlyOwner {
        _cashback = cashback;
    }

}

interface IServicesSales {
    function addServicePermanent(string memory moduleName, uint256 payAmount) external;
    function addServicePermanentWithTokens(string memory moduleName, address payAddress, uint256 payAmount) external;
    function addServiceOneTime(string memory moduleName, uint256 payAmount) external;
    function addServiceOneTimeWithTokens(string memory moduleName, address payAddress, uint256 payAmount) external;
    function addServiceTimeBased(string memory moduleName, uint256 payAmount, uint256 duration) external;
    function addServiceTimeBasedWithTokens(string memory moduleName, address payAddress, uint256 payAmount, uint256 duration) external;
    function addServiceNFT(string memory moduleName, uint256 payAmount, address tokenAddress, uint256 number) external;
    function addServiceNFTWithTokens(string memory moduleName, address payAddress, uint256 payAmount, address tokenAddress, uint256 number) external;
    function addServiceERC20(string memory moduleName, uint256 payAmount, address tokenAddress, uint256 number) external;
    function addServiceERC20WithTokens(string memory moduleName, address payAddress, uint256 payAmount, address tokenAddress, uint256 number) external;
    function removeServiceFromList(uint256 serviceId, string memory serviceName) external;
    function buyService(uint256 serviceId, string memory serviceName) external payable;
    function buyServiceWithTokens(uint256 serviceId, string memory serviceName) external;
    function buyListedNFT(string memory serviceName) external payable;
    function buyListedNFTWithTokens(string memory serviceName) external;
    function buyListedERC20(string memory serviceName) external payable;
    function buyListedERC20WithTokens(string memory serviceName) external;
}

// Module name => Anhydrite server module: ModuleSales
contract ModuleSales is IServicesSales, Finances, ModuleCashback {
    address internal _serverContract;

    enum ServiceType {
        Permanent,
        OneTime,
        TimeBased,
        NFT,
        ERC20,
        Sentinel //This is the sentinel value
    }

    struct Price {
        address tokenAddress;
        uint256 amount;
    }

    struct Service {
        bytes32 hash;
        string name;
        Price price;
        uint256 timestamp;
        uint256 duration;
        address tokenAddress;
        uint256 number;
    }
    mapping(uint256 => Service[]) public services;
    mapping(address => mapping(uint256 => Service[])) public userPurchasedServices;

    event ServicePurchased(address indexed purchaser, ServiceType serviceType);

    constructor(address serverContract_, string memory name_, string memory symbol_)
        ModuleCashback(string(abi.encodePacked(name_, "ModuleSales")), string(abi.encodePacked(symbol_, "MS"))) {
        _serverContract = serverContract_;
    }

    /// @custom:info Special functions of the server contract.

    function addServicePermanent(string memory moduleName, uint256 payAmount) public onlyOwner {
        uint256 serviceId = uint(ServiceType.Permanent);
        _addService(serviceId, moduleName, address(0), payAmount, 0, address(0), 0);
    }

    function addServicePermanentWithTokens(string memory moduleName, address payAddress, uint256 payAmount) public onlyOwner {
        uint256 serviceId = uint(ServiceType.Permanent);
        _addService(serviceId, moduleName, payAddress, payAmount, 0, address(0), 0);
    }

    function addServiceOneTime(string memory moduleName, uint256 payAmount) public onlyOwner {
        uint256 serviceId = uint(ServiceType.OneTime);
        _addService(serviceId, moduleName, address(0), payAmount, 0, address(0), 0);
    }

    function addServiceOneTimeWithTokens(string memory moduleName, address payAddress, uint256 payAmount) public onlyOwner {
        uint256 serviceId = uint(ServiceType.OneTime);
        _addService(serviceId, moduleName, payAddress, payAmount, 0, address(0), 0);
    }

    function addServiceTimeBased(string memory moduleName, uint256 payAmount, uint256 duration) public onlyOwner {
        uint256 serviceId = uint(ServiceType.TimeBased);
        _addService(serviceId, moduleName, address(0), payAmount, duration, address(0), 0);
    }

    function addServiceTimeBasedWithTokens(string memory moduleName, address payAddress, uint256 payAmount, uint256 duration) public onlyOwner {
        uint256 serviceId = uint(ServiceType.TimeBased);
        _addService(serviceId, moduleName, payAddress, payAmount, duration, address(0), 0);
    }

    function addServiceNFT(string memory moduleName, uint256 payAmount, address tokenAddress, uint256 number) public onlyOwner {
        uint256 serviceId = uint(ServiceType.NFT);
        _addService(serviceId, moduleName, address(0), payAmount, 0, tokenAddress, number);
    }

    function addServiceNFTWithTokens(string memory moduleName, address payAddress, uint256 payAmount, address tokenAddress, uint256 number) public onlyOwner {
        uint256 serviceId = uint(ServiceType.NFT);
        _addService(serviceId, moduleName, payAddress, payAmount, 0, tokenAddress, number);
    }

    function addServiceERC20(string memory moduleName, uint256 payAmount, address tokenAddress, uint256 number) public onlyOwner {
        uint256 serviceId = uint(ServiceType.ERC20);
        _addService(serviceId, moduleName, address(0), payAmount, 0, tokenAddress, number);
    }

    function addServiceERC20WithTokens(string memory moduleName, address payAddress, uint256 payAmount, address tokenAddress, uint256 number) public onlyOwner {
        uint256 serviceId = uint(ServiceType.ERC20);
        _addService(serviceId, moduleName, payAddress, payAmount, 0, tokenAddress, number);
    }

    function removeServiceFromList(uint256 serviceId, string memory serviceName) public onlyOwner {
        _removeServiceFromList(serviceId, serviceName);
    }

    function buyService(uint256 serviceId, string memory serviceName) public payable validServiceId(serviceId) {
        Service memory service = _getServiceByNameAndType(serviceId, serviceName);
        require(service.price.tokenAddress == address(0), "This service is sold for tokens");
        _buyService(service, serviceId);
    }

    function buyServiceWithTokens(uint256 serviceId, string memory serviceName) public validServiceId(serviceId) {
        Service memory service = _getServiceByNameAndType(serviceId, serviceName);
        _buyService(service, serviceId);
    }
    
    function buyListedNFT(string memory serviceName) public payable {
        _buyListedNFT(serviceName);
    }
    
    function buyListedNFTWithTokens(string memory serviceName) public {
        _buyListedNFT(serviceName);
    }
    
    function buyListedERC20(string memory serviceName) public payable {
        _buyListedERC20(serviceName);
    }

    function buyListedERC20WithTokens(string memory serviceName) public {
        _buyListedERC20(serviceName);
    }

    function getServiceByNameAndType(uint256 serviceId, string memory serviceName) public view returns (Service memory) {
        return _getServiceByNameAndType(serviceId, serviceName);
    }

    function _buyListedERC20(string memory serviceName) internal {
        uint256 serviceId = uint(ServiceType.ERC20);
        Service memory service = _getServiceByNameAndType(serviceId, serviceName);
        uint256 amount = service.number;
        IERC20 erc20Token = IERC20(service.tokenAddress);
        require(erc20Token.balanceOf(address(this)) >= amount, "Not enough tokens in contract balance");

        _buyService(service, serviceId);
        erc20Token.transfer(msg.sender, amount);
    }
    
    function _buyListedNFT(string memory serviceName) private {
        uint256 serviceId = uint(ServiceType.NFT);
        Service memory service = _getServiceByNameAndType(serviceId, serviceName);
        uint256 idNft = service.number;
        ERC721 token = _listedNFT(idNft, service);

        _buyService(service, serviceId);
        token.safeTransferFrom(address(this), msg.sender, idNft);
        
        _removeServiceFromList(serviceId, serviceName);
    }

    function _getServiceByNameAndType(uint256 serviceId, string memory serviceName)internal view returns (Service memory) {
        bytes32 serviceNameHash = keccak256(abi.encodePacked(serviceName));
        Service[] memory serviceArray = services[serviceId];
        for(uint i = 0; i < serviceArray.length; i++) {
            if(serviceArray[i].hash == serviceNameHash) {
                return serviceArray[i];
            }
        }
        revert("Service not found");
    }

    function _purchaseService(address sender, Service memory service, uint256 serviceId) private {
        userPurchasedServices[sender][serviceId].push(service);

        _mint(msg.sender, _cashback);
        emit ServicePurchased(sender, ServiceType(serviceId));
    }
    
    function _buyService(Service memory service, uint256 serviceId) internal validServiceId(serviceId) {
        uint256 paymentAmount = service.price.amount;
        address paymentToken = service.price.tokenAddress;
        if(paymentToken == address(0)) {
            // If paying with ether
            require(msg.value == paymentAmount, "The amount of ether sent does not match the required amount.");
        } else {
            // If paying with tokens
            IERC20 token = IERC20(paymentToken);
            require(token.balanceOf(msg.sender) >= paymentAmount, "Your token balance is not enough.");
            require(token.allowance(msg.sender, _serverContract) >= paymentAmount, "The contract does not permit the transfer of tokens on behalf of the user.");
            token.transferFrom(msg.sender, _serverContract, paymentAmount);
        }

        _purchaseService(msg.sender, service, serviceId);
    }

    function _removeServiceFromList(uint256 serviceId, string memory serviceName) private {     
        // Find the service index and remove it
        for (uint256 i = 0; i < services[serviceId].length; i++) {
            if (keccak256(abi.encodePacked(services[serviceId][i].name)) == keccak256(abi.encodePacked(serviceName))) {
                require(i < services[serviceId].length, "Index out of bounds");

                // Move the last element to the spot at index
                services[serviceId][i] = services[serviceId][services[serviceId].length - 1];
        
                // Remove the last element
                services[serviceId].pop();
                break;
            }
        }
    }
    
    function _listedNFT(uint256 idNft, Service memory service) private view returns (ERC721 returnedToken) {
        address tokenAddress = service.tokenAddress;
        require(service.price.tokenAddress != address(0), "This service is sold for tokens");
        require(tokenAddress != address(0), "This service has no NFTs for sale");
        require(service.number == idNft, "NFT with such id is not for sale");
        ERC721 tokenInstance = ERC721(tokenAddress);
        require(tokenInstance.ownerOf(idNft) == address(this), "Token is not owned by this contract");
        return tokenInstance;
    }

    function _addService(uint256 serviceId, string memory moduleName, address payAddress, uint256 payAmount, uint256 duration,
        address tokenAddress, uint256 number) private {
        services[serviceId].push(Service({
            hash: keccak256(abi.encodePacked(moduleName)),
            name: moduleName,
            price: Price({
                tokenAddress: payAddress,
                amount: payAmount
            }),
            timestamp: block.timestamp,
            duration: duration,
            tokenAddress: tokenAddress,
            number: number
        }));
    }
    
    modifier validServiceId(uint256 serviceId) {
        require(serviceId < uint(ServiceType.Sentinel), "Invalid service type");
        _;
    }

    receive() external payable {
        Address.sendValue(payable(address(_serverContract)), msg.value);
    }

}

contract FactoryContract {

    struct Deployed {
        address moduleAddress;
        address serverContract;
    }

    Deployed[] public deployedModules;
    mapping(address => bool) public isDeploy;
    address public immutable proxyAddress;

    event ModuleCreated(address indexed moduleAddress, address indexed owner);

    constructor(address _proxyAddress) {
        proxyAddress = _proxyAddress;
    }

    function createModule(string memory name, string memory symbol, address serverContractAddress, address ownerAddress) public onlyAllowed(serverContractAddress) returns (address) {
        ModuleSales newModule = new ModuleSales(serverContractAddress, name, symbol);
        if (ownerAddress != address(0)) {
            newModule.transferOwnership(ownerAddress);
        }
        
        Deployed memory newDeployedModule = Deployed({
            moduleAddress: address(newModule),
            serverContract: serverContractAddress
        });
        isDeploy[serverContractAddress] = true;

        deployedModules.push(newDeployedModule);
        emit ModuleCreated(address(newModule), msg.sender);
        
        return address(newModule);
    }

    function getDeployedModules() public view returns (Deployed[] memory) {
        return deployedModules;
    }

    function getNumberOfDeployedModules() public view returns (uint256) {
        return deployedModules.length;
    }

    modifier onlyAllowed(address serverContractAddress) {
        IProxy proxy = IProxy(proxyAddress);
        require(msg.sender == proxy.getImplementation(), "Caller is not the implementation");
        require(!proxy.isStopped(), "Deploying is stopped");
        require(!isDeploy[serverContractAddress], "This server has already deployed this module");
        _;
    }

    receive() external payable {
        Address.sendValue(payable(IProxy(proxyAddress).getImplementation()), msg.value);
    }
}


interface IAnhydriteGlobal {
    function getPrice(string memory name) external view returns (uint256);
}

interface IProxy  {
    function getImplementation() external view returns (address);
    function isStopped() external view returns (bool);
}