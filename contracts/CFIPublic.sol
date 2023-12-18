// SPDX-License-Identifier: MIT

pragma solidity 0.8.22;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { ERC721, Strings } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import { CFIPublicErrors } from "./interfaces/Errors.sol";
import { ICFIPublic } from "./interfaces/ICFIPublic.sol";

import { Roles } from "./utils/Roles.sol";

/**
 * @title Crypto Financial Inc Public.
 * @author CFI team.
 * @notice Public CFI NFT collection.
 * @dev Includes a custom implementation of {ERC721URIStorage}.
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

    /// @dev Mapping from `tokenId` to `tokenURI`.
    mapping (uint256 => string) private _tokenURI;
    /// @dev Mapping from `tokenURI` to `tokenId`.
    mapping (string => uint256) private _inUseBy;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @dev Assigns all roles.
     * @param governor_ Address of the contract governor.
     * @param baseURI_ Base URI for computing the {tokenURI}.
     */
    constructor(
        address governor_,
        string memory baseURI_
    ) ERC721("Crypto Financial Inc Public", "CFIP") {
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(GOVERNOR_ROLE, ADMIN_ROLE);
        _grantRole(GOVERNOR_ROLE, governor_);
        /// @dev Responsible for all roles.
        _grantRole(ADMIN_ROLE, governor_);

        _setBaseURI(baseURI_);
    }

    /* ========== FUNCTIONS ========== */

    /**
     * @notice Returns the `tokenId` for the given `uri`.
     */
    function inUseBy(string memory uri) external view returns (uint256) {
        return _inUseBy[uri];
    }

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
        if (_inUseBy[newTokenURI] != 0) revert tokenURIAlreadyInUse();

        delete _inUseBy[oldTokenURI];
        _inUseBy[newTokenURI] = tokenId;
        _tokenURI[tokenId] = newTokenURI;

        emit SetTokenURI(newTokenURI, oldTokenURI);
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
        if (_inUseBy[uri] != 0) revert tokenURIAlreadyInUse();
        uint256 tokenId = ++_totalSupply;
        _safeMint(to, tokenId);
        _inUseBy[uri] = tokenId;
        _tokenURI[tokenId] = uri;

        emit Tag(tokenId, tag);
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
        uint256 tokenId = _totalSupply;
        _totalSupply += quantity;

        for (uint256 i = 0 ; i < quantity ; i++) {
            if (_inUseBy[uris[i]] != 0) revert tokenURIAlreadyInUse();
            tokenId++;
            _safeMint(to, tokenId);
            _inUseBy[uris[i]] = tokenId;
            _tokenURI[tokenId] = uris[i];

            emit Tag(tokenId, tags[i]);
        }
        return true;
    }
}
