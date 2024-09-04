// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract MusubiRewarder {
    struct ReawardRule {
        bytes32 name;
        bytes32 data;
        uint amount;
        uint tokenId;
        uint float;
        uint probability;
    }

    ReawardRule[] private _rewardRules;
    mapping(bytes32 => uint) private _rewardRuleIdx;

    constructor() {
        _rewardRules.push(ReawardRule("GOLD_NORMAL_MINT", "", 25, 101, 0, 0));
        _rewardRules.push(ReawardRule("EXP_NORMAL_MINT", "", 25, 102, 0, 0));
    }
}
