// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Agent} from "../src/Agent.sol";
import {Challenge, ChallengeReward, RewardTokenDetailInfo, ChallengeStatus, UserRewardRecord, ChallengeInfo, ChallengeRewardStrategy, UserChallengeInfo, UserChallengeStatus} from "../src/Challenge.sol";
import {Factory} from "../src/challenges/01/Factory.sol";
import {Main} from "../src/challenges/01/Main.sol";
import {MockERC20} from "./MockERC20.sol";
import {TokenType} from "../src/interface/IAgent.sol";
import {Attacker} from "./Attacker.sol";

import {IChallenge} from "../src/interface/IChallenge.sol";

contract ChallengeAddTest is Test {
    Agent agent;
    address owner = address(1);
    address user1 = address(2);

    address challengeFactory;
    address main;

    address token;

    Challenge challenge;

    function setUp() public {
        vm.startPrank(owner);
        agent = new Agent();

        agent.grantRole(agent.CHALLENGE_MANAGER_ADMIN_ROLE(), owner);
        agent.grantRole(agent.CHALLENGE_MANAGER_ROLE(), owner);
        agent.grantRole(agent.MANAGER_ADMIN_ROLE(), owner);
        agent.grantRole(agent.MANAGER_ROLE(), owner);
        challengeFactory = address(new Factory());
        challenge = new Challenge(address(agent));

        token = address(new MockERC20("Test", "tst"));
    }

    function test_AddChallenge_not_allowed() public {
        RewardTokenDetailInfo[] memory rtds = new RewardTokenDetailInfo[](1);
        RewardTokenDetailInfo memory rtd;

        rtd.tokenSize = 1;
        rtd.tokens = new address[](1);
        rtd.tokens[0] = token;
        rtd.tokenDatas = new bytes[](1);
        rtd.tokenDatas[0] = "";
        rtd.tokenIds = new uint[](1);
        rtd.tokenIds[0] = 0;
        rtd.tokenAmounts = new uint[](1);
        rtd.tokenAmounts[0] = 20 ether;
        rtd.tokenFloats = new uint[](1);
        rtd.tokenFloats[0] = 0;
        rtd.tokenProbabilities = new uint[](1);
        rtd.tokenProbabilities[0] = 0;

        rtds[0] = rtd;

        ChallengeReward[] memory rewards;
        ChallengeReward memory reward;
        reward.strategy = ChallengeRewardStrategy.RankOnce;
        reward.values = new uint[](1);
        reward.values[0] = 1;
        reward.rewards = rtds;

        vm.expectRevert();
        vm.prank(user1);
        challenge.addChallenge(user1, challengeFactory, 1 ether, rewards);
    }

    function test_AddChallenge_allowed_token_not_supported() public {
        vm.startPrank(owner);

        agent.setChallengeManager(user1, true);

        RewardTokenDetailInfo[] memory rtds = new RewardTokenDetailInfo[](1);
        RewardTokenDetailInfo memory rtd;

        rtd.tokenSize = 1;
        rtd.tokens = new address[](1);
        rtd.tokens[0] = token;
        rtd.tokenDatas = new bytes[](1);
        rtd.tokenDatas[0] = "";
        rtd.tokenIds = new uint[](1);
        rtd.tokenIds[0] = 0;
        rtd.tokenAmounts = new uint[](1);
        rtd.tokenAmounts[0] = 20 ether;
        rtd.tokenFloats = new uint[](1);
        rtd.tokenFloats[0] = 0;
        rtd.tokenProbabilities = new uint[](1);
        rtd.tokenProbabilities[0] = 0;

        rtds[0] = rtd;

        ChallengeReward[] memory rewards = new ChallengeReward[](1);
        ChallengeReward memory reward;
        reward.strategy = ChallengeRewardStrategy.RankOnce;
        reward.values = new uint[](1);
        reward.values[0] = 1;
        reward.rewards = rtds;

        rewards[0] = reward;
        vm.stopPrank();

        // vm.expectRevert();
        assertTrue(agent.hasRole(agent.DEFAULT_ADMIN_ROLE(), owner));
        assertTrue(agent.hasRole(agent.CHALLENGE_MANAGER_ROLE(), owner));
        vm.expectRevert();
        vm.prank(owner);
        challenge.addChallenge(user1, challengeFactory, 1 ether, rewards);
    }

    function test_AddChallenge_allowed_token_supported() public {
        vm.startPrank(owner);

        agent.setChallengeManager(user1, true);
        agent.addWhitelistedToken(token, TokenType.MusubiBadge);

        RewardTokenDetailInfo[] memory rtds = new RewardTokenDetailInfo[](1);
        RewardTokenDetailInfo memory rtd;

        rtd.tokenSize = 1;
        rtd.tokens = new address[](1);
        rtd.tokens[0] = token;
        rtd.tokenDatas = new bytes[](1);
        rtd.tokenDatas[0] = "";
        rtd.tokenIds = new uint[](1);
        rtd.tokenIds[0] = 0;
        rtd.tokenAmounts = new uint[](1);
        rtd.tokenAmounts[0] = 20 ether;
        rtd.tokenFloats = new uint[](1);
        rtd.tokenFloats[0] = 0;
        rtd.tokenProbabilities = new uint[](1);
        rtd.tokenProbabilities[0] = 0;

        rtds[0] = rtd;

        ChallengeReward[] memory rewards = new ChallengeReward[](1);
        ChallengeReward memory reward;
        reward.strategy = ChallengeRewardStrategy.RankOnce;
        reward.values = new uint[](1);
        reward.values[0] = 1;
        reward.rewards = rtds;

        rewards[0] = reward;
        vm.stopPrank();

        // vm.expectRevert();
        assertTrue(agent.hasRole(agent.DEFAULT_ADMIN_ROLE(), owner));
        assertTrue(agent.hasRole(agent.CHALLENGE_MANAGER_ROLE(), owner));
        vm.prank(owner);
        challenge.addChallenge(user1, challengeFactory, 1 ether, rewards);
    }

    function test_AddChallenge_allowed_token_supported_repeat() public {
        vm.startPrank(owner);

        agent.setChallengeManager(user1, true);
        agent.addWhitelistedToken(token, TokenType.MusubiBadge);

        RewardTokenDetailInfo[] memory rtds = new RewardTokenDetailInfo[](1);
        RewardTokenDetailInfo memory rtd;

        rtd.tokenSize = 1;
        rtd.tokens = new address[](1);
        rtd.tokens[0] = token;
        rtd.tokenDatas = new bytes[](1);
        rtd.tokenDatas[0] = "";
        rtd.tokenIds = new uint[](1);
        rtd.tokenIds[0] = 0;
        rtd.tokenAmounts = new uint[](1);
        rtd.tokenAmounts[0] = 20 ether;
        rtd.tokenFloats = new uint[](1);
        rtd.tokenFloats[0] = 0;
        rtd.tokenProbabilities = new uint[](1);
        rtd.tokenProbabilities[0] = 0;

        rtds[0] = rtd;

        ChallengeReward[] memory rewards = new ChallengeReward[](1);
        ChallengeReward memory reward;
        reward.strategy = ChallengeRewardStrategy.RankOnce;
        reward.values = new uint[](1);
        reward.values[0] = 1;
        reward.rewards = rtds;

        rewards[0] = reward;
        vm.stopPrank();

        // vm.expectRevert();
        assertTrue(agent.hasRole(agent.DEFAULT_ADMIN_ROLE(), owner));
        assertTrue(agent.hasRole(agent.CHALLENGE_MANAGER_ROLE(), owner));
        vm.prank(owner);
        challenge.addChallenge(user1, challengeFactory, 1 ether, rewards);

        vm.expectRevert();
        vm.prank(owner);
        challenge.addChallenge(user1, challengeFactory, 1 ether, rewards);
    }

    function test_AddChallenge_allowed_token_supported_values_not_incresing()
        public
    {
        vm.startPrank(owner);

        agent.setChallengeManager(user1, true);
        agent.addWhitelistedToken(token, TokenType.MusubiBadge);

        RewardTokenDetailInfo[] memory rtds = new RewardTokenDetailInfo[](3);
        RewardTokenDetailInfo memory rtd;

        rtd.tokenSize = 1;
        rtd.tokens = new address[](1);
        rtd.tokens[0] = token;
        rtd.tokenDatas = new bytes[](1);
        rtd.tokenDatas[0] = "";
        rtd.tokenIds = new uint[](1);
        rtd.tokenIds[0] = 0;
        rtd.tokenAmounts = new uint[](1);
        rtd.tokenAmounts[0] = 20 ether;
        rtd.tokenFloats = new uint[](1);
        rtd.tokenFloats[0] = 0;
        rtd.tokenProbabilities = new uint[](1);
        rtd.tokenProbabilities[0] = 0;

        rtds[0] = rtd;
        rtds[1] = rtd;
        rtds[2] = rtd;

        ChallengeReward[] memory rewards = new ChallengeReward[](1);
        ChallengeReward memory reward;
        reward.strategy = ChallengeRewardStrategy.RankOnce;
        reward.values = new uint[](3);
        reward.values[0] = 2;
        reward.values[1] = 1;
        reward.values[2] = 3;
        reward.rewards = rtds;

        rewards[0] = reward;
        vm.stopPrank();

        // vm.expectRevert();
        assertTrue(agent.hasRole(agent.DEFAULT_ADMIN_ROLE(), owner));
        assertTrue(agent.hasRole(agent.CHALLENGE_MANAGER_ROLE(), owner));
        vm.expectRevert();
        vm.prank(owner);
        challenge.addChallenge(user1, challengeFactory, 1 ether, rewards);

        reward.strategy = ChallengeRewardStrategy.TimeLimitOnce;
        vm.expectRevert();
        vm.prank(owner);
        challenge.addChallenge(user1, challengeFactory, 1 ether, rewards);

        reward.strategy = ChallengeRewardStrategy.TimeLimitOnce;
        vm.expectRevert();
        vm.prank(owner);
        challenge.addChallenge(user1, challengeFactory, 1 ether, rewards);
    }

    function test_AddChallenge_normal_tokenSize_invalid_tokens() public {
        vm.startPrank(owner);

        agent.setChallengeManager(user1, true);
        agent.addWhitelistedToken(token, TokenType.MusubiBadge);

        RewardTokenDetailInfo[] memory rtds = new RewardTokenDetailInfo[](1);
        RewardTokenDetailInfo memory rtd;

        rtd.tokenSize = 1;
        rtd.tokens = new address[](2);
        rtd.tokens[0] = token;
        rtd.tokens[1] = token;
        rtd.tokenDatas = new bytes[](1);
        rtd.tokenDatas[0] = "";
        rtd.tokenIds = new uint[](1);
        rtd.tokenIds[0] = 0;
        rtd.tokenAmounts = new uint[](1);
        rtd.tokenAmounts[0] = 20 ether;
        rtd.tokenFloats = new uint[](1);
        rtd.tokenFloats[0] = 0;
        rtd.tokenProbabilities = new uint[](1);
        rtd.tokenProbabilities[0] = 0;

        rtds[0] = rtd;

        ChallengeReward[] memory rewards = new ChallengeReward[](1);
        ChallengeReward memory reward;
        reward.strategy = ChallengeRewardStrategy.RankOnce;
        reward.values = new uint[](1);
        reward.values[0] = 1;
        reward.rewards = rtds;

        rewards[0] = reward;
        vm.stopPrank();

        // vm.expectRevert();
        assertTrue(agent.hasRole(agent.DEFAULT_ADMIN_ROLE(), owner));
        assertTrue(agent.hasRole(agent.CHALLENGE_MANAGER_ROLE(), owner));
        vm.prank(owner);
        vm.expectRevert();
        challenge.addChallenge(user1, challengeFactory, 1 ether, rewards);
    }

    function test_AddChallenge_normal_tokenSize_invalid_tokenDatas() public {
        vm.startPrank(owner);

        agent.setChallengeManager(user1, true);
        agent.addWhitelistedToken(token, TokenType.MusubiBadge);

        RewardTokenDetailInfo[] memory rtds = new RewardTokenDetailInfo[](1);
        RewardTokenDetailInfo memory rtd;

        rtd.tokenSize = 1;
        rtd.tokens = new address[](1);
        rtd.tokens[0] = token;
        rtd.tokenDatas = new bytes[](2);
        rtd.tokenDatas[0] = "";
        rtd.tokenDatas[1] = "";
        rtd.tokenIds = new uint[](1);
        rtd.tokenIds[0] = 0;
        rtd.tokenAmounts = new uint[](1);
        rtd.tokenAmounts[0] = 20 ether;
        rtd.tokenFloats = new uint[](1);
        rtd.tokenFloats[0] = 0;
        rtd.tokenProbabilities = new uint[](1);
        rtd.tokenProbabilities[0] = 0;

        rtds[0] = rtd;

        ChallengeReward[] memory rewards = new ChallengeReward[](1);
        ChallengeReward memory reward;
        reward.strategy = ChallengeRewardStrategy.RankOnce;
        reward.values = new uint[](1);
        reward.values[0] = 1;
        reward.rewards = rtds;

        rewards[0] = reward;
        vm.stopPrank();

        // vm.expectRevert();
        assertTrue(agent.hasRole(agent.DEFAULT_ADMIN_ROLE(), owner));
        assertTrue(agent.hasRole(agent.CHALLENGE_MANAGER_ROLE(), owner));
        vm.prank(owner);
        vm.expectRevert();
        challenge.addChallenge(user1, challengeFactory, 1 ether, rewards);
    }

    function test_AddChallenge_normal_tokenSize_invalid_tokenProbabilities()
        public
    {
        vm.startPrank(owner);

        agent.setChallengeManager(user1, true);
        agent.addWhitelistedToken(token, TokenType.MusubiBadge);

        RewardTokenDetailInfo[] memory rtds = new RewardTokenDetailInfo[](1);
        RewardTokenDetailInfo memory rtd;

        rtd.tokenSize = 1;
        rtd.tokens = new address[](1);
        rtd.tokens[0] = token;
        rtd.tokenDatas = new bytes[](1);
        rtd.tokenDatas[0] = "";
        rtd.tokenIds = new uint[](1);
        rtd.tokenIds[0] = 0;
        rtd.tokenAmounts = new uint[](1);
        rtd.tokenAmounts[0] = 20 ether;
        rtd.tokenFloats = new uint[](1);
        rtd.tokenFloats[0] = 0;
        rtd.tokenProbabilities = new uint[](2);
        rtd.tokenProbabilities[0] = 0;
        rtd.tokenProbabilities[1] = 0;

        rtds[0] = rtd;

        ChallengeReward[] memory rewards = new ChallengeReward[](1);
        ChallengeReward memory reward;
        reward.strategy = ChallengeRewardStrategy.RankOnce;
        reward.values = new uint[](1);
        reward.values[0] = 1;
        reward.rewards = rtds;

        rewards[0] = reward;
        vm.stopPrank();

        // vm.expectRevert();
        assertTrue(agent.hasRole(agent.DEFAULT_ADMIN_ROLE(), owner));
        assertTrue(agent.hasRole(agent.CHALLENGE_MANAGER_ROLE(), owner));
        vm.prank(owner);
        vm.expectRevert();
        challenge.addChallenge(user1, challengeFactory, 1 ether, rewards);
    }

    function test_AddChallenge_normal_tokenSize_invalid_tokenIds() public {
        vm.startPrank(owner);

        agent.setChallengeManager(user1, true);
        agent.addWhitelistedToken(token, TokenType.MusubiBadge);

        RewardTokenDetailInfo[] memory rtds = new RewardTokenDetailInfo[](1);
        RewardTokenDetailInfo memory rtd;

        rtd.tokenSize = 1;
        rtd.tokens = new address[](1);
        rtd.tokens[0] = token;
        rtd.tokenDatas = new bytes[](1);
        rtd.tokenDatas[0] = "";
        rtd.tokenIds = new uint[](2);
        rtd.tokenIds[0] = 0;
        rtd.tokenIds[1] = 0;
        rtd.tokenAmounts = new uint[](1);
        rtd.tokenAmounts[0] = 20 ether;
        rtd.tokenFloats = new uint[](1);
        rtd.tokenFloats[0] = 0;
        rtd.tokenProbabilities = new uint[](1);
        rtd.tokenProbabilities[0] = 0;

        rtds[0] = rtd;

        ChallengeReward[] memory rewards = new ChallengeReward[](1);
        ChallengeReward memory reward;
        reward.strategy = ChallengeRewardStrategy.RankOnce;
        reward.values = new uint[](1);
        reward.values[0] = 1;
        reward.rewards = rtds;

        rewards[0] = reward;
        vm.stopPrank();

        // vm.expectRevert();
        assertTrue(agent.hasRole(agent.DEFAULT_ADMIN_ROLE(), owner));
        assertTrue(agent.hasRole(agent.CHALLENGE_MANAGER_ROLE(), owner));
        vm.prank(owner);
        vm.expectRevert();
        challenge.addChallenge(user1, challengeFactory, 1 ether, rewards);
    }

    function test_AddChallenge_normal_tokenSize_invalid_tokenAmounts() public {
        vm.startPrank(owner);

        agent.setChallengeManager(user1, true);
        agent.addWhitelistedToken(token, TokenType.MusubiBadge);

        RewardTokenDetailInfo[] memory rtds = new RewardTokenDetailInfo[](1);
        RewardTokenDetailInfo memory rtd;

        rtd.tokenSize = 1;
        rtd.tokens = new address[](1);
        rtd.tokens[0] = token;
        rtd.tokenDatas = new bytes[](1);
        rtd.tokenDatas[0] = "";
        rtd.tokenIds = new uint[](1);
        rtd.tokenIds[0] = 0;
        rtd.tokenAmounts = new uint[](2);
        rtd.tokenAmounts[0] = 20 ether;
        rtd.tokenAmounts[1] = 20 ether;
        rtd.tokenFloats = new uint[](1);
        rtd.tokenFloats[0] = 0;
        rtd.tokenProbabilities = new uint[](1);
        rtd.tokenProbabilities[0] = 0;

        rtds[0] = rtd;

        ChallengeReward[] memory rewards = new ChallengeReward[](1);
        ChallengeReward memory reward;
        reward.strategy = ChallengeRewardStrategy.RankOnce;
        reward.values = new uint[](1);
        reward.values[0] = 1;
        reward.rewards = rtds;

        rewards[0] = reward;
        vm.stopPrank();

        // vm.expectRevert();
        assertTrue(agent.hasRole(agent.DEFAULT_ADMIN_ROLE(), owner));
        assertTrue(agent.hasRole(agent.CHALLENGE_MANAGER_ROLE(), owner));
        vm.prank(owner);
        vm.expectRevert();
        challenge.addChallenge(user1, challengeFactory, 1 ether, rewards);
    }

    function test_AddChallenge_normal_tokenSize_invalid_tokenFloats() public {
        vm.startPrank(owner);

        agent.setChallengeManager(user1, true);
        agent.addWhitelistedToken(token, TokenType.MusubiBadge);

        RewardTokenDetailInfo[] memory rtds = new RewardTokenDetailInfo[](1);
        RewardTokenDetailInfo memory rtd;

        rtd.tokenSize = 1;
        rtd.tokens = new address[](1);
        rtd.tokens[0] = token;
        rtd.tokenDatas = new bytes[](1);
        rtd.tokenDatas[0] = "";
        rtd.tokenIds = new uint[](1);
        rtd.tokenIds[0] = 0;
        rtd.tokenAmounts = new uint[](1);
        rtd.tokenAmounts[0] = 20 ether;
        rtd.tokenFloats = new uint[](2);
        rtd.tokenFloats[0] = 0;
        rtd.tokenFloats[1] = 0;
        rtd.tokenProbabilities = new uint[](1);
        rtd.tokenProbabilities[0] = 0;

        rtds[0] = rtd;

        ChallengeReward[] memory rewards = new ChallengeReward[](1);
        ChallengeReward memory reward;
        reward.strategy = ChallengeRewardStrategy.RankOnce;
        reward.values = new uint[](1);
        reward.values[0] = 1;
        reward.rewards = rtds;

        rewards[0] = reward;
        vm.stopPrank();

        // vm.expectRevert();
        assertTrue(agent.hasRole(agent.DEFAULT_ADMIN_ROLE(), owner));
        assertTrue(agent.hasRole(agent.CHALLENGE_MANAGER_ROLE(), owner));
        vm.prank(owner);
        vm.expectRevert();
        challenge.addChallenge(user1, challengeFactory, 1 ether, rewards);
    }

    function test_AddChallenge_normal_check_value() public {
        vm.startPrank(owner);

        agent.setChallengeManager(user1, true);
        agent.addWhitelistedToken(token, TokenType.MusubiBadge);

        RewardTokenDetailInfo[] memory rtds = new RewardTokenDetailInfo[](1);
        RewardTokenDetailInfo memory rtd;

        rtd.tokenSize = 1;
        rtd.tokens = new address[](1);
        rtd.tokens[0] = token;
        rtd.tokenDatas = new bytes[](1);
        rtd.tokenDatas[0] = "";
        rtd.tokenIds = new uint[](1);
        rtd.tokenIds[0] = 0;
        rtd.tokenAmounts = new uint[](1);
        rtd.tokenAmounts[0] = 20 ether;
        rtd.tokenFloats = new uint[](1);
        rtd.tokenFloats[0] = 0;
        rtd.tokenProbabilities = new uint[](1);
        rtd.tokenProbabilities[0] = 0;

        rtds[0] = rtd;

        ChallengeReward[] memory rewards = new ChallengeReward[](1);
        ChallengeReward memory reward;
        reward.strategy = ChallengeRewardStrategy.RankOnce;
        reward.values = new uint[](1);
        reward.values[0] = 1;
        reward.rewards = rtds;

        rewards[0] = reward;
        vm.stopPrank();

        // vm.expectRevert();
        assertTrue(agent.hasRole(agent.DEFAULT_ADMIN_ROLE(), owner));
        assertTrue(agent.hasRole(agent.CHALLENGE_MANAGER_ROLE(), owner));
        vm.prank(owner);
        challenge.addChallenge(user1, challengeFactory, 1 ether, rewards);
    }
}

contract ChallengeTest is Test {
    Agent agent;
    address owner = address(1);
    address user1 = address(2);
    address user2 = address(3);
    address user3 = address(4);

    address challengeFactory;
    address main;

    address token;

    Challenge challenge;

    function setUp() public {
        vm.warp(block.timestamp + 30000);

        vm.startPrank(owner);
        agent = new Agent();

        agent.grantRole(agent.CHALLENGE_MANAGER_ADMIN_ROLE(), owner);
        agent.grantRole(agent.CHALLENGE_MANAGER_ROLE(), owner);
        agent.grantRole(agent.MANAGER_ADMIN_ROLE(), owner);
        agent.grantRole(agent.MANAGER_ROLE(), owner);
        challengeFactory = address(new Factory());
        challenge = new Challenge(address(agent));

        token = address(new MockERC20("Test", "tst"));

        vm.startPrank(owner);

        agent.setChallengeManager(user1, true);
        agent.addWhitelistedToken(token, TokenType.MusubiBadge);

        RewardTokenDetailInfo[] memory rtds = new RewardTokenDetailInfo[](1);
        RewardTokenDetailInfo memory rtd;

        rtd.tokenSize = 1;
        rtd.tokens = new address[](1);
        rtd.tokens[0] = token;
        rtd.tokenDatas = new bytes[](1);
        rtd.tokenDatas[0] = "";
        rtd.tokenIds = new uint[](1);
        rtd.tokenIds[0] = 0;
        rtd.tokenAmounts = new uint[](1);
        rtd.tokenAmounts[0] = 20 ether;
        rtd.tokenFloats = new uint[](1);
        rtd.tokenFloats[0] = 0;
        rtd.tokenProbabilities = new uint[](1);
        rtd.tokenProbabilities[0] = 0;

        rtds[0] = rtd;

        ChallengeReward[] memory rewards = new ChallengeReward[](1);
        ChallengeReward memory reward;
        reward.strategy = ChallengeRewardStrategy.RankOnce;
        reward.values = new uint[](1);
        reward.values[0] = 1;
        reward.rewards = rtds;

        rewards[0] = reward;
        vm.stopPrank();

        // vm.expectRevert();
        assertTrue(agent.hasRole(agent.DEFAULT_ADMIN_ROLE(), owner));
        assertTrue(agent.hasRole(agent.CHALLENGE_MANAGER_ROLE(), owner));
        vm.prank(owner);
        challenge.addChallenge(user1, challengeFactory, 1 ether, rewards);
    }

    function test_GenerateChallenge() public {
        hoax(owner, 1 ether);
        challenge.generateChallenge{value: 1 ether}(user1, 1);

        UserChallengeInfo memory userChallengeInfo = challenge
            .getUserChallengeInfo(1, user1);

        ChallengeInfo memory challengeInfo = challenge.getChallengeInfo(1);

        assertEq(userChallengeInfo.challenge, address(0));

        vm.prank(user1);
        userChallengeInfo = challenge.getUserChallengeInfo(1, user1);
        assertNotEq(userChallengeInfo.challenge, address(0));
        console.log(userChallengeInfo.challenge);

        assert(userChallengeInfo.status == UserChallengeStatus.Ongoing);
        assert(userChallengeInfo.rank == 0);
        assert(userChallengeInfo.startTime == block.timestamp);
        assert(userChallengeInfo.timeCost == 0);

        ChallengeReward memory cr = challengeInfo.rewards[0];
        UserRewardRecord memory ur = userChallengeInfo.rewardRecords[0];

        assert(cr.strategy == ur.strategy);
    }

    function test_ResolveChallenge() public {
        vm.warp(block.timestamp + 500);
        hoax(owner, 1 ether);
        challenge.generateChallenge{value: 1 ether}(user1, 1);

        hoax(owner, 1 ether);
        challenge.generateChallenge{value: 1 ether}(user2, 1);

        hoax(owner, 1 ether);
        challenge.generateChallenge{value: 1 ether}(user3, 1);

        ChallengeInfo memory challengeInfo = challenge.getChallengeInfo(1);

        assertEq(challengeInfo.participantCount, 3);
        assertEq(challengeInfo.passCount, 0);

        vm.prank(user1);
        UserChallengeInfo memory userChallengeInfo = challenge
            .getUserChallengeInfo(1, user1);
        // challengeInfo.challenge

        hoax(user1, user1, 10 ether);
        Attacker attacker = new Attacker(userChallengeInfo.challenge);
        vm.prank(user1, user1);
        attacker.attack{value: 0.001 ether}();

        console.log(address(userChallengeInfo.challenge).balance);
        console.log(IChallenge(userChallengeInfo.challenge).isPassed());

        challenge.getChallengeInfo(1);

        vm.prank(owner);
        challenge.verifyChallenge(user1, 1);

        challengeInfo = challenge.getChallengeInfo(1);
        userChallengeInfo = challenge.getUserChallengeInfo(1, user1);
        console.log(challengeInfo.contributor);
        assertEq(challengeInfo.contributor, user1);
        console.log(challengeInfo.status == ChallengeStatus.InUse);
        assert(challengeInfo.status == ChallengeStatus.InUse);
        console.log(challengeInfo.passCount);
        // assert(challengeInfo.passCount == 1);
        console.log(challengeInfo.participantCount);
        assertEq(challengeInfo.participantCount, 3);
        assertEq(challengeInfo.passCount, 1);
        console.log(challengeInfo.startTime);
        console.log(challengeInfo.prepareValue);
        console.log("////////////");

        console.log(userChallengeInfo.challenge);
        console.log(userChallengeInfo.status == UserChallengeStatus.Finished);
        console.log(userChallengeInfo.rank);
        console.log(userChallengeInfo.timeCost);
        console.log(userChallengeInfo.startTime);
    }

    function test_ClaimReward_Rank() public {
        vm.warp(block.timestamp + 500);
        hoax(owner, 1 ether);
        challenge.generateChallenge{value: 1 ether}(user1, 1);

        hoax(owner, 1 ether);
        challenge.generateChallenge{value: 1 ether}(user2, 1);

        hoax(owner, 1 ether);
        challenge.generateChallenge{value: 1 ether}(user3, 1);

        ChallengeInfo memory challengeInfo = challenge.getChallengeInfo(1);

        assertEq(challengeInfo.participantCount, 3);
        assertEq(challengeInfo.passCount, 0);

        vm.prank(user1);
        UserChallengeInfo memory userChallengeInfo = challenge
            .getUserChallengeInfo(1, user1);
        // challengeInfo.challenge

        hoax(user1, user1, 10 ether);
        Attacker attacker = new Attacker(userChallengeInfo.challenge);
        vm.prank(user1, user1);
        attacker.attack{value: 0.001 ether}();

        console.log(address(userChallengeInfo.challenge).balance);
        console.log(IChallenge(userChallengeInfo.challenge).isPassed());

        challenge.getChallengeInfo(1);

        vm.prank(owner);
        challenge.verifyChallenge(user1, 1);
    }
}
