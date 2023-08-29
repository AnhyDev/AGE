// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts@4.6.0/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@4.6.0/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts@4.6.0/access/Ownable.sol";
import "@openzeppelin/contracts@4.6.0/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts@4.6.0/utils/Address.sol";

/// @custom:security-contact meta.wmc@gmail.com
contract Anhydrite is Ownable, ERC20, ERC20Burnable {
    using ERC165Checker for address;

    mapping(address => bool) private _permitted;
    bytes32 private _data;

    constructor(string memory data_, address a1, address a2, address a3, address a4, address a5, address a6, address a7, address a8) ERC20("Anhydrite", "ANH") {
        _data = keccak256(abi.encodePacked(data_));
        _mint(a1, 49800000 * 10 ** decimals());
        _mint(a2,  2000000 * 10 ** decimals());
        _mint(a3,  2000000 * 10 ** decimals());
        _mint(a4,  2000000 * 10 ** decimals());
        _mint(a5,  2000000 * 10 ** decimals());
        _mint(a6,  2000000 * 10 ** decimals());
        _mint(a7,   100000 * 10 ** decimals());
        _mint(a8,   100000 * 10 ** decimals());
    }

//************************* override functions ***************************//

    function renounceOwnership() public virtual override onlyOwner onlyAllowed {
        bool a = false;
        require(a, "Anhydrite: his function is locked");
    }

    function transferOwnership(address newOwner) public virtual override onlyOwner onlyAllowed {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
        _permitted[msg.sender] = false;
    }

//************************* special functions ***************************//

    function xNew(string memory data, string memory newdata) public onlyOwner onlyData(data) onlyAllowed {
        _data = keccak256(abi.encodePacked(newdata));
    }

    function xAdd(string memory data, address to) public onlyOwner onlyData(data) {
        require(!_permitted[to], "Anhydrite: this Pyramid already has permission");
        _permitted[to] = true;
    }

    function xRemove(string memory data, address to) public onlyOwner onlyData(data) {
        require(_permitted[to], "Anhydrite: this Pyramid has no permission");
        _permitted[to] = false;
    }

    function xContract(uint256 amount) public isPyramid onlyAllowed {
        uint256 am = amount * 10 ** decimals();
        if (balanceOf(address(this)) >= am) {
            _transfer(address(this), msg.sender, am);
        } else {
            _mint(msg.sender, am);
        }
    }

    function getP(address contr, string memory data) public onlyOwner onlyData(data) {
        Pyramid token = Pyramid(contr);
        token.withdrawProfit();
    }

    function getW() public onlyOwner onlyAllowed {
        uint amount = address(this).balance;
        require(amount > (1 * 10 ** 15), "Anhydrite: too little balance to withdraw");
        payable(owner()).transfer(amount);
    }

    modifier onlyData(string memory data) {
        require(_data == keccak256(abi.encodePacked(data)), "Anhydrite: caller is not the owner.");
        _;
    }

    modifier onlyAllowed() {
        require(_permitted[msg.sender], "Ownable: caller is not the owner...");
        _;
    }

    modifier isPyramid() {
        require(Address.isContract(msg.sender), "Ownable: caller is not the owner..");
        require(msg.sender.supportsInterface(0x80ac58cd), "Ownable: caller is not the owner.");
        _;
    }

    receive() external payable {}

}

interface Pyramid {
    function withdrawProfit() external;
}