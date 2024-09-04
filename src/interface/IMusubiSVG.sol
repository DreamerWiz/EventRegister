// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMusubiSVG {
    function getSVG(uint tokenId) external view returns (bytes memory);

    function setSVG(uint tokenId, bytes calldata svg) external;
}
