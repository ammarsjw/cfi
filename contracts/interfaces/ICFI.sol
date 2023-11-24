// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title ICFI.
 * @author CFI team.
 * @notice Primary CFI NFT collection interface.
 */
interface ICFI {
    /**
     * @dev Emitted when {baseURI} is changed from `oldBaseURI` to `newBaseURI`.
     */
    event SetBaseURI(string newBaseURI, string oldBaseURI);

    function baseURI() external view returns (string memory);

    function setBaseURI(string memory newBaseURI) external returns (bool);

    function safeMint(address to, uint256 quantity) external returns (bool);
}
