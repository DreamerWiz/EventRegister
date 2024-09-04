// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract UserProfile {
    address private _agent;

    mapping(address => mapping(address => address))
        private _userChallengeAddress;
    mapping(address => uint) private _userChallengePassCount;
    mapping(address => uint) private _userChallengeCount;

    mapping(address => uint) private _userPublishedChallenge;
    mapping(uint => address) private _challengePublisher;

    function getUserChallengeAddress(
        address user,
        address challengeFactory
    ) external view returns (address) {
        return _userChallengeAddress[user][challengeFactory];
    }

    function getUserChallengeInfo(
        address user
    ) external view returns (uint passCount, uint totalCount) {
        return (_userChallengePassCount[user], _userChallengeCount[user]);
    }
}
