// SPDX-License-Identifier: MIT

pragma solidity 0.8.22;

import "forge-std/Test.sol";

import { EACAggregatorProxy } from "./utils/EACAggregatorProxy.sol";
import { WETH9 } from "./utils/WETH9.sol";

import { CFI } from "contracts/CFI.sol";
import { CFIPublic } from "contracts/CFIPublic.sol";
import {
    AggregatorV3Interface,
    Marketplace,
    IERC20,
    IERC721
} from "contracts/Marketplace.sol";

contract MarketplaceTest is Test {

    /* ========== STATE VARIABLES ========== */

    // Allowed tokens and their respective whales.
    WETH9 weth;
    address wethWhale = 0x88124Ef4A9EC47e691F254F2E8e348fd1e341e9B;

    // Setup variables.
    address ownerAddress = address(this);
    uint256 initialSupply = 250;
    address governorAddress = address(1);
    IERC20[] tokens;
    AggregatorV3Interface[] priceFeeds;
    IERC721[] initialListings;

    // Protocol contracts.
    Marketplace marketplace;
    CFI cfi;
    CFIPublic cfiPublic;

    /* ========== SETUP ========== */

    /**
     * @dev Invoked before each test.
     */
    function setUp() public {
        cfi = new CFI(ownerAddress, initialSupply);
        cfiPublic = new CFIPublic(governorAddress);
        initialListings.push(IERC721(address(cfi)));
        initialListings.push(IERC721(address(cfiPublic)));

        weth = new WETH9();
        tokens.push(IERC20(address(weth)));

        EACAggregatorProxy eacAggregatorProxy = new EACAggregatorProxy();
        priceFeeds.push(AggregatorV3Interface(address(eacAggregatorProxy)));

        marketplace = new Marketplace(
            governorAddress,
            tokens,
            priceFeeds,
            initialListings
        );

        // Getting WETH.
        vm.deal(address(this), type(uint256).max);
        uint256 wethBalance = type(uint256).max / 2;
        weth.deposit{value: wethBalance}();

        // Approving WETH.
        weth.approve(address(marketplace), type(uint256).max);
    }

    /* ========== TESTS ========== */

    function testMultipleBids() public {
        // Stacking multiple bids on a few NFTs.
        for (uint256 i = 0 ; i < 100 ; i++) {
            marketplace.bid(IERC721(address(cfi)), 1, (i + 1) * 1e18);
        }
        for (uint256 i = 0 ; i < 100 ; i++) {
            marketplace.bid(IERC721(address(cfi)), 2, (i + 1) * 1e18);
        }
    }

    function testSale() public {
        // Approval method 1.
        cfi.approve(address(marketplace), 1);
        marketplace.startSale(IERC721(address(cfi)), 1, 5000, 1000000000000000000);
        // Approval method 2.
        cfi.setApprovalForAll(address(marketplace), true);
        marketplace.startSale(IERC721(address(cfi)), 2, 5000, 1000000000000000000);
    }
}
