# MusubiEventsRegister Smart Contract - Documentation

## Overview

The `MusubiEventsRegister` smart contract is designed for hosting blockchain-based puzzle-solving events. The contract manages event registration, challenge implementation, and the distribution of rewards. It is a comprehensive system for event organizers to create, manage, and reward participants in their events.

## Key Features

- **Whitelist Management:** Only whitelisted users, added by the contract owner, can register events.
- **Event Registration:** Users can register an event with multiple challenges and associated rewards.
- **Challenge Integration:** Each event contains challenges that conform to the `IChallenge` interface.
- **Reward System:** Rewards in the form of ERC20, ERC721, and ERC1155 tokens can be distributed. Rewards are transferred to the contract at registration and released upon the successful completion of challenges or events.
- **First-to-Solve Reward:** The first participant to solve a challenge receives a special reward.
- **Event Completion Reward:** Participants who complete all challenges within an event receive rewards.
- **Challenge Implementation:** Participants must create a challenge implementation to begin solving it.

## Contract Workflow

1. **Whitelist Addition:** The contract owner adds event organizers to the whitelist using `addToWhitelist`.
2. **Event Registration:** Whitelisted users register an event using `registerEvents`. Each event contains several challenges and rewards. ERC721 rewards are only allowed as mints, not transfers.
3. **Challenge Implementation:** Participants invoke `createChallengeImpl` to generate an instance of the challenge contract.
4. **Solving Challenges:** Participants call `solveEvent` to attempt solving the challenges. Successful attempts trigger rewards.

## Contract Functions

### Whitelist Management

- `addToWhitelist(address user)`: Adds a user to the whitelist.
- `isWhitelisted(address user)`: Checks if a user is whitelisted.

### Event and Challenge Management

- `registerEvents(Event calldata eventDetail)`: Registers a new event with details including challenges and rewards.
- `createChallengeImpl(uint256 eventId, uint256 challengeIndex)`: Creates an implementation of a challenge.
- `solveEvent(uint256 eventId)`: Allows a participant to solve an event's challenges.

### Internal Functions

- `_sendRewards(...)`: Handles the distribution of rewards to participants.
- `_collectRewards(...)`: Collects rewards for an event/challenge from the event organizer.

## Event and Reward Structure

### Event Structure

- **startTime and endTime**: Define the event's duration.
- **challenges**: An array of challenges that participants need to solve.
- **rewards**: Rewards for completing the entire event.

### Reward Structure

- **token**: Address of the token to be rewarded.
- **rewardType**: Type of reward (ERC20, ERC721, ERC1155, ERC20Mint, ERC721Mint, ERC1155Mint).
- **rewardAmount**: Amount for ERC20 or ERC1155 rewards.
- **rewardId**: Token ID for ERC721 or ERC1155 rewards.
- **rewardRemaining**: Tracks the remaining quantity of a reward.

## Security and Access Control

- The contract uses `Ownable` from OpenZeppelin for owner-specific functions.
- A modifier `onlyWhitelisted` ensures that only authorized users can register events.

## Event Flow

1. **Event Creation**: An organizer creates an event with challenges and rewards.
2. **Challenge Participation**: Participants create instances of challenges and attempt to solve them.
3. **Reward Distribution**: Rewards are distributed automatically upon the successful completion of challenges or the entire event.

## Notes

- The contract assumes trust in the event organizers for fair challenge creation and reward allocation.
- ERC721 rewards in events are restricted to minting operations, aligning with the contract's design choice to prevent direct transfer of existing ERC721 tokens as rewards. 
- Minting reward methods should give permission to `MusubiEventsRegister` contract and only supported by interface below: 
```js
interface IERC20Token is IERC20 {
    function mint(address to, uint256 amount) external;
}

interface IERC721Token is IERC721 {
    function mint(address to) external;
}

interface IERC1155Token is IERC1155 {
    function mint(address to, uint256 tokenId, uint256 amount) external;
}
```
