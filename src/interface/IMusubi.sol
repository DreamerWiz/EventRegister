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

enum UserChallengeStatus {
    None,
    Ongoing,
    Finished
}

enum ChallengsStatus {
    None,
    InUse,
    Banned
}

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

struct UserEventInfo {
    UserEventStatus status;
    // bool[] rewarded;
    uint[][] rewardValues;
}

struct RewardInfo {
    uint[] values;
    RewardTokenDetailInfo[] rewards;
    RewardStrategy strategy;
}

struct RewardTokenDetailInfo {
    uint tokenSize;
    address[] tokens;
    uint[] tokenIds;
    uint[] tokenAmounts;
    uint[] tokenFloats;
    uint[] tokanProbabilities;
}

struct UserEffectInfo {
    uint passNo;
}

struct CollectionInfo {
    uint[] events;
}

struct ChallengeInfo {
    address contributor;
    //@TODO interface
    address challengeFactory;
    ChallengsStatus status;
    uint passCount;
    address firstResolver;
    uint firstResolveTimestamp;
    uint startTime;
    //@dev if one to one relation
    bool ifBindedWithEvent;
    // rewards for completing the challenge
    RewardTokenDetailInfo[] rewards;
}

struct UserChallengeInfo {
    address challenge;
    UserChallengeStatus status;
    bool rewarded;
}

interface IMusubi {
    // errors
    error UserChallengeAlreadyOngoing(uint challengeId, address msgSender);
    error UserChallengeHaveFinished(uint challengeId, address msgSender);
    error UserChallengeVerifiyFailed(uint challengeId, address msgSender);

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
}
