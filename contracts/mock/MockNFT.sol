// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
contract MockNFT is ERC721("APE", "APE") {
    function mint(address to, uint256 tokenId) external {
        ERC721._mint(to, tokenId);
    }
}