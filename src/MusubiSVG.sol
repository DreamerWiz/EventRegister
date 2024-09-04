// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MusubiSVG {
    mapping(uint => bytes) private _svg;

    function setSVG(uint tokenId, bytes calldata svg) external {
        _svg[tokenId] = svg;
    }

    function getSVG(uint tokenId) public view returns (bytes memory) {
        return _svg[tokenId];
    }
}
