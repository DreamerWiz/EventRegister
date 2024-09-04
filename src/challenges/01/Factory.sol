// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./Main.sol";

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

contract Factory {
    function prepareValue() public returns (uint) {
        return 1 ether;
    }

    function prepare(address account) external payable returns (address) {
        require(msg.value == prepareValue(), "Factory: value not matched.");
        return address(new Main{value: 0.001 ether}(account));
    }
}
