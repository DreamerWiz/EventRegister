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
//  * @dev This is the main contract to manage challenges
//  * events and issue rewards for outstanding users.
//  *
//  * Challenge:
//  * 1. AddChallenge, only manager can add challenge into
//  * the pool.
//  * 2. BanChallenge, avoid marlicious challenges.
//  */

import {IAgent} from "./interface/IAgent.sol";
import {ChallengeInfo} from "./Challenge.sol";
import {IChallengeRegistry} from "./interface/IChallengeRegistry.sol";
import {TokenType} from "./interface/IAgent.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/interfaces/IERC1155.sol";
import {IMusubiBadge} from "./interface/IMusubiBadge.sol";

enum RewardStrategy {
    Single, //Each challenge pass can get rewards
    Count, // [1,3,5,7,9] can repeatly claim
    CountOnce, // [9, 7, 5, 3, 1] can only claim once. Should in desc order
    TimeLimitOnce, // [300, 600, 900, 1200, 1800, 3600] claim only once.
    RankOnce //[1, 10, 100, 666] claim only once
}

enum EventStatus {
    None,
    InUse,
    Banned
}

enum UserEventStatus {
    None,
    Ongoing,
    Finished
}

struct UserEventInfo {
    UserEventStatus status;
    // bool[] rewarded;
    UserRewardRecord[] rewardRecords;
    uint startTime;
    uint passCount;
    uint finishTime;
    uint rank;
}

struct UserRewardRecord {
    uint[] values;
    RewardStrategy strategy;
}

struct RewardInfo {
    uint[] values;
    RewardTokenDetailInfo[][] rewards;
    RewardStrategy strategy;
}

struct RewardTokenDetailInfo {
    uint tokenSize;
    address[] tokens; //token list  [usdt, usdt]   [25]
    bytes[] tokenDatas;
    uint[] tokenIds; // id
    uint[] tokenAmounts; // amount   [25e18, ]  25-30
    uint[] tokenFloats; // float   5e18    uint(keccak256(abiencode(msg.sender, block.number))) % float  0-5
    uint[] tokenProbabilities; //  []
}

struct EventInfo {
    uint[] challenges;
    uint startTime;
    uint endTime;
    bytes32 description;
    bytes32 name;
    // statistics
    uint participantNumber;
    uint passNumber;
    // rewards
    RewardInfo[] rewardConditions;
    // status
    EventStatus status;
}

contract Event {
    // errors
    error UserChallengeAlreadyOngoing(uint challengeId, address msgSender);
    error UserChallengeHaveFinished(uint challengeId, address msgSender);
    error UserChallengeVerifiyFailed(uint challengeId, address msgSender);
    error UserEventStatusError(UserEventStatus status);

    error OnlyManagerAllowed(address msgSender);
    error OnlyWhitelistedTokenSupported(address errorToken);

    error ChallengeInvalid(uint idx);
    error ChallengeBinded(uint idx);
    error ChallengeBanned(uint idx);

    error EventStatusInvalid(uint idx);

    error DuplicateChallengeFactory(address factory);
    error UnknownChallengeAddress(address factory);

    error EmptyChallengesArray();
    error EndTimeBePastTime();

    error VerifyFailed();

    error RewardDetailLengthNotMatchValues();

    error RewardDetailTokensLengthNotMatch();
    error RewardDetailTokenIdsLengthNotMatch();
    error RewardDetailTokenAmountsLengthNotMatch();
    error RewardDetailTokenFloatsLengthNotMatch();
    error RewardDetailTokenProbabilitiessLengthNotMatch();

    error RewardTokenNotSupported(address token);
    error SingleNotCoverAllChallenges();

    error EventIndexInvalid(uint eventIdx);
    error EventEnded(uint eventIdx);
    error EventChallengeIndexInvalid(uint eventId, uint eventChallengeIndex);

    error UserEventOngoingOrFinished(uint eventId);
    error UserEventNotOngoing();

    error UserChallengeNotOngoing();
    error UserChallengeNotCreated();
    error UserChallengeExist();

    // challenges
    event UserChallengePassed(uint challengeId, address msgSender);
    event AddChallenge(address indexed challegneAddress);
    event BanChallengeByAddress(address indexed challengeAddress);
    event BanChallengeByIndex(uint indexed challengeIdx);

    // events
    event AddEvent(uint eventIdx);
    event BanEvent(uint eventIdx);

    event SignUpEvent(uint eventIdx, address indexed user);

    // @TODO determine privacy
    event Verified(address user, uint challengeId);

    event ResolveChallenge(address user, uint eventId, uint challengeIdx);
    address private _agent;
    address private _challenge;

    uint private _eventCounter;
    mapping(uint => EventInfo) private _events;

    mapping(address => mapping(uint => UserEventInfo)) private _userEvent;

    constructor(address agent, address challenge) {
        _agent = agent;
        _challenge = challenge;
    }

    modifier onlyManager() {
        if (!IAgent(_agent).isOperator(msg.sender))
            revert OnlyManagerAllowed(msg.sender);
        _;
    }

    function _isWhitelistedToken(address token) internal view returns (bool) {
        return IAgent(_agent).getTokenType(token) != TokenType.None;
    }

    function _sendReward(
        address user,
        RewardTokenDetailInfo[] memory rewards
    ) internal {
        for (uint i = 0; i < rewards.length; i++) {
            uint tokenSize = rewards[i].tokenSize;
            for (uint j = 0; j < tokenSize; j++) {
                address token = rewards[i].tokens[j];
                TokenType typ = IAgent(_agent).getTokenType(token);
                uint tokenId = rewards[i].tokenIds[j];
                bytes memory data = rewards[i].tokenDatas[j];
                uint amount = rewards[i].tokenAmounts[j];
                uint probability = rewards[i].tokenProbabilities[j];
                uint float = rewards[i].tokenFloats[j];
                uint _amount = amount;

                if (float != 0) {
                    _amount +=
                        uint(
                            bytes32(
                                keccak256(
                                    abi.encode(msg.sender, block.timestamp, 1)
                                )
                            )
                        ) %
                        float;
                }
                if (probability != 0) {
                    if (
                        uint(
                            bytes32(
                                keccak256(
                                    abi.encode(msg.sender, block.timestamp, 2)
                                )
                            )
                        ) %
                            1e5 >
                        probability
                    ) {
                        _amount = 0;
                    }
                }
                if (_amount == 0) {
                    continue;
                }
                if (typ == TokenType.ERC20) {
                    IERC20(token).transfer(user, amount);
                }
                //@TODO tokenId redundant
                if (typ == TokenType.ERC721) {
                    IERC721(token).transferFrom(address(this), user, tokenId);
                }
                if (typ == TokenType.ERC1155) {
                    IERC1155(token).safeTransferFrom(
                        address(this),
                        user,
                        tokenId,
                        _amount,
                        data
                    );
                }
                if (typ == TokenType.MusubiBadge) {
                    IMusubiBadge(token).mint(user, data);
                }
            }
        }
    }

    // event management
    function addEvent(
        uint[] calldata challengeIndexes,
        uint startTime,
        uint endTime,
        string calldata detailLink,
        bool ifAllChallengeInitial,
        RewardInfo[] calldata rewardConditions
    ) external onlyManager {
        if (startTime == 0) {
            startTime = block.timestamp;
        }

        if (endTime != 0 && endTime <= startTime) {
            revert EndTimeBePastTime();
        }

        // 1. Check if index exceed bound
        // 2. Check if the challenge has been added
        // 3. Check if the challenge is banned
        for (uint i = 0; i < challengeIndexes.length; i++) {
            uint idx = challengeIndexes[i];

            if (!IChallengeRegistry(_challenge).isChallengeValid(idx)) {
                revert ChallengeInvalid(idx);
            }

            if (ifAllChallengeInitial) {
                if (IChallengeRegistry(_challenge).isBindedWithEvent(idx)) {
                    revert ChallengeBinded(idx);
                }
            }

            // Once added into an event, ifBindedWithEvent is set true, and
            // its start time aligns with the event
            if (!IChallengeRegistry(_challenge).isBindedWithEvent(idx)) {
                IChallengeRegistry(_challenge).setBindedWithEvent(idx);
            }
        }

        EventInfo storage _event = _events[++_eventCounter];
        // 4. Check reward conditions
        for (uint i = 0; i < rewardConditions.length; i++) {
            RewardInfo calldata rewardCondition = rewardConditions[i];

            for (uint k = 0; k < rewardCondition.rewards.length; k++) {
                RewardTokenDetailInfo[] calldata rewardDetail = rewardCondition
                    .rewards[k];

                if (rewardDetail.length != rewardCondition.values.length) {
                    revert RewardDetailLengthNotMatchValues();
                }

                for (uint j = 0; j < rewardDetail.length; j++) {
                    RewardTokenDetailInfo calldata info = rewardDetail[j];
                    if (info.tokens.length != info.tokenSize) {
                        revert RewardDetailTokensLengthNotMatch();
                    }
                    if (info.tokenIds.length != info.tokenSize) {
                        revert RewardDetailTokenIdsLengthNotMatch();
                    }
                    if (info.tokenAmounts.length != info.tokenSize) {
                        revert RewardDetailTokenAmountsLengthNotMatch();
                    }
                    if (info.tokenFloats.length != info.tokenSize) {
                        revert RewardDetailTokenFloatsLengthNotMatch();
                    }
                    if (info.tokenProbabilities.length != info.tokenSize) {
                        revert RewardDetailTokenProbabilitiessLengthNotMatch();
                    }

                    for (
                        uint tokenIdx = 0;
                        tokenIdx < info.tokens.length;
                        tokenIdx++
                    ) {
                        if (!_isWhitelistedToken(info.tokens[tokenIdx])) {
                            revert RewardTokenNotSupported(
                                info.tokens[tokenIdx]
                            );
                        }
                    }
                }
            }

            if (rewardCondition.strategy == RewardStrategy.Single) {
                if (rewardCondition.values.length != challengeIndexes.length) {
                    revert SingleNotCoverAllChallenges();
                }

                // values only 0 or 1, 0 represent none 1 represents there is reward for this one.
            }

            _event.rewardConditions.push(rewardCondition);
        }

        _event.challenges = challengeIndexes;
        _event.startTime = block.timestamp;
        _event.endTime = endTime;

        _event.status = EventStatus.InUse;
        emit AddEvent(_eventCounter);
    }

    function startEvent(uint eventIdx) external {
        if (eventIdx > _eventCounter || _eventCounter == 0) {
            revert EventIndexInvalid(eventIdx);
        }

        UserEventInfo storage ue = _userEvent[msg.sender][eventIdx];

        EventInfo storage e = _events[eventIdx];

        if (e.status != EventStatus.InUse) {
            revert EventStatusInvalid(eventIdx);
        }

        if (ue.status != UserEventStatus.None) {
            revert UserEventOngoingOrFinished(eventIdx);
        }

        ue.status = UserEventStatus.Ongoing;
        ue.startTime = block.timestamp;

        // Initialize all the rewards

        for (uint i = 0; i < e.rewardConditions.length; i++) {
            RewardInfo storage rc = e.rewardConditions[i];
            UserRewardRecord storage urr = ue.rewardRecords[i];

            urr.strategy = rc.strategy;

            uint[] memory _values = new uint[](rc.values.length);

            urr.values = _values;

            if (rc.strategy == RewardStrategy.Single) {
                for (
                    uint challengeArrayIdx;
                    challengeArrayIdx < e.challenges.length;
                    challengeArrayIdx++
                ) {
                    uint challengeIdx = e.challenges[challengeArrayIdx];
                    if (
                        IChallengeRegistry(_challenge).isChallengePassed(
                            msg.sender,
                            challengeIdx
                        )
                    ) {
                        // Marked as claimed ?
                        urr.values[challengeIdx] = 1;
                    }
                }
            }
        }
    }

    function banEvent(uint eventIdx) external onlyManager {
        if (eventIdx > _eventCounter || _eventCounter == 0) {
            revert EventIndexInvalid(eventIdx);
        }
        EventInfo storage info = _events[eventIdx];
        info.status = EventStatus.Banned;
        emit BanEvent(eventIdx);
    }

    function verifyChallenge(uint eventIdx, uint challengeIdx) external {
        if (eventIdx > _eventCounter || _eventCounter == 0) {
            revert EventIndexInvalid(eventIdx);
        }

        EventInfo storage e = _events[eventIdx];

        if (e.endTime != 0 && block.timestamp > e.endTime) {
            revert EventEnded(eventIdx);
        }

        UserEventInfo storage ue = _userEvent[msg.sender][eventIdx];

        if (ue.status != UserEventStatus.Ongoing) {
            revert UserEventStatusError(ue.status);
        }

        IChallengeRegistry(_challenge).verifyChallenge(
            msg.sender,
            challengeIdx
        );

        ue.passCount += 1;

        if (ue.passCount == e.challenges.length) {
            // All complete

            ue.finishTime = block.timestamp;

            e.passNumber += 1;
            ue.rank = e.passNumber;
        }
    }

    function claimRewards(uint eventIdx) external {
        if (eventIdx > _eventCounter || _eventCounter == 0) {
            revert EventIndexInvalid(eventIdx);
        }

        EventInfo storage e = _events[eventIdx];

        UserEventInfo storage ue = _userEvent[msg.sender][eventIdx];

        for (uint i = 0; i < e.rewardConditions.length; i++) {
            RewardInfo storage rc = e.rewardConditions[i];

            if (rc.strategy == RewardStrategy.Single) {
                for (uint j = 0; j < rc.values.length; j++) {
                    if (rc.values[j] == 1) continue;
                    uint challengeIdx = rc.values[j]; //rc.values store indexes
                    if (
                        IChallengeRegistry(_challenge).isChallengePassed(
                            msg.sender,
                            challengeIdx
                        )
                    ) {
                        _sendReward(msg.sender, rc.rewards[j]);
                    }
                    rc.values[j] = 1;
                }
            }

            if (rc.strategy == RewardStrategy.Count) {
                for (uint j = 0; j < rc.values.length; j++) {
                    if (rc.values[j] == 1) continue;
                    uint countRequirement = rc.values[j];
                    if (ue.passCount >= countRequirement) {
                        _sendReward(msg.sender, rc.rewards[j]);
                    } else {
                        break;
                    }
                    rc.values[j] = 1;
                }
            }

            if (rc.strategy == RewardStrategy.CountOnce) {
                if (rc.values[0] == 1) break;
                for (
                    uint targetIdx;
                    targetIdx < rc.values.length;
                    targetIdx++
                ) {
                    rc.values[targetIdx] = 1;
                    if (rc.values[targetIdx] <= ue.passCount) {
                        _sendReward(msg.sender, rc.rewards[targetIdx]);
                        break;
                    }
                }
            }

            if (rc.strategy == RewardStrategy.TimeLimitOnce) {
                if (rc.values[0] == 1) break;
                for (
                    uint targetIdx;
                    targetIdx < rc.values.length;
                    targetIdx++
                ) {
                    rc.values[targetIdx] = 1;
                    if (rc.values[targetIdx] >= ue.finishTime - ue.startTime) {
                        _sendReward(msg.sender, rc.rewards[targetIdx]);
                        break;
                    }
                }
            }

            if (rc.strategy == RewardStrategy.RankOnce) {
                if (rc.values[0] == 1) break;
                for (
                    uint targetIdx;
                    targetIdx < rc.values.length;
                    targetIdx++
                ) {
                    rc.values[targetIdx] = 1;
                    if (rc.values[targetIdx] >= ue.rank) {
                        _sendReward(msg.sender, rc.rewards[targetIdx]);
                        break;
                    }
                }
            }
        }
    }
}
