// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";

contract MockImpl {
    address data;

    constructor() {
        data = msg.sender;
    }
}

contract MockChallenge {
    mapping(address => address) public implMapping;

    function initialize() external returns (address) {
        MockImpl impl = new MockImpl();
        implMapping[msg.sender] = address(impl);
        return address(impl);
    }

    function getSeed() external returns (bytes32) {
        return keccak256(abi.encodePacked(msg.sender));
    }

    function verify(bytes32 seed) external returns (bool) {
        return true;
    }
}

contract MockChallengeFailed {
    mapping(address => address) public implMapping;

    function initialize() external returns (address) {
        MockImpl impl = new MockImpl();
        implMapping[msg.sender] = address(impl);
        return address(impl);
    }

    function getSeed() external returns (bytes32) {
        return keccak256(abi.encodePacked(msg.sender));
    }

    function verify(bytes32 seed) external returns (bool) {
        return false;
    }
}

contract MockERC20 is ERC20 {
    address minter;

    constructor(
        string memory name,
        string memory symbol,
        address _minter
    ) ERC20(name, symbol) {
        minter = _minter;
    }

    function setMinter(address newMinter) public{
        require(msg.sender == minter);
        minter = newMinter;
    }

    function mint(address to, uint256 amount) public {
        require(msg.sender == minter);
        _mint(to, amount);
    }
}

contract MockERC721 is ERC721 {
    uint256 private _tokenIdCounter = 1;
    address minter;

    constructor(
        string memory name,
        string memory symbol,
        address _minter
    ) ERC721(name, symbol) {
        minter = _minter;
    }

    function setMinter(address newMinter) public{
        require(msg.sender == minter);
        minter = newMinter;
    }

    function mint(address to) public {
        require(msg.sender == minter);
        _safeMint(to, _tokenIdCounter);
        _tokenIdCounter++;
    }
}

contract MockERC1155 is ERC1155 {
    address minter;

    constructor(
        address _minter
    ) ERC1155("http://api.example.com/token/{id}.json") {
        minter = _minter;
    }

    function setMinter(address newMinter) public{
        require(msg.sender == minter);
        minter = newMinter;
    }

    function mint(address to, uint256 id, uint256 amount) public {
        require(msg.sender == minter);
        _mint(to, id, amount, "");
    }
}
