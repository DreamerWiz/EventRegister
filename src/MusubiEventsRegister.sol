// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import "./IEventsRegister.sol";
import "./IERC.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract MusubiEventsRegister is
    IEventsRegister,
    Ownable,
    ERC721Holder,
    ERC1155Holder
{
    uint32 public eventsTotal = 0;
    // Mapping for whitelist
    mapping(address => bool) private whitelist;

    // Mapping for events
    mapping(uint256 => Event) public events;
    mapping(address => Challenge) public challenges;
    mapping(address => mapping(address => bool))
        public isChallengeSolvedByAddress; // challengeAddress => solver => isSolved
    mapping(uint256 => mapping(address => bool))
        public isEventAllSolvedByAddress; // EventId => solver => isSolved

    constructor() Ownable(msg.sender) {}

    // Modifier to check whitelist status
    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], "NotWhitelisted()");
        _;
    }

    function isWhitelisted(address user) external view returns (bool) {
        return whitelist[user];
    }

    // Function to add to whitelist
    function addToWhitelist(address user) external onlyOwner {
        whitelist[user] = true;
    }

    function getEventDetail(
        uint256 eventId
    ) external view returns (Event memory) {
        return events[eventId];
    }

    function registerEvents(
        Event calldata eventDetail
    ) external override onlyWhitelisted {
        require(eventDetail.challenges.length < 10);
        uint256 _eventId = ++eventsTotal;
        events[_eventId] = eventDetail;
        _collectRewards(_eventId, eventDetail.rewards);
        for (uint256 i = 0; i < eventDetail.challenges.length; i++) {
            address _challengeAddress = address(
                eventDetail.challenges[i].challenge
            );
            challenges[_challengeAddress] = eventDetail.challenges[i];
            challenges[_challengeAddress].registeredTimestamp = block.timestamp;
            _collectRewards(
                _eventId,
                challenges[_challengeAddress].rewards
            );
        }
        emit EventRegistered(_eventId, msg.sender);
    }

    function createChallengeImpl(
        uint256 eventId,
        uint256 challengeIndex
    ) external {
        IChallenge _challenge = events[eventId]
            .challenges[challengeIndex]
            .challenge;
        address implAddress = _challenge.initialize();
        emit ChallengeInitialized(
            eventId,
            msg.sender,
            challengeIndex,
            implAddress
        );
    }

    function _sendRewards(
        uint256 eventId,
        Reward[] storage rewards,
        address recipient
    ) internal {
        for (uint256 i = 0; i < rewards.length; i++) {
            Reward storage reward = rewards[i];
            bool sent;
            if (reward.rewardRemaining < 1) {
                continue;
            } else if (reward.rewardType == RewardType.ERC20) {
                sent = IERC20Token(reward.token).transfer(
                    recipient,
                    reward.rewardAmount
                );
            } else if (reward.rewardType == RewardType.ERC721) {
                IERC721Token(reward.token).safeTransferFrom(
                    address(this),
                    recipient,
                    reward.rewardId
                );
                sent = true;
            } else if (reward.rewardType == RewardType.ERC1155) {
                IERC1155Token(reward.token).safeTransferFrom(
                    address(this),
                    recipient,
                    reward.rewardId,
                    reward.rewardAmount,
                    ""
                );
                sent = true;
            } else if (reward.rewardType == RewardType.ERC20Mint) {
                IERC20Token(reward.token).mint(recipient, reward.rewardAmount);
                sent = true;
            } else if (reward.rewardType == RewardType.ERC721Mint) {
                IERC721Token(reward.token).mint(recipient);
                sent = true;
            } else if (reward.rewardType == RewardType.ERC1155Mint) {
                IERC1155Token(reward.token).mint(
                    recipient,
                    reward.rewardId,
                    reward.rewardAmount
                );
                sent = true;
            }
            require(sent, "SendRewardFailed()");
            reward.rewardRemaining -= 1;
            emit RewardSent(
                eventId,
                reward.token,
                reward.rewardType,
                reward.rewardId,
                reward.rewardAmount
            );
        }
    }

    function _collectRewards(
        uint256 eventId,
        Reward[] memory rewards
    ) internal {
        for (uint256 i = 0; i < rewards.length; i++) {
            Reward memory reward = rewards[i];
            bool sent;
            if (reward.rewardType == RewardType.ERC20) {
                sent = IERC20Token(reward.token).transferFrom(
                    msg.sender,
                    address(this),
                    reward.rewardAmount * reward.rewardRemaining
                );
                require(sent, "CollectERC20RewardFailed()");
            } else if (reward.rewardType == RewardType.ERC721) {
                require(reward.rewardRemaining == 1, "ERC721RewardRemainingMustBeOne()");
                IERC721Token(reward.token).safeTransferFrom(
                    msg.sender,
                    address(this),
                    reward.rewardId
                );
                sent = true;
                require(sent, "CollectERC721RewardFailed()");
            } else if (reward.rewardType == RewardType.ERC1155) {
                IERC1155Token(reward.token).safeTransferFrom(
                    msg.sender,
                    address(this),
                    reward.rewardId,
                    reward.rewardAmount * reward.rewardRemaining,
                    ""
                );
                sent = true;
                require(sent, "CollectERC1155RewardFailed()");
            }
        }
    }


    function solveEvent(uint256 eventId) external override {
        require(
            !isEventAllSolvedByAddress[eventId][msg.sender],
            "AllChallengesSolvedInEvent()"
        );
        bool isAllSolved = true;
        for (uint256 i = 0; i < events[eventId].challenges.length; i++) {
            bool isSolved;
            address _challengeAddress = address(
                events[eventId].challenges[i].challenge
            );
            if (isChallengeSolvedByAddress[_challengeAddress][msg.sender]) {
                isSolved = true;
            } else {
                // verify answer
                bytes32 seed = challenges[_challengeAddress]
                    .challenge
                    .getSeed();
                isSolved = challenges[_challengeAddress].challenge.verify(seed);
                if (isSolved) {
                    // Save the first solved timestamp
                    if (
                        challenges[_challengeAddress].firstSolvedTimestamp == 0
                    ) {
                        // Save timestamp of first blood
                        challenges[_challengeAddress]
                            .firstSolvedTimestamp = block.timestamp;
                        // Send challenge reward of first blood
                        _sendRewards(
                            eventId,
                            challenges[_challengeAddress].rewards,
                            msg.sender
                        );
                    }

                    // Save challengeSolved by address
                    isChallengeSolvedByAddress[_challengeAddress][
                        msg.sender
                    ] = true;
                    emit ChallengeSolved(
                        eventId,
                        i,
                        msg.sender,
                        block.timestamp
                    );
                }
            }
            isAllSolved = isAllSolved || isSolved;
        }
        if (isAllSolved) {
            // Send Event reward
            isEventAllSolvedByAddress[eventId][msg.sender] = true;
            _sendRewards(eventId, events[eventId].rewards, msg.sender);
            emit AllChallengesInEventSolved(
                eventId,
                msg.sender,
                block.timestamp
            );
        }
    }
}
