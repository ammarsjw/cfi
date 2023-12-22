// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @dev Generic errors version 1.
 */
interface GenericErrorsV1 {
    /**
     * @dev Indicates an error if the string being reassigned is the same as the old
     * string.
     * @param newString New value of the string.
     * @param oldString Old value of the string.
     */
    error IdenticalStringReassignment(string newString, string oldString);
}

/**
 * @dev Generic errors version 2.
 */
interface GenericErrorsV2 {
    /**
     * @dev Indicates an error if the number of arguments do not match.
     */
    error ArgumentArityMismatch();
}

/**
 * @dev Errors for the {CFIPublic} contract.
 */
interface CFIPublicErrors is GenericErrorsV1, GenericErrorsV2 {
    /**
     * @dev Indicates an error if the given `quantity` during batch minting is less than
     * or equal to `1` or is more than the `limit`.
     * @param quantity Number of tokens being batch minted.
     */
    error InvalidMintQuantity(uint256 quantity, uint256 limit);

    /**
     * @dev Indicates an error if the given `tokenURI` is already in use.
     */
    error tokenURIAlreadyInUse();
}

/**
 * @dev Errors for the {Marketplace} contract.
 */
interface MarketplaceErrors is GenericErrorsV2 {
    /**
     * @dev Indicates an error if the given `collection` is already listed in the
     * `Marketplace`.
     */
    error CollectionAlreadyListed();
    /**
     * @dev Indicates an error if the given `collection` is not listed in the
     * `Marketplace`.
     */
    error CollectionNotListed();
    /**
     * @dev Indicates an error if the variable being reassigned is the same as the old
     * variable.
     */
    error IdenticalVariableReassignment();
    /**
     * @dev Indicates an error if the allowance of the `token` to bid with is
     * insufficient.
     */
    error InsufficientTokenApproval();
    /**
     * @dev Indicates an error if the balance of the `token` to bid with is
     * insufficient.
     */
    error InsufficientTokenBalance();
    /**
     * @dev Indicates a failure with the given address, for example, `address(0)`.
     */
    error InvalidAddress();
    /**
     * @dev Indicates an error related to the given amount, for example, `0`.
     */
    error InvalidAmount();
    /**
     * @dev Indicates a failure with the given array, for example, array length is `0`.
     */
    error InvalidArrayLength();
    /**
     * @dev Indicates an error if the given `collection` is not in the storage mapping.
     */
    error InvalidCollection();
    /**
     * @dev Indicates an error if the given bid does not exist.
     */
    error InvalidBid();
    /**
     * @dev Indicates an error if the caller is not the bidder.
     */
    error InvalidBidder();
    /**
     * @dev Indicates an error if the given `token` is not allowed to bid with.
     */
    error InvalidToken();
    /**
     * @dev Indicates an error if the given ETH value is invalid, for example `0`.
     */
    error InvalidValue();
    /**
     * @dev Indicates an error if the given `tokenId` in the given `collection` is
     * already up for a sale.
     */
    error SaleAlreadyExists();
    /**
     * @dev Indicates an error if the given `tokenId` in the given `collection` has not
     * been put up for a sale.
     */
    error SaleDoesNotExist();
    /**
     * @dev Indicates an error if the given tokenId is not owned by the caller.
     */
    error TokenIdNotOwned();
    /**
     * @dev Indicates an error if the given `tokenId` in the given `collection` is not
     * approved for the `Marketplace`.
     */
    error TokenIdNotApproved();
    /**
     * @dev Indicates an error when trying to wrap while having sufficient Wrapped ETH
     * balance.
     */
    error WrappedBalanceAlreadyExists();
}
