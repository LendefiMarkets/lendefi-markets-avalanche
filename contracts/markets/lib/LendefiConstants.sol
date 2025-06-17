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

    /// @notice Address of the Uniswap V3 AVAX/USDC pool on Avalanche (token0=AVAX, token1=USDC)
    address internal constant USDC_AVAX_POOL = 0xfAe3f424a0a47706811521E3ee268f00cFb5c45E;

    /// @notice Role identifier for users authorized to pause/unpause the protocol
    bytes32 internal constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @notice Role identifier for users authorized to manage protocol parameters
    bytes32 internal constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    /// @notice Role identifier for users authorized to upgrade the contract
    bytes32 internal constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /// @notice Role identifier for users authorized to access borrow/repay functions in the LendefiMarketVault
    bytes32 internal constant PROTOCOL_ROLE = keccak256("PROTOCOL_ROLE");

    /// @notice Role identifier for addresses that can create new markets
    bytes32 internal constant MARKET_OWNER_ROLE = keccak256("MARKET_OWNER_ROLE");

    /// @notice Duration of the timelock for upgrade operations (3 days)
    uint256 internal constant UPGRADE_TIMELOCK_DURATION = 3 days;

    /// @notice Max liquidation threshold, percentage on a 1000 scale
    uint16 internal constant MAX_LIQUIDATION_THRESHOLD = 990;

    /// @notice Min liquidation threshold, percentage on a 1000 scale
    uint16 internal constant MIN_THRESHOLD_SPREAD = 10;

    /// @notice Max assets supported by platform
    uint32 internal constant MAX_ASSETS = 3000;

    /// @notice Avalanche mainnet chain ID
    uint256 internal constant AVALANCHE_CHAIN_ID = 43114;

    /// @notice Avalanche mainnet USDC token address
    address internal constant AVALANCHE_USDC = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;

    /// @notice Avalanche mainnet WAVAX token address
    address internal constant AVALANCHE_WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;

    /// @notice Avalanche mainnet USDT token address
    address internal constant AVALANCHE_USDT = 0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7;

    /// @notice Avalanche mainnet AVAX/USDC Uniswap V3 pool address
    address internal constant AVAX_USDC_POOL = 0xfAe3f424a0a47706811521E3ee268f00cFb5c45E;
}
