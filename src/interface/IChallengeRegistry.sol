// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

// /**
//   ███▄ ▄███▓ █    ██   ██████  █    ██  ▄▄▄▄    ██▓
//   ▓██▒▀█▀ ██▒ ██  ▓██▒▒██    ▒  ██  ▓██▒▓█████▄ ▓██▒
//   ▓██    ▓██░▓██  ▒██░░ ▓██▄   ▓██  ▒██░▒██▒ ▄██▒██▒
//   ▒██    ▒██ ▓▓█  ░██░  ▒   ██▒▓▓█  ░██░▒██░█▀  ░██░
//   ▒██▒   ░██▒▒▒█████▓ ▒██████▒▒▒▒█████▓ ░▓█  ▀█▓░██░
//   ░ ▒░   ░  ░░▒▓▒ ▒ ▒ ▒ ▒▓▒ ▒ ░░▒▓▒ ▒ ▒ ░▒▓███▀▒░▓
//   ░  ░      ░░░▒░ ░ ░ ░ ░▒  ░ ░░░▒░ ░ ░ ▒░▒   ░  ▒ ░
//   ░      ░    ░░░ ░ ░ ░  ░  ░   ░░░ ░ ░  ░    ░  ▒ ░
//         ░      ░           ░     ░      ░       ░
//                                               ░
//  *
//  */

interface IChallengeRegistry {
    function isChallengeValid(uint idx) external view returns (bool);

    function setBindedWithEvent(uint idx) external;

    function isBindedWithEvent(uint idx) external view returns (bool);

    function verifyChallenge(address user, uint challengeIdx) external;

    function isChallengePassed(
        address user,
        uint challengeIdx
    ) external view returns (bool);
}
