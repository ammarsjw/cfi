// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @dev Roles for the {CFIPublic} and {Marketplace} contracts.
 */
abstract contract Roles {
    /// @dev Replaces the {DEFAULT_ADMIN_ROLE}.
    bytes32 constant public ADMIN_ROLE = keccak256(abi.encodePacked("Admin"));
    /// @dev Fulfils functional requirements.
    bytes32 constant public GOVERNOR_ROLE = keccak256(abi.encodePacked("Governor"));
}

/**
 * @dev Roles for the {CFI} contract.
 */
abstract contract CFIRoles {
    /// @dev Replaces the {DEFAULT_ADMIN_ROLE}.
    bytes32 constant public ADMIN_ROLE = keccak256(abi.encodePacked("Admin"));
    /// @dev Has all privileges.
    bytes32 constant public OWNER_ROLE = keccak256(abi.encodePacked("Owner"));
}
