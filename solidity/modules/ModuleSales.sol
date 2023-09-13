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

/*
 * IANHReceiver Interface:
 * - Purpose: To handle the receiving of ERC-20 tokens from another smart contract.
 * - Key Method: 
 *   - `onERC20Received`: This is called when tokens are transferred to a smart contract implementing this interface.
 *                        It allows for custom logic upon receiving tokens.
 */

// Interface for contracts that are capable of receiving ERC20 (ANH) tokens.
interface IERC20Receiver {
    // Function that is triggered when ERC20 (ANH) tokens are received.
    function onERC20Received(address _from, address _who, uint256 _amount) external returns (bytes4);

    // An event to track from which address the tokens were transferred, who transferred, to which address and the number of tokens
    event ChallengeIERC20Receiver(address indexed from, address indexed who, address indexed token, uint256 amount);
}

/*
 * ERC20Receiver Contract:
 * - Inherits From: IERC20Receiver, ERC20
 * - Purpose: To handle incoming ERC-20 tokens and trigger custom logic upon receipt.
 * - Special Features:
 *   - Verifies the compliance of receiving contracts with the IERC20Receiver interface.
 *   - Uses the ERC1820 Registry to identify contracts that implement the IERC20Receiver interface.
 *   - Safely calls `onERC20Received` on the receiving contract and logs any exceptions.
 *   - Extends the standard ERC20 `_afterTokenTransfer` function to incorporate custom logic.
 * 
 * - Key Methods:
 *   - `_onERC20Received`: Internal function to verify and trigger `onERC20Received` on receiving contracts.
 *   - `_afterTokenTransfer`: Overridden from ERC20 to add additional behavior upon token transfer.
 *   - `onERC20Received`: Implements the IERC20Receiver interface, allowing the contract to handle incoming tokens.
 * 
 * - Events:
 *   - TokensReceivedProcessed: Logs successful processing of incoming tokens by receiving contracts.
 *   - ExceptionInfo: Logs exceptions during the execution of `onERC20Received` on receiving contracts.
 *   - ReturnOfThisToken: Logs when tokens are received from this contract itself.
 * 
 */
abstract contract ERC20Receiver is IERC20Receiver, ERC20 {

    // The magic identifier for the ability in the external contract to cancel the token acquisition transaction
    bytes4 internal ERC20ReceivedMagic;

    IERC1820Registry constant internal erc1820Registry = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    // Confirm receipt and handling of Anhydrite tokens by external IERC20Receiver contract
    event TokensReceivedProcessed(address indexed from, address indexed who, address indexed receiver, uint256 amount);
    // An event to log the return of Anhydrite tokens to this smart contract
    event ReturnOfThisToken(address indexed from, address indexed who, address indexed thisToken, uint256 amount);
    // An event about an exception that occurred during the execution of an external contract
    event ExceptionInfo(address indexed to, string exception);


    constructor() {
        ERC20ReceivedMagic = IERC20Receiver(address(this)).onERC20Received.selector;
        erc1820Registry.setInterfaceImplementer(address(this), keccak256("IERC20Receiver"), address(this));
        erc1820Registry.setInterfaceImplementer(address(this), keccak256("ERC20"), address(this));
    }

    /*
     * Overridden Function: onERC20Received
     * - Purpose: Implements the onERC20Received function from the IERC20Receiver interface to handle incoming ERC-20 tokens.
     * - Arguments:
     *   - _from: The sender of the ERC-20 tokens.
     *   - _who: Indicates the original sender for forwarded tokens (useful in case of proxy contracts).
     *   - _amount: The amount of tokens being sent.
     * 
     * - Behavior:
     *   1. If the message sender is this contract itself, it emits a ReturnOfAnhydrite event and returns the method selector for onERC20Received, effectively acknowledging receipt.
     *   2. If the message sender is not this contract, it returns a different bytes4 identifier, which signifies the tokens were not properly processed as per IERC20Receiver standards.
     * 
     * - Returns:
     *   - The function returns a "magic" identifier (bytes4) that confirms the execution of the onERC20Received function.
     *
     * - Events:
     *   - ReturnOfAnhydrite: Emitted when tokens are received from this contract itself.
     *   - DepositERC20: Emitted when other tokens of the EPC-20 standard are received
     */
    function onERC20Received(address _from, address _who, uint256 _amount) external override returns (bytes4) {
        bytes4 fakeID = bytes4(keccak256("anything_else"));
        bytes4 validID = ERC20ReceivedMagic;
        bytes4 returnValue = fakeID;  // Default value
        if (msg.sender.code.length > 0) {
            if (msg.sender == address(this)) {
                emit ReturnOfThisToken(_from, _who, address(this), _amount);
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
        }
        return returnValue;
    }

    // An abstract function for implementing a whitelist to handle trusted contracts with special logic.
    // If this is not required, implement a simple function that always returns false
    function _checkWhitelist(address checked) internal view virtual returns (bool);

    /*
     * Private Function: _onERC20Received
     * - Purpose: Verifies if the receiving contract complies with the IERC20Receiver interface and triggers corresponding events.
     * - Arguments:
     *   - _from: The origin address of the ERC-20 tokens.
     *   - _to: The destination address of the ERC-20 tokens.
     *   - _amount: The quantity of tokens being transferred.
     * 
     * - Behavior:
     *   1. Checks if `_to` is a contract address. If not, no further action is taken.
     *   2. If `_to` is a smart contract and is whitelisted, the `onERC20Received` method of `_to` is invoked, expecting a magic value in return.
     *   3. If `_to` is recognized as an IERC20Receiver by the ERC1820Registry, a try-catch block is used to safely call `onERC20Received` and log any exceptions.
     *   4. If `_to` doesn't fall into any of the above categories, an event is emitted to log the tokens as unprocessed.
     *
     * - Events:
     *   - AnhydriteTokensReceivedProcessed: Triggered to indicate whether the tokens were successfully processed by the receiving contract.
     *   - ExceptionInfo: Triggered when an exception occurs in the receiving contract's `onERC20Received` method, logging the reason for failure.
     */
    function _onERC20Received(address _from, address _to, uint256 _amount) internal {
	    if (_to.code.length > 0) {
            if (_checkWhitelist(msg.sender)) {
	            bytes4 retval = IERC20Receiver(_to).onERC20Received(_from, msg.sender, _amount);
                if (retval != ERC20ReceivedMagic) {
                    revert ("ERC20Receiver: An invalid magic ID was returned");
                }
                emit TokensReceivedProcessed(_from, msg.sender, _to, _amount);
            } else if (erc1820Registry.getInterfaceImplementer(msg.sender, keccak256("IERC20Receiver")) == msg.sender) {
	            try IERC20Receiver(_to).onERC20Received(_from, msg.sender, _amount) returns (bytes4 retval) {
	                require(retval == ERC20ReceivedMagic, "ERC20Receiver: An invalid magic ID was returned");
                    emit TokensReceivedProcessed(_from, msg.sender, _to, _amount);
	            } catch Error(string memory reason) {
                    emit ExceptionInfo(_to, reason);
	            } catch (bytes memory lowLevelData) {
                    string memory infoError = "Another error";
                    if (lowLevelData.length > 0) {
                        infoError = string(lowLevelData);
                    }
                    emit ExceptionInfo(_to, infoError);
	            }
            }
	    }
	}

    /*
     * Overridden Function: _afterTokenTransfer
     * - Purpose: Extends the original _afterTokenTransfer function by additionally invoking _onERC20Received when recepient are not the zero address.
     * - Arguments:
     *   - from: The sender's address.
     *   - to: The recipient's address.
     *   - amount: The amount of tokens being transferred.
     *
     * - Behavior:
     *   1. If the recipient's address (`to`) is not the zero address, this function calls the internal method _onERC20Received.
     *
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        if(to != address(0)) {
            _onERC20Received(from, to, amount);
        }
    }
}
interface IERC1820Registry {
    function setInterfaceImplementer(address account, bytes32 interfaceHash, address implementer) external;
    function getInterfaceImplementer(address account, bytes32 interfaceHash) external view returns (address);
}

// Interface for interacting with the Anhydrite contract.
interface IANH is IERC20 {
    // Returns the interface address of the proxy contract
    function getProxyAddress() external view returns (address);
    // Gets the max supply of the token.
    function getMaxSupply() external pure returns (uint256);
    // Transfers tokens for the proxy.
    function transferForProxy(uint256 amount) external;
    // Is the address whitelisted
    function isinWhitelist(address contractAddress) external view returns (bool);
}

abstract contract ModuleCashback is ERC20Receiver, Ownable {
    uint256 internal _cashback;

    // Main project token (ANH) address
    IANH internal constant ANHYDRITE = IANH(0x869c859A01935Fa5f0fc24a92C1c3C69f9b9ff6a);
    
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

    // An abstract function for implementing a whitelist to handle trusted contracts with special logic.
    function _checkWhitelist(address checked) internal view override virtual returns (bool) {
        return ANHYDRITE.isinWhitelist(checked);
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

    function deployModule(string memory name, string memory symbol, address serverContractAddress, address ownerAddress) public onlyAllowed(serverContractAddress) returns (address) {
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