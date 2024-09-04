// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/** 
  ███▄ ▄███▓ █    ██   ██████  █    ██  ▄▄▄▄    ██▓
  ▓██▒▀█▀ ██▒ ██  ▓██▒▒██    ▒  ██  ▓██▒▓█████▄ ▓██▒
  ▓██    ▓██░▓██  ▒██░░ ▓██▄   ▓██  ▒██░▒██▒ ▄██▒██▒
  ▒██    ▒██ ▓▓█  ░██░  ▒   ██▒▓▓█  ░██░▒██░█▀  ░██░
  ▒██▒   ░██▒▒▒█████▓ ▒██████▒▒▒▒█████▓ ░▓█  ▀█▓░██░
  ░ ▒░   ░  ░░▒▓▒ ▒ ▒ ▒ ▒▓▒ ▒ ░░▒▓▒ ▒ ▒ ░▒▓███▀▒░▓  
  ░  ░      ░░░▒░ ░ ░ ░ ░▒  ░ ░░░▒░ ░ ░ ▒░▒   ░  ▒ ░
  ░      ░    ░░░ ░ ░ ░  ░  ░   ░░░ ░ ░  ░    ░  ▒ ░
        ░      ░           ░     ░      ░       ░  
                                              ░     
 */

contract Main {
    address private _operator;
    address private _factory;
    mapping(address => uint) private _balances;

    modifier onlyOperator() {
        require(tx.origin == _operator);
        _;
    }

    modifier onlyFactory() {
        require(msg.sender == _factory);
        _;
    }

    constructor(address operator) payable {
        require(msg.value == 0.001 ether);
        _operator = operator;
    }

    function deposit() external payable onlyOperator {
        _balances[msg.sender] += msg.value;
    }

    function withdraw() external onlyOperator {
        address(msg.sender).call{value: _balances[msg.sender]}("");
        _balances[msg.sender] = 0;
    }

    function isPassed() external view returns (bool) {
        return address(this).balance == 0;
    }
}
