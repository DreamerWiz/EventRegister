// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Interface for challenges
interface IChallenge {
    function initialize() external returns (address);
    function getSeed() external returns (bytes32);
    function verify(bytes32 seed) external returns (bool);
}

interface IEventsRegister {
    // Define the Event struct and other necessary structs here
    struct Reward {
        address token;
        RewardType rewardType;
        uint256 rewardAmount; // for prize money
        uint256 rewardId; // for NFT id
        uint256 rewardRemaining;
    }

    struct Challenge {
        IChallenge challenge;
        uint registeredTimestamp;
        uint firstSolvedTimestamp;
        Reward[] rewards;
    }

    struct Event {
        uint256 startTime;
        uint256 endTime;
        Challenge[] challenges;
        Reward[] rewards;
    }
    enum RewardType {
        ERC20,
        ERC721,
        ERC1155,
        ERC20Mint,
        ERC721Mint,
        ERC1155Mint
    }
    // Define the necessary events
    event EventRegistered(uint256 indexed eventId, address indexed creator);
    event ChallengeSolved(
        uint256 indexed eventId,
        uint256 indexed challengeIndex,
        address indexed solver,
        uint256 timestamp
    );    
    event AllChallengesInEventSolved(
        uint256 indexed eventId,
        address indexed solver,
        uint256 timestamp
    );
    event RewardSent(
        uint256 indexed eventId,
        address indexed token,
        RewardType rewardType,
        uint256 rewardId,
        uint256 rewardAmount
    );
    event ChallengeInitialized(
        uint256 indexed eventId,
        address indexed sender,
        uint256 challengeIndex,
        address implAddress
    );

    // Function to add events
    function registerEvents(Event memory eventDetail) external;

    // Function for participants to solve challenges
    function solveEvent(uint256 eventId) external;
}
