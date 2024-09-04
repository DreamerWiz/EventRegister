// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import {Agent} from "../src/Agent.sol";

contract AgentTest is Test {
    Agent agent;

    function setUp() public {
        agent = new Agent();
    }
}
