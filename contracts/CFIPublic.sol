// SPDX-License-Identifier: MIT

pragma solidity 0.8.22;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { ERC721, Strings } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import { CFIPublicErrors } from "./interfaces/Errors.sol";
import { ICFIPublic } from "./interfaces/ICFIPublic.sol";

import { Roles } from "./utils/Roles.sol";

/**
 * @title CFIPublic.
 * @author CFI team.
 * @notice Public CFI NFT collection.
 */
contract CFIPublic is AccessControl, ERC721, CFIPublicErrors, ICFIPublic, Roles {
    using Strings for string;

    /* ========== STATE VARIABLES ========== */

    /// @notice Maxmimum amount of tokens that can be minted using {safeMintBatch}.
    uint256 public constant MAX_MINT_BATCH_QUANTITY_LIMIT = 1000;

    /// @dev Total number of tokens in existence.
    uint256 private _totalSupply;

    /// @notice See {ERC721-_baseURI}.
    string public baseURI;

    /* ========== STORAGE ========== */

    mapping (uint256 => string) private _tokenURI;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @dev Assigns all roles.
     * @param governor_ Address of the contract governor.
     */
    constructor(address governor_) ERC721("Crypto Financial Inc Public", "CFIP") {
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(GOVERNOR_ROLE, ADMIN_ROLE);
        _grantRole(GOVERNOR_ROLE, governor_);
        /// @dev Responsible for all roles.
        _grantRole(ADMIN_ROLE, governor_);
    }

    /* ========== FUNCTIONS ========== */

    /**
     * @inheritdoc ERC721
     * @dev Overridden to include this contracts `interfaceId`.
     * @param interfaceId Id of the required interface.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(AccessControl, ERC721) returns (bool) {
        return
            interfaceId == type(ICFIPublic).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @notice Returns the total number of tokens in existence.
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @notice For emergencies. Sets the value for {tokenURI} for a given `tokenId`.
     * Only `Governor` can call this function.
     * @param tokenId Token to change the {tokenURI} of.
     * @param newTokenURI Value to set the {tokenURI} to.
     */
    function setTokenURI(
        uint256 tokenId,
        string memory newTokenURI
    ) external onlyRole(GOVERNOR_ROLE) returns (bool) {
        string memory oldTokenURI = _tokenURI[tokenId];

        if (newTokenURI.equal(oldTokenURI))
            revert IdenticalStringReassignment(newTokenURI, oldTokenURI);

        emit SetTokenURI(newTokenURI, oldTokenURI);
        _tokenURI[tokenId] = newTokenURI;
        return true;
    }

    /**
     * @inheritdoc ERC721
     * @dev Overridden to return a unique {tokenURI} relevant to each `tokenId`.
     * @param tokenId Token to get the {tokenURI} for.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);

        string memory __baseURI = baseURI;
        return bytes(__baseURI).length > 0 ?
            string.concat(__baseURI, _tokenURI[tokenId]) :
            "";
    }

    /**
     * @notice Sets the value for {baseURI}. Only `Governor` can call this function.
     * @param newBaseURI Value to set the {baseURI} to.
     */
    function setBaseURI(
        string memory newBaseURI
    ) external onlyRole(GOVERNOR_ROLE) returns (bool) {
        if (newBaseURI.equal(baseURI))
            revert IdenticalStringReassignment(newBaseURI, baseURI);

        emit SetBaseURI(newBaseURI, baseURI);
        baseURI = newBaseURI;
        return true;
    }

    /**
     * @notice See {ERC721-_safeMint}.
     * @dev Also takes the unique `uri` as an argument for the token being minted.
     * @param to Address to which token will be minted.
     * @param uri URI for the token.
     */
    function safeMint(
        address to,
        string memory uri,
        string memory tag
    ) external returns (bool) {
        _totalSupply++;
        _safeMint(to, _totalSupply);
        _tokenURI[_totalSupply] = uri;

        emit Tag(_totalSupply, tag);
        return true;
    }

    /**
     * @notice Safely mints `quantity` amount of tokens to `to`.
     * @dev Also takes the unique `uris` as an argument for the tokens being minted.
     * @param to Address to which tokens will be minted.
     * @param quantity Amount of tokens to mint.
     * @param uris Array of URIs for the tokens.
     * @param tags Array of tags for the tokens.
     */
    function safeMintBatch(
        address to,
        uint256 quantity,
        string[] memory uris,
        string[] memory tags
    ) external returns (bool) {
        if (quantity < 2 || MAX_MINT_BATCH_QUANTITY_LIMIT < quantity)
            revert InvalidMintQuantity(quantity, MAX_MINT_BATCH_QUANTITY_LIMIT);
        if (quantity != uris.length || quantity != tags.length)
            revert ArgumentArityMismatch();
        uint256 currentSupply = _totalSupply;
        _totalSupply += quantity;

        for (uint256 i = 0 ; i < quantity ; i++) {
            currentSupply++;
            _safeMint(to, currentSupply);
            _tokenURI[currentSupply] = uris[i];

            emit Tag(currentSupply, tags[i]);
        }
        return true;
    }
}
