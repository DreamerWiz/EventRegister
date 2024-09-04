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
 * @dev This contract ought not to be changed any more.
 * It is the most basic part and should not be extended
 * after first edition.
 * 
 */

import {IAgent, TokenType} from "./interface/IAgent.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/interfaces/IERC1155.sol";
import {IMusubiBadge} from "./interface/IMusubiBadge.sol";
import {IChallengeFactory, IChallenge} from "./interface/IChallenge.sol";

enum ChallengeStatus {
    None,
    InUse,
    Banned
}

enum UserChallengeStatus {
    None,
    Ongoing,
    Finished
}

enum ChallengeRewardStrategy {
    RankOnce,
    TimeLimitOnce,
    CompleteOnce
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

struct ChallengeReward {
    ChallengeRewardStrategy strategy;
    uint[] values;
    RewardTokenDetailInfo[] rewards;
}

struct ChallengeInfo {
    address contributor;
    //@TODO interface
    address challengeFactory;
    ChallengeStatus status;
    uint passCount;
    uint participantCount;
    address firstResolver;
    uint firstResolveTimestamp;
    uint startTime;
    uint prepareValue;
    //@dev if one to one relation
    bool ifBindedWithEvent;
    // rewards for completing the challenge

    ChallengeReward[] rewards;
}

struct UserRewardRecord {
    uint[] values;
    ChallengeRewardStrategy strategy;
    uint startTime;
}

struct UserChallengeInfo {
    address challenge;
    UserChallengeStatus status;
    uint rank;
    uint timeCost;
    uint startTime;
    UserRewardRecord[] rewardRecords;
}

contract Challenge {
    IAgent private _agent;

    uint private _counter = 1;
    mapping(uint => ChallengeInfo) private _challenges;
    mapping(address => uint) private _challengeIdx;

    mapping(address => mapping(uint => address)) _userChallengeAddress;

    mapping(address => mapping(uint => UserChallengeInfo)) _userChallenge;

    error DuplicateChallengeFactory(address challengeFactory);
    error ChallengePrepareFeeNotReceived();
    error UnknownChallengeAddress(address challengeFactory);
    error ChallengeInvalid(uint challengeIdx);
    error UserChallengeStatusInvalid(UserChallengeStatus wrongStatus);
    error UserChallengeVerifyFailed();
    error ChallengeStatusInvalid(ChallengeStatus status, uint challengeIdx);
    error ValuesMustInIncresingOrder();
    error RewardTokenDetailTokensLengthNotEqualTokenSize(uint rewardIdx);
    error RewardTokenDetailTokenDatasLengthNotEqualTokenSize(uint rewardIdx);
    error RewardTokenDetailTokenIdsLengthNotEqualTokenSize(uint rewardIdx);
    error RewardTokenDetailTokenAmountsLengthNotEqualTokenSize(uint rewardIdx);
    error RewardTokenDetailTokenFloatsLengthNotEqualTokenSize(uint rewardIdx);
    error RewardTokenDetailTokenProbabilitesLengthNotEqualTokenSize(
        uint rewardIdx
    );
    error RewardToeknDetailNotSupportedToken(address token);

    event AddChallenge(address challengeFactory);
    event BanChallenge(uint challengeIdx);
    event GenerateChallenge(address user, uint challengeIdx);
    event VerifyChallenge(address user, uint challengeIdx);

    modifier onlyAllowed() {
        _agent.isChallengeManager(msg.sender);
        _;
    }

    constructor(address agent) {
        _agent = IAgent(agent);
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

    // challenge management
    function addChallenge(
        address contributor,
        address challengeFactory,
        uint prepareValue,
        ChallengeReward[] calldata rewards
    ) external onlyAllowed {
        if (_challengeIdx[challengeFactory] > 0) {
            // the challenge has been added
            revert DuplicateChallengeFactory(challengeFactory);
        }
        ChallengeInfo storage challenge = _challenges[_counter];
        challenge.challengeFactory = challengeFactory;
        challenge.contributor = contributor;
        challenge.status = ChallengeStatus.InUse;
        challenge.passCount = 0;
        challenge.startTime = block.timestamp;
        challenge.participantCount = 0;
        challenge.prepareValue = prepareValue; // user pays eth to start the challenge
        challenge.ifBindedWithEvent = false;
        // challenge.rewards = rewards;

        for (uint i = 0; i < rewards.length; i++) {
            ChallengeReward calldata cr = rewards[i];

            if (
                cr.strategy == ChallengeRewardStrategy.RankOnce ||
                cr.strategy == ChallengeRewardStrategy.TimeLimitOnce
            ) {
                // Check if the values are in in creasing order
                for (uint j = 1; j < cr.values.length; j++) {
                    if (cr.values[j] <= cr.values[j - 1]) {
                        revert ValuesMustInIncresingOrder();
                    }
                }

                // No checks if it is complete once strategy
            }

            //Check if the rewards are valid
            for (
                uint rewardIdx = 0;
                rewardIdx < cr.rewards.length;
                rewardIdx++
            ) {
                RewardTokenDetailInfo calldata rtd = cr.rewards[rewardIdx];
                uint tokenSize = rtd.tokenSize;
                if (rtd.tokens.length != tokenSize) {
                    revert RewardTokenDetailTokensLengthNotEqualTokenSize(
                        rewardIdx
                    );
                }
                if (rtd.tokenDatas.length != tokenSize) {
                    revert RewardTokenDetailTokenDatasLengthNotEqualTokenSize(
                        rewardIdx
                    );
                }
                if (rtd.tokenIds.length != tokenSize) {
                    revert RewardTokenDetailTokenIdsLengthNotEqualTokenSize(
                        rewardIdx
                    );
                }
                if (rtd.tokenAmounts.length != tokenSize) {
                    revert RewardTokenDetailTokenAmountsLengthNotEqualTokenSize(
                        rewardIdx
                    );
                }
                if (rtd.tokenFloats.length != tokenSize) {
                    revert RewardTokenDetailTokenFloatsLengthNotEqualTokenSize(
                        rewardIdx
                    );
                }
                if (rtd.tokenProbabilities.length != tokenSize) {
                    revert RewardTokenDetailTokenProbabilitesLengthNotEqualTokenSize(
                        rewardIdx
                    );
                }

                for (
                    uint tokenIdx = 0;
                    tokenIdx < rtd.tokens.length;
                    tokenIdx++
                ) {
                    TokenType typ = _agent.getTokenType(rtd.tokens[tokenIdx]);
                    if (typ == TokenType.None) {
                        revert RewardToeknDetailNotSupportedToken(
                            rtd.tokens[tokenIdx]
                        );
                    }
                }
            }

            challenge.rewards.push(cr);
        }

        // challenge.rewards = rewards;
        _challengeIdx[challengeFactory] = _counter;
        _counter++;
        // _challenges.push(challenge);
        // _challengeIdx[challengeFactory] = _challenges.length;
        emit AddChallenge(challengeFactory);
    }

    function banChallengeByAddress(address challenge) external {
        if (_challengeIdx[challenge] == 0) {
            revert UnknownChallengeAddress(challenge);
        }

        uint idx = _challengeIdx[challenge] - 1;
        banChallengeByIndex(idx);
    }

    function banChallengeByIndex(uint challengeIdx) public onlyAllowed {
        if (challengeIdx >= _counter) {
            revert ChallengeInvalid(challengeIdx);
        }

        ChallengeInfo storage challengeInfo = _challenges[challengeIdx];
        challengeInfo.status = ChallengeStatus.Banned;
        emit BanChallenge(challengeIdx);
    }

    function generateChallengeByAddress(
        address user,
        address challenge
    ) external {
        if (_challengeIdx[challenge] == 0) {
            revert UnknownChallengeAddress(challenge);
        }
        uint idx = _challengeIdx[challenge] - 1;
        generateChallenge(user, idx);
    }

    function generateChallenge(
        address user,
        uint challengeIdx
    ) public payable onlyAllowed {
        if (challengeIdx >= _counter) {
            revert ChallengeInvalid(challengeIdx);
        }

        ChallengeInfo storage c = _challenges[challengeIdx];

        if (msg.value != c.prepareValue) {
            revert ChallengePrepareFeeNotReceived();
        }

        if (c.status == ChallengeStatus.Banned) {
            revert ChallengeStatusInvalid(c.status, challengeIdx);
        }

        UserChallengeInfo storage uc = _userChallenge[user][challengeIdx];

        if (uc.status != UserChallengeStatus.None) {
            revert UserChallengeStatusInvalid(uc.status);
        }

        uc.challenge = IChallengeFactory(c.challengeFactory).prepare{
            value: c.prepareValue
        }(user);

        c.participantCount++;
        uc.status = UserChallengeStatus.Ongoing;
        uc.startTime = block.timestamp;

        // initiate user reaward records
        for (uint i = 0; i < c.rewards.length; i++) {
            ChallengeReward storage cr = c.rewards[i];
            // UserRewardRecord storage urr = uc.rewardRecords[i];
            // urr.strategy = cr.strategy;
            UserRewardRecord memory urr;
            urr.strategy = cr.strategy;
            urr.values = new uint[](cr.values.length);
            for (uint j = 0; j < cr.values.length; j++) {
                urr.values[j] = 0;
            }
            urr.startTime = block.timestamp;
            uc.rewardRecords.push(urr);
        }

        emit GenerateChallenge(user, challengeIdx);
    }

    function verifyChallengeByAddress(
        address user,
        address challenge
    ) external {
        if (_challengeIdx[challenge] == 0) {
            revert UnknownChallengeAddress(challenge);
        }
        uint idx = _challengeIdx[challenge] - 1;

        verifyChallenge(user, idx);
    }

    function verifyChallenge(
        address user,
        uint challengeIdx
    ) public onlyAllowed {
        if (challengeIdx >= _counter) {
            revert ChallengeInvalid(challengeIdx);
        }

        ChallengeInfo storage c = _challenges[challengeIdx];

        UserChallengeInfo storage uc = _userChallenge[user][challengeIdx];

        if (uc.status != UserChallengeStatus.Ongoing) {
            revert UserChallengeStatusInvalid(uc.status);
        }

        bool res = IChallenge(uc.challenge).isPassed();

        if (!res) {
            revert UserChallengeVerifyFailed();
        }

        uc.status = UserChallengeStatus.Finished;
        uc.rank = c.passCount + 1;
        uc.timeCost = block.timestamp - c.startTime;
        // cannot use uc.startTime because user can complete the challenge in one single tx.
        c.passCount++;

        if (c.firstResolver == address(0)) {
            c.firstResolver = user;
            c.firstResolveTimestamp = block.timestamp;
        }

        emit VerifyChallenge(user, challengeIdx);
    }

    function claimChallengeRewardByAddress(
        address user,
        address challenge
    ) external {
        if (_challengeIdx[challenge] == 0) {
            revert UnknownChallengeAddress(challenge);
        }
        uint idx = _challengeIdx[challenge] - 1;

        claimChallengeReward(user, idx);
    }

    function claimChallengeReward(
        address user,
        uint challengeIdx
    ) public onlyAllowed {
        if (challengeIdx >= _counter) {
            revert ChallengeInvalid(challengeIdx);
        }

        ChallengeInfo storage c = _challenges[challengeIdx];

        UserChallengeInfo storage uc = _userChallenge[user][challengeIdx];

        if (uc.status != UserChallengeStatus.Finished) {
            revert UserChallengeStatusInvalid(uc.status);
        }

        UserRewardRecord[] storage urr = uc.rewardRecords;
        for (uint i = 0; i < urr.length; i++) {
            ChallengeRewardStrategy strategy = urr[i].strategy;

            if (strategy == ChallengeRewardStrategy.RankOnce) {
                for (
                    uint findIdx = 0;
                    findIdx <= urr[i].values.length;
                    findIdx++
                ) {
                    if (urr[i].values[findIdx] == 1) {
                        break;
                    }
                    urr[i].values[findIdx] = 1;
                    if (uc.rank <= c.rewards[i].values[i]) {
                        _sendReward(user, c.rewards[i].rewards);
                    }
                }
            }

            if (strategy == ChallengeRewardStrategy.TimeLimitOnce) {
                for (
                    uint findIdx = 0;
                    findIdx <= urr[i].values.length;
                    findIdx++
                ) {
                    if (urr[i].values[findIdx] == 1) {
                        break;
                    }
                    urr[i].values[findIdx] = 1;
                    if (uc.timeCost <= c.rewards[i].values[i]) {
                        _sendReward(user, c.rewards[i].rewards);
                    }
                }
            }

            if (strategy == ChallengeRewardStrategy.CompleteOnce) {
                for (
                    uint findIdx = 0;
                    findIdx <= urr[i].values.length;
                    findIdx++
                ) {
                    if (urr[i].values[findIdx] == 1) {
                        break;
                    }
                    urr[i].values[findIdx] = 1;
                    _sendReward(user, c.rewards[i].rewards);
                }
            }
        }
    }

    function getUserChallengeInfo(
        uint challengeIdx,
        address user
    ) public view returns (UserChallengeInfo memory info) {
        info = _userChallenge[user][challengeIdx];
        if (msg.sender != user) {
            info.challenge = address(0);
        }
    }

    function getChallengeInfo(
        uint challengeIdx
    ) public view returns (ChallengeInfo memory info) {
        info = _challenges[challengeIdx];
    }

    function getChallengeCount() public view returns (uint) {
        return _counter;
    }

    function isChallengeValid(uint idx) external view returns (bool) {
        return _challenges[idx].status == ChallengeStatus.InUse;
    }

    function isBindedWithEvent(uint idx) external view returns (bool) {
        return _challenges[idx].ifBindedWithEvent;
    }

    function isChallengePassed(
        address user,
        uint challengeIdx
    ) external view returns (bool) {
        UserChallengeInfo memory uc = _userChallenge[user][challengeIdx];
        return uc.status == UserChallengeStatus.Finished;
    }

    function setBindedWithEvent(uint idx) external onlyAllowed {
        ChallengeInfo storage c = _challenges[idx];
        c.ifBindedWithEvent = true;
        c.startTime = block.timestamp;
    }
}
