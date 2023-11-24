// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title LinkedListStorage.
 * @author CFI team.
 * @notice Linked list storage interface.
 */
interface LinkedListStorage {

    /* ========== STORAGE ========== */

    /// @dev Data pertaining to each node. Struct is contract specific. NOTE: Must be
    /// the same as the data type of {data} in {Node}.
    struct Bid {
        address bidder;
        uint256 amountToken;
        uint256 time;
    }

    /// @dev Storage of each node. Linked list specific struct.
    struct Node {
        int256 nextIndex;
        int256 prevIndex;

        /// @dev Change the data type of {data} as required.
        Bid data;
    }

    /// @dev Storage logic for the linked list. Linked list specific struct.
    struct LinkedList {
        mapping (int256 => Node) nodes;

        int256 headIndex;
        int256 tailIndex;

        int256 count;
    }
}
