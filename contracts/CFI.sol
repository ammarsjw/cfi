// SPDX-License-Identifier: MIT

pragma solidity 0.8.22;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { ERC721A } from "./extensions/ERC721A.sol";

import { GenericErrorsV1 } from "./interfaces/Errors.sol";
import { ICFI } from "./interfaces/ICFI.sol";

import { CFIRoles } from "./utils/Roles.sol";

/**
 * @title Crypto Financial Inc.
 * @author CFI team.
 * @notice CFI NFT collection.
 */
contract CFI is AccessControl, ERC721A, GenericErrorsV1, ICFI, CFIRoles {
    using Strings for string;

    /* ========== STATE VARIABLES ========== */

    /// @notice See {ERC721A-_baseURI}.
    string public baseURI;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @dev Assigns all roles and mints initial supply.
     * @param owner_ Address of the contract owner.
     * @param initialSupply_ Amount of tokens to mint at contract creation.
     * @param baseURI_ Base URI for computing the {tokenURI}.
     */
    constructor(
        address owner_,
        uint256 initialSupply_,
        string memory baseURI_
    ) ERC721A("Crypto Financial Inc", "CFI") {
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(OWNER_ROLE, ADMIN_ROLE);
        _grantRole(OWNER_ROLE, owner_);
        /// @dev Responsible for all roles.
        _grantRole(ADMIN_ROLE, owner_);

        _setBaseURI(baseURI_);

        /// @dev To be used only in the constructor.
        _mintERC2309(owner_, initialSupply_);
    }

    /* ========== FUNCTIONS ========== */

    /**
     * @inheritdoc ERC721A
     * @dev Overridden to include this contracts `interfaceId`.
     * @param interfaceId Id of the required interface.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(AccessControl, ERC721A) returns (bool) {
        return
            interfaceId == type(ICFI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc ERC721A
     * @dev Overridden to change {_startTokenId} to `1`.
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /**
     * @notice Sets the value for {baseURI}. Only `Owner` can call this function.
     * @param newBaseURI Value to set the {baseURI} to.
     */
    function setBaseURI(
        string memory newBaseURI
    ) external onlyRole(OWNER_ROLE) returns (bool) {
        if (newBaseURI.equal(baseURI))
            revert IdenticalStringReassignment(newBaseURI, baseURI);

        _setBaseURI(newBaseURI);
        return true;
    }

    /**
     * @dev Internal set base uri logic.
     */
    function _setBaseURI(string memory newBaseURI) internal {
        emit SetBaseURI(newBaseURI, baseURI);
        baseURI = newBaseURI;
    }

    /**
     * @inheritdoc ERC721A
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @notice See {ERC721A-_safeMint}. Only `Owner` can call this function.
     * @param to Recipient address of minted tokens.
     * @param quantity Amount of tokens to mint.
     */
    function safeMint(
        address to,
        uint256 quantity
    ) external onlyRole(OWNER_ROLE) returns (bool) {
        _safeMint(to, quantity);
        return true;
    }
}
