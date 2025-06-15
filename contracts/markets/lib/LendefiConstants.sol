// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

/**
 * @title Lendefi Constants
 * @notice Shared constants for Lendefi and LendefiAssets contracts
 * @author alexei@lendefimarkets(dot)xyz
 * @custom:copyright Copyright (c) 2025 Nebula Holding Inc. All rights reserved.
 */
library LendefiConstants {
    /// @notice Standard decimals for percentage calculations (1e6 = 100%)
    uint256 internal constant WAD = 1e6;

    /// @notice Address of the Uniswap V3 USDC/ETH pool with 0.05% fee tier
    address internal constant USDC_ETH_POOL =
        0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640;

    /// @notice Role identifier for users authorized to pause/unpause the protocol
    bytes32 internal constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @notice Role identifier for users authorized to manage protocol parameters
    bytes32 internal constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    /// @notice Role identifier for users authorized to upgrade the contract
    bytes32 internal constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /// @notice Role identifier for users authorized to access borrow/repay functions in the LendefiMarketVault
    bytes32 internal constant PROTOCOL_ROLE = keccak256("PROTOCOL_ROLE");

    /// @notice Role identifier for addresses that can create new markets
    bytes32 internal constant MARKET_OWNER_ROLE =
        keccak256("MARKET_OWNER_ROLE");

    /// @notice Duration of the timelock for upgrade operations (3 days)
    uint256 internal constant UPGRADE_TIMELOCK_DURATION = 3 days;

    /// @notice Max liquidation threshold, percentage on a 1000 scale
    uint16 internal constant MAX_LIQUIDATION_THRESHOLD = 990;

    /// @notice Min liquidation threshold, percentage on a 1000 scale
    uint16 internal constant MIN_THRESHOLD_SPREAD = 10;

    /// @notice Max assets supported by platform
    uint32 internal constant MAX_ASSETS = 3000;

    /// @notice Ethereum mainnet chain ID
    uint256 internal constant ETHEREUM_CHAIN_ID = 1;

    /// @notice Ethereum mainnet USDC token address
    address internal constant ETHEREUM_USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    /// @notice Ethereum mainnet WETH token address
    address internal constant ETHEREUM_WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
}
