// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interface/IAgent.sol";

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
 * @dev This contract is used as the permission control
 * center of the entire musubi protocl. Any other contracts
 * are considered to use this protocol to control privileges.
 */

import "./interface/IAgent.sol";

contract Agent is AccessControl, IAgent {
    bytes32 public constant OPERATOR_ROLE = bytes32(uint(0x01));
    bytes32 public constant OPERATOR_ADMIN_ROLE = bytes32(uint(0x02));

    bytes32 public constant MANAGER_ROLE = bytes32(uint(0x03));
    bytes32 public constant MANAGER_ADMIN_ROLE = bytes32(uint(0x04));

    bytes32 public constant CHALLENGE_MANAGER_ROLE = bytes32(uint(0x05));
    bytes32 public constant CHALLENGE_MANAGER_ADMIN_ROLE = bytes32(uint(0x06));

    bytes32 public constant MINTER_ROLE = bytes32(uint(0x07));
    bytes32 public constant MINTER_ADMIN_ROLE = bytes32(uint(0x08));

    mapping(address => TokenType) private _whitelistedTokens;

    event AddWhitelistedToken(address token);

    constructor() {
        _setRoleAdmin(OPERATOR_ROLE, OPERATOR_ADMIN_ROLE);
        _setRoleAdmin(MANAGER_ROLE, MANAGER_ADMIN_ROLE);
        _setRoleAdmin(CHALLENGE_MANAGER_ROLE, CHALLENGE_MANAGER_ADMIN_ROLE);
        _setRoleAdmin(MINTER_ROLE, MINTER_ADMIN_ROLE);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function isOperator(address user) external view returns (bool res) {
        return hasRole(OPERATOR_ROLE, user);
    }

    function isChallengeManager(address user) external view returns (bool res) {
        return hasRole(CHALLENGE_MANAGER_ROLE, user);
    }

    function isManager(address user) external view returns (bool res) {
        return hasRole(MANAGER_ROLE, user);
    }

    function isMinter(address user) external view returns (bool res) {
        return hasRole(MINTER_ROLE, user);
    }

    function setChallengeManager(
        address user,
        bool s
    ) external onlyRole(CHALLENGE_MANAGER_ADMIN_ROLE) {
        if (s && !hasRole(CHALLENGE_MANAGER_ROLE, user)) {
            _grantRole(CHALLENGE_MANAGER_ROLE, user);
        } else if (!s && hasRole(CHALLENGE_MANAGER_ROLE, user)) {
            _revokeRole(CHALLENGE_MANAGER_ROLE, user);
        }
    }

    function addWhitelistedToken(
        address token,
        TokenType tokenType
    ) external onlyRole(MANAGER_ROLE) {
        _whitelistedTokens[token] = tokenType;
    }

    function removeWhitelistedToken(
        address token
    ) external onlyRole(MANAGER_ROLE) {
        _whitelistedTokens[token] = TokenType.None;
    }

    function getTokenType(
        address token
    ) external view returns (TokenType tokenType) {
        return _whitelistedTokens[token];
    }
}
