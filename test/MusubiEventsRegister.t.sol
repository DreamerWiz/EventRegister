// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "./MockLib.sol";
import "../src/MusubiEventsRegister.sol";
import {IEventsRegister} from "../src/IEventsRegister.sol";

contract MusubiEventsRegisterTest is Test {
    MusubiEventsRegister register;
    address owner;
    address organizer;
    address user;
    address user2;
    MockERC20 erc20;
    MockERC721 erc721;
    MockERC1155 erc1155;
    MockChallenge mockChallenge;
    MockChallengeFailed mockChallengeFailed;

    function setUp() public {
        owner = address(this); // Test contract is the owner
        organizer = address(1);
        user = address(2);
        user2 = address(3);
        register = new MusubiEventsRegister();
        erc20 = new MockERC20("MockToken", "MTK", owner);
        erc721 = new MockERC721("MockNFT", "MNFT", owner);
        erc1155 = new MockERC1155(owner);
        erc20.mint(organizer, 10 ether);
        erc721.mint(organizer);
        erc1155.mint(organizer, 1, 5);
        mockChallenge = new MockChallenge();
        mockChallengeFailed = new MockChallengeFailed();

        register.addToWhitelist(organizer);
        vm.startPrank(organizer);
        console.log(address(register));
        erc20.approve(address(register), type(uint256).max);
        erc721.approve(address(register), 1);
        erc1155.setApprovalForAll(address(register), true);
        vm.stopPrank();
    }

    // Test whitelisting functionality
    function testWhitelisting() public {
        // Owner can whitelist
        assertTrue(register.isWhitelisted(organizer));

        // Non-owner cannot whitelist
        vm.prank(user);
        vm.expectRevert();
        register.addToWhitelist(user);
    }

    // Test event registration
    function testEventRegistration() public {
        // Whitelisted user can register an event
        vm.prank(organizer);
        // Assuming a function to create a mock event
        IEventsRegister.Event memory mockEvent = createMockEvent();
        register.registerEvents(mockEvent);
    }

    // Test challenge creation
    function testChallengeCreation() public {
        // Assuming a function to create a mock event
        IEventsRegister.Event memory mockEvent = createMockEvent();
        vm.prank(organizer);
        register.registerEvents(mockEvent);
        vm.prank(user);
        register.createChallengeImpl(1, 0);
    }

    // Test event solving and reward distribution
    function testEventSolvingAndReward() public {
        // User solves a challenge
        IEventsRegister.Event memory mockEvent = createMockEvent();
        erc20.setMinter(address(register));
        vm.prank(organizer);
        register.registerEvents(mockEvent);
        vm.prank(user);
        register.createChallengeImpl(1, 0);
        vm.prank(user);
        register.solveEvent(1);
        assertEq(erc20.balanceOf(user), 2 ether);
        assertEq(erc721.ownerOf(1), user);
        assertEq(erc1155.balanceOf(user, 1), 1);
    }

    // Test event solving and reward distribution
    function testEventSolvingWithNFTMintReward() public {
        // User solves a challenge
        IEventsRegister.Event memory mockEvent = createNFTMintingMockEvent();
        erc20.setMinter(address(register));
        erc721.setMinter(address(register));
        vm.prank(organizer);
        register.registerEvents(mockEvent);
        vm.prank(user);
        register.createChallengeImpl(1, 0);
        vm.prank(user);
        register.solveEvent(1);
        vm.prank(user2);
        register.createChallengeImpl(1, 0);
        vm.prank(user2);
        register.solveEvent(1);
        assertEq(erc20.balanceOf(user), 2 ether);
        assertEq(erc20.balanceOf(user2), 0);
        assertEq(erc721.ownerOf(1), user);
        assertEq(erc721.ownerOf(2), user);
        assertEq(erc721.ownerOf(3), user2);
        assertEq(erc1155.balanceOf(user, 1), 1);
    }

    // Test event solving and reward distribution
    function testEventSolvingAndNoRemainingReward() public {
        // User solves a challenge
        IEventsRegister.Event memory mockEvent = createMockEvent();
        erc20.setMinter(address(register));
        vm.prank(organizer);
        register.registerEvents(mockEvent);
        vm.prank(user);
        register.createChallengeImpl(1, 0);
        vm.prank(user);
        register.solveEvent(1);
        vm.prank(user2);
        register.createChallengeImpl(1, 0);
        vm.prank(user2);
        register.solveEvent(1);
        assertEq(erc20.balanceOf(user), 2 ether);
        assertEq(erc20.balanceOf(user2), 0);
        assertEq(erc721.ownerOf(1), user);
        assertEq(erc1155.balanceOf(user, 1), 1);
    }

    // Utility functions to create mock data
    function createMockEvent()
        internal
        returns (IEventsRegister.Event memory e)
    {
        // Create and return a mock event
        IEventsRegister.Challenge[] memory challenges = new IEventsRegister.Challenge[](1);
        IEventsRegister.Reward[] memory rewards= new IEventsRegister.Reward[](3);
        IEventsRegister.Reward[] memory eventRewards= new IEventsRegister.Reward[](1);
        eventRewards[0] = IEventsRegister.Reward(
            address(erc20),
            IEventsRegister.RewardType.ERC20Mint,
            1 ether,
            0,
            1
        );
        rewards[0] = IEventsRegister.Reward(
            address(erc20),
            IEventsRegister.RewardType.ERC20,
            1 ether,
            0,
            1
        );

        rewards[1] = IEventsRegister.Reward(
            address(erc721),
            IEventsRegister.RewardType.ERC721,
            0,
            1,
            1
        );

        rewards[2] = IEventsRegister.Reward(
            address(erc1155),
            IEventsRegister.RewardType.ERC1155,
            1,
            1,
            1
        );

        challenges[0] = IEventsRegister.Challenge(
            IChallenge(address(mockChallenge)),
            0,
            0,
            rewards
        );

        e.startTime = block.timestamp;
        e.endTime = block.timestamp + 1 days;
        e.challenges = challenges;
        e.rewards = eventRewards;
    }
        // Utility functions to create mock data
    function createNFTMintingMockEvent()
        internal
        returns (IEventsRegister.Event memory e)
    {
        // Create and return a mock event
        
        e = createMockEvent();
        IEventsRegister.Reward[] memory eventRewards= new IEventsRegister.Reward[](2);
        eventRewards[0] = IEventsRegister.Reward(
            address(erc20),
            IEventsRegister.RewardType.ERC20Mint,
            1 ether,
            0,
            1
        );
        eventRewards[1] = IEventsRegister.Reward(
            address(erc721),
            IEventsRegister.RewardType.ERC721Mint,
            1,
            0,
            2
        );
        e.rewards = eventRewards;
        
    }
}
