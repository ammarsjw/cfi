// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title ICFIPublic.
 * @author CFI team.
 * @notice Public CFI NFT collection interface.
 */
interface ICFIPublic {
    /**
     * @dev Emitted when {baseURI} is changed from `oldBaseURI` to `newBaseURI`.
     */
    event SetBaseURI(string newBaseURI, string oldBaseURI);

    /**
     * @dev Emitted when {tokenURI} is changed from `oldTokenURI` to `newTokenURI`.
     */
    event SetTokenURI(string newTokenURI, string oldTokenURI);

    /**
     * @dev Emitted to record the `tag` against a given `tokenId`.
     */
    event Tag(uint256 tokenId, string tag);

    function baseURI() external view returns (string memory);

    function setBaseURI(string memory newBaseURI) external returns (bool);

    function totalSupply() external view returns (uint256);

    function safeMint(
        address to,
        string memory uri,
        string memory tag
    ) external returns (bool);

    function safeMintBatch(
        address to,
        uint256 quantity,
        string[] memory uris,
        string[] memory tags
    ) external returns (bool);
}
