// SPDX-License-Identifier: MIT

pragma solidity 0.8.22;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {
    Address,
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {
    AggregatorV3Interface
} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import { MarketplaceErrors } from "./interfaces/Errors.sol";
import { IWETH } from "./interfaces/IWETH.sol";

import { LinkedListLogic, LinkedListStorage } from "./libraries/LinkedList.sol";

import { Roles } from "./utils/Roles.sol";

/**
 * @title Marketplace.
 * @author CFI team.
 * @notice Marketplace to buy and sell NFTs.
 */
contract Marketplace is AccessControl, MarketplaceErrors, LinkedListStorage, Roles {
    using Address for address payable;
    using SafeERC20 for IERC20;
    using LinkedListLogic for LinkedList;

    /* ========== STATE VARIABLES ========== */

    /// @dev Tokenized checksummed address used as an identifier for ETH.
    IERC20 private constant _ETH = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    /// @notice Address of the Wrapped ETH token.
    address public immutable WETH;

    /// @notice Minimum sell price/bid amount in USD - magnified by 1e18.
    uint256 public constant MIN_AMOUNT = 0.000000001 * 1e18;
    /// @notice Percentage increase needed from the highest bid - magnified by 1e3.
    uint256 public constant PERCENTAGE_INCREASE = 0.1 * 1e3;
    /// @notice Percentage tax when an NFT is bought.
    uint256 public constant PERCENTAGE_TAX = 0.5 * 1e3;

    /// @notice Address of the tax collector wallet;
    address public treasuryWallet;

    /* ========== STORAGE ========== */

    struct Listing {
        uint256 startTime;
        IERC20 token;
    }

    struct Sale {
        uint256 startTime;
        uint256 endTime;
        uint256 duration;
        /// @dev Price of NFT being sold in USD - magnified by 1e18.
        uint256 price;
    }

    /// @notice Tokens that are allowed for bidding. Mapping from `token` to
    /// `priceFeed`. If the `priceFeed` is equal to `address(0)` then the token is not
    /// allowed.
    mapping (IERC20 => AggregatorV3Interface) public allowedTokens;
    /// @notice Collections that are currently listed on the marketplace. Mapping from
    /// `collection` to {Listing}.
    mapping (IERC721 => Listing) public getListings;
    /// @dev Mapping from hash of `collection` and `tokenId` to {Sale}.
    mapping (bytes32 => Sale) private _getSales;
    /// @dev Mapping from hash of `collection` and `tokenId` to `token` to {LinkedList}.
    mapping (bytes32 => mapping (IERC20 => LinkedList)) private _getBids;

    /* ========== EVENTS ========== */

    event UpdateTreasuryWallet(address newTreasuryWallet, address oldTreasuryWallet);
    event UpdateAllowedToken(IERC20 token, AggregatorV3Interface priceFeed);
    event UpdateListing(IERC721 collection, uint256 startTime, IERC20 token);
    event StartSale(
        IERC721 collection,
        uint256 tokenId,
        uint256 startTime,
        uint256 endTime,
        uint256 duration,
        uint256 price
    );
    event EndSale(IERC721 collection, uint256 tokenId);
    event AuctionBid(
        IERC721 collection,
        uint256 tokenId,
        int256 index,
        address bidder,
        uint256 amountToken
    );
    event AuctionCancelBid(IERC721 collection, uint256 tokenId, int256 index);
    event AuctionAcceptBid(IERC721 collection, uint256 tokenId, int256 index);
    event SaleBuy(
        IERC721 collection,
        uint256 tokenId,
        address buyer,
        uint256 amountToken,
        IERC20 token
    );

    /* ========== CONSTRUCTOR ========== */

    /**
     * @dev Assigns all roles and initializes all dependencies.
     * @param governor_ Address of the contract governor.
     * @param allowedTokens_ Tokens that are allowed for bidding.
     * @param priceFeeds_ PriceFeeds used to get the price of tokens.
     * @param initialListings_ Collections to add in the listing at initialization.
     */
    constructor(
        address governor_,
        IERC20[] memory allowedTokens_,
        AggregatorV3Interface[] memory priceFeeds_,
        IERC721[] memory initialListings_
    ) {
        if (allowedTokens_.length == 0 || initialListings_.length == 0)
            revert InvalidArrayLength();
        if (allowedTokens_.length != priceFeeds_.length) revert ArgumentArityMismatch();

        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(GOVERNOR_ROLE, ADMIN_ROLE);
        _grantRole(GOVERNOR_ROLE, governor_);
        /// @dev Responsible for all roles.
        _grantRole(ADMIN_ROLE, governor_);

        /// @dev The first allowed token should always be Wrapped ETH.
        WETH = address(allowedTokens_[0]);

        treasuryWallet = governor_;

        for (uint256 i = 0 ; i < allowedTokens_.length ; i++) {
            allowedTokens[allowedTokens_[i]] = priceFeeds_[i];
        }
        for (uint256 i = 0 ; i < initialListings_.length ; i++) {
            _updateListing(initialListings_[i], IERC20(WETH));
        }
    }

    /* ========== FUNCTIONS ========== */

    /**
     * @dev Internal storage mapping slug logic.
     */
    function _slug(
        IERC721 collection,
        uint256 tokenId
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(collection, tokenId));
    }

    /**
     * @notice Sales that are currently ongoing.
     * @param collection Collection to interact with.
     * @param tokenId Unique identifier of the NFT.
     */
    function getSales(
        IERC721 collection,
        uint256 tokenId
    ) external view returns (Sale memory) {
        return _getSales[_slug(collection, tokenId)];
    }

    /**
     * @notice Bids in a given auction that is currently ongoing.
     * @param collection Collection to interact with.
     * @param tokenId Unique identifier of the NFT.
     * @param token Token to interact with.
     * @param index Unique index of the bid.
     */
    function getBids(
        IERC721 collection,
        uint256 tokenId,
        IERC20 token,
        int256 index
    ) external view returns (Bid memory) {
        return _getBids[_slug(collection, tokenId)][token].getData(index);
    }

    /**
     * @dev Updates the address of {treasuryWallet}. Only `Governor` can call this
     * function.
     * @param newTreasuryWallet New address to assign to {treasuryWallet}.
     */
    function updateTreasuryWallet(
        address newTreasuryWallet
    ) external onlyRole(GOVERNOR_ROLE) {
        if (newTreasuryWallet == treasuryWallet)
            revert IdenticalVariableReassignment();

        emit UpdateTreasuryWallet(newTreasuryWallet, treasuryWallet);
        treasuryWallet = newTreasuryWallet;
    }

    /**
     * @notice Adds or updates a given `token` and it's `priceFeed` in the list of
     * tokens that are allowed for bidding. Only `Governor` can call this function.
     * @param token Token to interact with.
     * @param priceFeed Price aggregator of the given `token`.
     */
    function updateAllowedToken(
        IERC20 token,
        AggregatorV3Interface priceFeed
    ) external onlyRole(GOVERNOR_ROLE) {
        if (address(token) == address(0)) revert InvalidAddress();
        if (priceFeed == allowedTokens[token]) revert IdenticalVariableReassignment();
        allowedTokens[token] = priceFeed;

        emit UpdateAllowedToken(token, priceFeed);
    }

    /**
     * @notice Adds or updates a given `collection` in the listing. Only `Governor` can
     * call this function. NOTE: If the `collection` was already listed and it's bidding
     * token is changed then all bids with the previous token will be archived.
     * @param collection Collection to interact with.
     * @param token Token to be used for bidding.
     */
    function updateListing(
        IERC721 collection,
        IERC20 token
    ) external onlyRole(GOVERNOR_ROLE) {
        _updateListing(collection, token);
    }

    /**
     * @dev Internal update listing logic.
     */
    function _updateListing(IERC721 collection, IERC20 token) internal {
        Listing storage listing = getListings[collection];

        if (address(collection) == address(0)) revert InvalidAddress();
        if (token == listing.token) revert IdenticalVariableReassignment();

        if (address(token) == address(0)) {
            delete getListings[collection];
        } else {
            if (address(listing.token) == address(0)) {
                listing.startTime = block.timestamp;
            }
            listing.token = token;
        }

        emit UpdateListing(collection, listing.startTime, token);
    }

    /**
     * @notice Start the sale or restart it when it ends for a given NFT.
     * @param collection Collection to interact with.
     * @param tokenId Unique identifier of the NFT.
     * @param duration Duration of the sale in seconds.
     * @param price Selling price of the NFT in USD.
     */
    function startSale(
        IERC721 collection,
        uint256 tokenId,
        uint256 duration,
        uint256 price
    ) external {
        Sale storage sale = _getSales[_slug(collection, tokenId)];

        if (getListings[collection].startTime == 0) revert CollectionNotListed();
        if (block.timestamp <= sale.endTime) revert SaleAlreadyExists();
        if (collection.ownerOf(tokenId) != _msgSender()) revert IncorrectOwner();
        bool isNotApproved =
            collection.getApproved(tokenId) != address(this) &&
            !collection.isApprovedForAll(_msgSender(), address(this));

        if (isNotApproved) revert MissingTokenIdApproval();
        if (duration == 0 || price < MIN_AMOUNT) revert InvalidAmount();
        sale.startTime = block.timestamp;
        sale.endTime = block.timestamp + duration;
        sale.duration = duration;
        sale.price = price;

        emit StartSale(
            collection,
            tokenId,
            block.timestamp,
            sale.endTime,
            duration,
            price
        );
    }

    /**
     * @notice End the sale early for a given NFT.
     * @param collection Collection to interact with.
     * @param tokenId Unique identifier of the NFT.
     */
    function endSale(IERC721 collection, uint256 tokenId) external {
        bytes32 slug = _slug(collection, tokenId);
        Sale memory sale = _getSales[slug];

        if (sale.startTime == 0 || block.timestamp > sale.endTime)
            revert SaleDoesNotExist();
        if (collection.ownerOf(tokenId) == _msgSender()) revert IncorrectOwner();

        delete _getSales[slug];

        emit EndSale(collection, tokenId);
    }

    /**
     * @notice Give Wrapped ETH approval as a bid for a given NFT that is on auction.
     * NOTE: Should only be called if the caller does not have enough Wrapped ETH
     * balance.
     * @dev Accepts ETH equal to `amountWETH - WETH.balanceOf(_msgSender())` and returns
     * an equivalent amount of Wrapped ETH.
     * @param collection Collection to interact with.
     * @param tokenId Unique identifier of the NFT.
     * @param amountWETH Amount of Wrapped ETH to bid.
     */
    function wrapAndBid(
        IERC721 collection,
        uint256 tokenId,
        uint256 amountWETH
    ) external payable {
        if (address(getListings[collection].token) != address(WETH))
            revert InvalidToken();
        IWETH weth = IWETH(WETH);
        uint256 balanceWETH = weth.balanceOf(_msgSender());

        if (balanceWETH >= amountWETH) revert WrappedBalanceAlreadyExists();
        if (msg.value != (amountWETH - balanceWETH)) revert InvalidValue();
        weth.deposit{value: msg.value}();
        weth.transfer(_msgSender(), msg.value);
        _bid(collection, tokenId, amountWETH);
    }

    /**
     * @notice Give `token` approval as a bid for a given NFT that is on auction.
     * @param collection Collection to interact with.
     * @param tokenId Unique identifier of the NFT.
     * @param amountToken Amount of token to bid.
     */
    function bid(IERC721 collection, uint256 tokenId, uint256 amountToken) external {
        _bid(collection, tokenId, amountToken);
    }

    /**
     * @dev Internal bid logic.
     */
    function _bid(IERC721 collection, uint256 tokenId, uint256 amountToken) internal {
        Listing memory listing = getListings[collection];

        if (listing.startTime == 0) revert CollectionNotListed();
        LinkedList storage linkedList =
            _getBids[_slug(collection, tokenId)][listing.token];
        uint256 highestBidAmount = linkedList.getHighestAmount();
        uint256 minRequiredBidAmountToken = highestBidAmount > 0 ?
            (highestBidAmount * (1e5 + PERCENTAGE_INCREASE)) / 1e5 :
            MIN_AMOUNT;

        if (amountToken < minRequiredBidAmountToken) revert InvalidAmount();
        if (listing.token.allowance(_msgSender(), address(this)) < amountToken)
            revert InsufficientTokenApproval();
        if (listing.token.balanceOf(_msgSender()) < amountToken)
            revert InsufficientTokenBalance();
        Bid memory bidToCreate;
        bidToCreate.bidder = _msgSender();
        bidToCreate.amountToken = amountToken;
        bidToCreate.time = block.timestamp;
        int256 index = linkedList.insert(bidToCreate);

        emit AuctionBid(collection, tokenId, index, _msgSender(), amountToken);
    }

    /**
     * @notice Cancel a bid for a given NFT that is on auction.
     * @param collection Collection to interact with.
     * @param tokenId Unique identifier of the NFT.
     * @param index Unique index of the bid.
     */
    function cancelBid(IERC721 collection, uint256 tokenId, int256 index) external {
        Listing memory listing = getListings[collection];

        if (listing.startTime == 0) revert CollectionNotListed();
        LinkedList storage linkedList =
            _getBids[_slug(collection, tokenId)][listing.token];

        if (linkedList.getData(index).bidder != _msgSender()) revert InvalidBidder();
        /// @dev Deleting the bid at `index`.
        linkedList.remove(index);

        emit AuctionCancelBid(collection, tokenId, index);
    }

    /**
     * @notice Accept the highest bid for a given NFT that is on auction.
     * @param collection Collection to interact with.
     * @param tokenId Unique identifier of the NFT.
     * @param index Unique index of the bid.
     */
    function AcceptBid(IERC721 collection, uint256 tokenId, int256 index) external {
        if (collection.ownerOf(tokenId) == _msgSender()) revert IncorrectOwner();
        Listing memory listing = getListings[collection];

        if (listing.startTime == 0) revert CollectionNotListed();
        LinkedList storage linkedList =
            _getBids[_slug(collection, tokenId)][listing.token];
        Bid memory bidToAccept = linkedList.getData(index);

        if (!linkedList.exists(index)) revert InvalidBid();
        if (bidToAccept.bidder != _msgSender()) revert InvalidBidder();
        /// @dev Deleting the bid at `index`.
        linkedList.remove(index);
        address seller = collection.ownerOf(tokenId);
        uint256 amountTax = bidToAccept.amountToken * PERCENTAGE_TAX / 1e5;
        listing.token.safeTransferFrom(_msgSender(), treasuryWallet, amountTax);
        bidToAccept.amountToken -= amountTax;
        listing.token.safeTransferFrom(_msgSender(), seller, bidToAccept.amountToken);
        collection.transferFrom(seller, _msgSender(), tokenId);

        emit AuctionAcceptBid(collection, tokenId, index);
    }

    /**
     * @notice Buy a given NFT that is on sale using ETH.
     * @param collection Collection to interact with.
     * @param tokenId Unique identifier of the NFT.
     */
    function buyETH(IERC721 collection, uint256 tokenId) external payable {
        if (msg.value == 0) revert InvalidValue();
        (address seller, uint256 amountETH) = _buy(collection, tokenId, IERC20(WETH));

        if (msg.value > amountETH) {
            uint256 toReturn = msg.value - amountETH;
            payable(_msgSender()).sendValue(toReturn);
        }
        uint256 amountTax = amountETH * PERCENTAGE_TAX / 1e5;
        payable(treasuryWallet).sendValue(amountTax);
        uint256 amountSeller = amountETH - amountTax;
        payable(seller).sendValue(amountSeller);
        collection.transferFrom(seller, _msgSender(), tokenId);

        emit SaleBuy(collection, tokenId, _msgSender(), amountETH, _ETH);
    }

    /**
     * @notice Buy a given NFT that is on sale using the provided `token`.
     * @param collection Collection to interact with.
     * @param tokenId Unique identifier of the NFT.
     * @param token Token to buy with.
     */
    function buy(IERC721 collection, uint256 tokenId, IERC20 token) external {
        (address seller, uint256 amountToken) = _buy(collection, tokenId, token);
        uint256 amountTax = amountToken * PERCENTAGE_TAX / 1e5;
        token.safeTransferFrom(_msgSender(), treasuryWallet, amountTax);
        uint256 amountSeller = amountToken - amountTax;
        token.safeTransferFrom(_msgSender(), seller, amountSeller);
        collection.transferFrom(seller, _msgSender(), tokenId);

        emit SaleBuy(collection, tokenId, _msgSender(), amountToken, token);
    }

    /**
     * @dev Internal buy logic.
     */
    function _buy(
        IERC721 collection,
        uint256 tokenId,
        IERC20 token
    ) internal returns (address seller, uint256 amountToken) {
        bytes32 slug = _slug(collection, tokenId);
        Sale memory sale = _getSales[slug];

        if (block.timestamp > sale.endTime) revert SaleDoesNotExist();
        if (address(allowedTokens[token]) == address(0)) revert InvalidToken();
        AggregatorV3Interface priceFeed = allowedTokens[token];
        (, int256 priceToken, , , ) = priceFeed.latestRoundData();
        amountToken = (sale.price * priceFeed.decimals()) / uint256(priceToken);
        seller = collection.ownerOf(tokenId);

        delete _getSales[slug];
        return (seller, amountToken);
    }
}
