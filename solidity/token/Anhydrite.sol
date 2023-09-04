// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/*
 * Copyright (C) 2023 Anhydrite Gaming Ecosystem
 *
 * This code is part of the Anhydrite Gaming Ecosystem.
 *
 * ERC-20 Token: Anhydrite ANH
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
* VotingOwner is the only way to change the owner of a smart contract.
* The standard Ownable owner change functions from OpenZeppelin are blocked.
*/

abstract contract BaseProxyVoting is Ownable {
    
    IProxy internal _proxyContract;

    struct VoteResult {
        address[] isTrue;
        address[] isFalse;
        uint256 timestamp;
    }

    function _isProxyOwner(address senderAddress) internal view returns (bool) {
        return _proxyContract.isProxyOwner(senderAddress);
    }

    // Modifier that checks whether you are among the owners of the proxy smart contract and whether you have the right to vote
    modifier onlyProxyOwner(address senderAddress) {
        if (address(_proxyContract) != address(0)) {
            require(_isProxyOwner(senderAddress), "ProxyOwner: caller is not the proxy owner");
        } else {
            require(senderAddress == owner(), "ProxyOwner: caller is not the owner");
        }
        _;
    }

    function _votes(VoteResult storage result, bool vote) internal returns (uint256, uint256, uint256) {
        uint256 _totalOwners = 1;
        if (address(_proxyContract) != address(0)) {
            _totalOwners = _proxyContract.getTotalOwners();
        } 
        if (vote) {
            result.isTrue.push(msg.sender);
        } else {
            result.isFalse.push(msg.sender);
        }
        return (result.isTrue.length, result.isFalse.length, _totalOwners);
    }
    
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

    function _resetVote(VoteResult storage vote) internal {
        vote.isTrue = new address[](0);
        vote.isFalse = new address[](0);
        vote.timestamp = 0;
    }

    // Modifier for checking whether 3 days have passed since the start of voting and whether it can be closed
    modifier canClose(uint256 timestamp) {
        require(block.timestamp >= timestamp + 3 days, "Owners: Voting is still open");
        _;
    }

    function _closeVote(VoteResult storage vote) internal canClose(vote.timestamp) {
        _resetVote(vote);
    }

    // This override function and is deactivated
    function renounceOwnership() public view override onlyOwner {
        revert("ProxyOwner: this function is deactivated");
    }

}

abstract contract OwnableManager is BaseProxyVoting {

    address internal _proposedOwner;
    VoteResult internal _votesForNewOwner;

    event VotingForOwner(address indexed voter, address votingSubject, bool vote);
    event VotingOwnerCompleted(address indexed voter, address votingSubject, bool vote, uint votesFor, uint votesAgainst);


    // Please provide the address of the new owner for the smart contract, override function
    function transferOwnership(address proposedOwner) public override onlyProxyOwner(msg.sender) {
        require(!_isActiveForVoteOwner(), "OwnableManager: voting is already activated");
        if (address(_proxyContract) != address(0)) {
            require(!_proxyContract.isBlacklisted(proposedOwner), "OwnableManager: this address is blacklisted");
            require(_isProxyOwner(proposedOwner), "OwnableManager: caller is not the proxy owner");
        }

        _proposedOwner = proposedOwner;
        _votesForNewOwner = VoteResult(new address[](0), new address[](0), block.timestamp);
        _voteForNewOwner(true);
    }

    function voteForNewOwner(bool vote) external onlyProxyOwner(_proposedOwner) {
        _voteForNewOwner(vote);
    }

    // Voting for the address of the new owner of the smart contract 
    function _voteForNewOwner(bool vote) internal onlyProxyOwner(msg.sender) {
        require(_isActiveForVoteOwner(), "OwnableManager: there are no votes at this address");
        require(!_hasOwnerVoted(_votesForNewOwner, msg.sender), "OwnableManager: Already voted");

        (uint votestrue, uint votesfalse, uint256 _totalOwners) = _votes(_votesForNewOwner, vote);

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

    function closeVoteForNewOwner() public onlyOwner {
        require(_proposedOwner != address(0), "There is no open vote");
        _closeVote(_votesForNewOwner);
        _proposedOwner = address(0);
    }

    // Check if voting is enabled for new contract owner and their address.
    function getActiveForVoteOwner() external view returns (bool, address) {
        require(_isActiveForVoteOwner(), "OwnableManager: re is no active voting");
        return (_isActiveForVoteOwner(), _proposedOwner);
    }

    function _isActiveForVoteOwner() internal view returns (bool) {
        return _proposedOwner != address(0) && _proposedOwner !=  owner();
    }
}

abstract contract TokenManager is OwnableManager {

    address internal _proposedTransferRecepient;
    uint256 internal _proposedTransferAmount;
    VoteResult internal _votesForTransfer;

    event VotingForTransfer(address indexed voter, address recepient, uint256 amount, bool vote);
    event VotingTransferCompleted(address indexed voter, address recepient, uint256 amount, bool vote, uint votesFor, uint votesAgainst);


    // Please provide the address of the new owner for the smart contract, override function
    function initiateTransfer(address recepient, uint256 amount) public onlyProxyOwner(msg.sender) {
        require(amount != 0, "TokenManager: Incorrect amount");
        require(_proposedTransferAmount == 0, "TokenManager: voting is already activated");
        if (address(_proxyContract) != address(0)) {
            require(!_proxyContract.isBlacklisted(recepient), "TokenManager: this address is blacklisted");
        }

        _proposedTransferRecepient = recepient;
        _proposedTransferAmount = amount;
        _votesForTransfer = VoteResult(new address[](0), new address[](0), block.timestamp);
        _voteForTransfer(true);
    }

    function voteForTransfer(bool vote) external onlyProxyOwner(msg.sender) {
        _voteForTransfer(vote);
    }

    // Voting for the address of the new owner of the smart contract 
    function _voteForTransfer(bool vote) internal {
        require(_proposedTransferAmount != 0, "TokenManager: There is no active voting on this issue");
        require(!_hasOwnerVoted(_votesForTransfer, msg.sender), "VotingOwner: Already voted");

        (uint votestrue, uint votesfalse, uint256 _totalOwners) = _votes(_votesForTransfer, vote);

        emit VotingForTransfer(msg.sender, _proposedTransferRecepient, _proposedTransferAmount, vote);

        if (votestrue * 100 >= _totalOwners * 60) {
            _transferFor(_proposedTransferRecepient, _proposedTransferAmount);
            _resetVote(_votesForTransfer);
            emit VotingTransferCompleted(msg.sender, _proposedTransferRecepient, _proposedTransferAmount, vote, votestrue, votesfalse);
            _proposedTransferRecepient = address(0);
            _proposedTransferAmount = 0;
        } else if (votesfalse * 100 > _totalOwners * 40) {
            _resetVote(_votesForTransfer);
            emit VotingTransferCompleted(msg.sender, _proposedTransferRecepient, _proposedTransferAmount, vote, votestrue, votesfalse);
            _proposedTransferRecepient = address(0);
            _proposedTransferAmount = 0;
        }
    }

    function _transferFor(address recepient, uint256 amount) internal virtual;

    function closeVoteForTransfer() public onlyOwner {
        require(_proposedTransferRecepient != address(0), "There is no open vote");
        _closeVote(_votesForTransfer);
        _proposedTransferRecepient = address(0);
            _proposedTransferAmount = 0;
    }

    // Check if voting is enabled for new contract owner and their address.
    function getActiveForVoteTransfer() external view returns (address, uint256) {
        require(_proposedTransferRecepient != address(0), "VotingOwner: re is no active voting");
        return (_proposedTransferRecepient, _proposedTransferAmount);
    }
}

abstract contract ProxyManager is TokenManager {

    address internal _proposedProxy;
    VoteResult internal _votesForNewProxy;

    event VotingForNewProxy(address indexed voter, address proposedProxy, bool vote);
    event VotingONewProxyCompleted(address indexed voter, address proposedProxy, bool vote, uint votesFor, uint votesAgainst);


    // Please provide the address of the new owner for the smart contract, override function
    function initiateNewProxy(address proposedNewProxy) public onlyProxyOwner(msg.sender) {
        require(!_isActiveForVoteNewProxy(), "ProxyManager: voting is already activated");

        _proposedProxy = proposedNewProxy;
        _votesForNewProxy = VoteResult(new address[](0), new address[](0), block.timestamp);
        _voteForNewProxy(true);
    }

    function voteForNewProxy(bool vote) external onlyProxyOwner(msg.sender) {
        _voteForNewProxy(vote);
    }

    // Voting for the address of the new owner of the smart contract 
    function _voteForNewProxy(bool vote) internal {
        require(_isActiveForVoteNewProxy(), "ProxyManager: there are no votes at this address");
        require(!_hasOwnerVoted(_votesForNewProxy, msg.sender), "ProxyManager: Already voted");

        (uint votestrue, uint votesfalse, uint256 _totalOwners) = _votes(_votesForNewProxy, vote);

        emit VotingForNewProxy(msg.sender, _proposedProxy, vote);

        if (votestrue * 100 >= _totalOwners * 70) {
            _proxyContract = IProxy(_proposedProxy);
            _resetVote(_votesForNewProxy);
            emit VotingONewProxyCompleted(msg.sender, _proposedProxy, vote, votestrue, votesfalse);
            _proposedProxy = address(0);
        } else if (votesfalse * 100 > _totalOwners * 30) {
            _resetVote(_votesForNewProxy);
            emit VotingONewProxyCompleted(msg.sender, _proposedProxy, vote, votestrue, votesfalse);
            _proposedProxy = address(0);
        }
    }

    function closeVoteForNewProxy() public onlyOwner {
        require(_proposedProxy != address(0), "There is no open vote");
        _closeVote(_votesForNewProxy);
        _proposedProxy = address(0);
    }

    // Check if voting is enabled for new contract owner and their address.
    function getActiveForVoteNewProxy() external view returns (bool, address) {
        require(_isActiveForVoteNewProxy(), "OwnableManager: re is no active voting");
        return (_isActiveForVoteNewProxy(), _proposedProxy);
    }

    function _isActiveForVoteNewProxy() internal view returns (bool) {
        return _proposedProxy != address(0) && _proposedProxy !=  address(_proxyContract);
    }
}


abstract contract FinanceManager is ProxyManager {

   /// @notice Function for transferring Ether
    function withdrawMoney(uint256 amount) external onlyOwner {
        address payable recipient = payable(_proxyContract.getImplementation());
        require(address(this).balance >= amount, "Contract has insufficient balance");
        recipient.transfer(amount);
    }

    /// @notice Function for transferring ERC20 tokens
    function withdraERC20Tokens(address _tokenAddress, uint256 _amount) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        require(token.balanceOf(address(this)) >= _amount, "Not enough tokens on contract balance");
        token.transfer(_proxyContract.getImplementation(), _amount);
    }

    /// @notice Function for transferring ERC721 tokens
    function withdraERC721Token(address _tokenAddress, uint256 _tokenId) external onlyOwner {
        IERC721 token = IERC721(_tokenAddress);
        require(token.ownerOf(_tokenId) == address(this), "The contract is not the owner of this token");
        token.safeTransferFrom(address(this), _proxyContract.getImplementation(), _tokenId);
    }

}

contract Anhydrite is FinanceManager, ERC20, ERC20Burnable {
    using ERC165Checker for address;

    uint256 private constant MAX_SUPPLY = 360000000 * 10 ** 18;
    bytes4 constant ERC20ReceivedMagic = bytes4(keccak256("onERC20Received(address,uint256)"));

    constructor() ERC20("Anhydrite", "ANH") {
        _mint(address(this), 70000000 * 10 ** decimals());
    }

    function getMaxSupply() public pure returns (uint256) {
        return MAX_SUPPLY;
    }

    function transferForProxy(uint256 amount) public {
        address proxy = address(_proxyContract);
        require(_msgSender() == proxy, "Anhydrite: Only a proxy smart contract can activate this feature");
        _transferFor(proxy, amount);
    }

    function _transferFor(address recepient, uint256 amount) internal override {
        if (balanceOf(address(this)) >= amount) {
            _transfer(address(this), recepient, amount);
        } else if (totalSupply() + amount <= MAX_SUPPLY) {
            _mint(recepient, amount);
        }
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        _onERC20Received(to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        _onERC20Received(to, amount);
        return true;
    }

    function _onERC20Received(address _to, uint256 _amount) private {
        if (Address.isContract(_to)) {
            IERC165 targetContract = IERC165(_to);
            if (targetContract.supportsInterface(type(IERC20Receiver).interfaceId)) {
                
                bytes4 retval = IERC20Receiver(_to).onERC20Received(_msgSender(), _amount);
                require(retval == ERC20ReceivedMagic, "Anhydrite: Target contract cannot handle ERC20 tokens");
            }
        }
    }

    function _mint(address account, uint256 amount) internal virtual override {
        require(totalSupply() + amount <= MAX_SUPPLY, "Anhydrite: MAX_SUPPLY limit reached");
        super._mint(account, amount);
    }
}

interface IProxy {
    function getToken() external view returns (IERC20);
    function getImplementation() external view returns (address);
    function isStopped() external view returns (bool);
    function getTotalOwners() external view returns (uint256);
    function isProxyOwner(address tokenAddress) external view returns (bool);
    function isOwner(address account) external view returns (bool);
    function getBalanceOwner(address owner) external view returns (uint256);
    function getTokensNeededForOwnership() external view returns (uint256);
    function isBlacklisted(address account) external view returns (bool);
    function depositTokens(uint256 amount) external;
    function voluntarilyExit() external;
    function withdrawExcessTokens() external;
    function rescueTokens(address tokenAddress) external;

    event VoluntarilyExit(address indexed votingSubject, uint returTokens);
}

interface IERC20Receiver {
    function onERC20Received(address _from, uint256 _amount) external returns (bytes4);
}
