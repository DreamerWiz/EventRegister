// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";
import "openzeppelin-contracts/contracts/token/ERC721/utils/ERC721Holder.sol";
import "openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol";

interface IERC20Token is IERC20 {
    function mint(address to, uint256 amount) external;
}

interface IERC721Token is IERC721 {
    function mint(address to) external;
}

interface IERC1155Token is IERC1155 {
    function mint(address to, uint256 tokenId, uint256 amount) external;
}
