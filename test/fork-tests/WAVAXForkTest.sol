// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./BasicDeploy.sol";
import {console2} from "forge-std/console2.sol";
import {IASSETS} from "../../contracts/interfaces/IASSETS.sol";
import {IPROTOCOL} from "../../contracts/interfaces/IProtocol.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from
    "../../contracts/vendor/@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IUniswapV3Pool} from "../../contracts/interfaces/IUniswapV3Pool.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract WAVAXForkTest is BasicDeploy {
    // Avalanche mainnet addresses from networks.json
    address constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address constant USDC_TOKEN = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;
    address constant USDT = 0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7;
    address constant BTC = 0x152b9d0FdC40C096757F570A51E494bd4b943E50;
    address constant WETH = 0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB;
    address constant LINK = 0x5947BB275c521040051D82396192181b413227A3;

    // Pools from networks.json
    address constant AVAX_USDC_POOL = 0xfAe3f424a0a47706811521E3ee268f00cFb5c45E;
    address constant WETH_AVAX_POOL = 0x7b602f98D71715916E7c963f51bfEbC754aDE2d0;
    address constant LINK_AVAX_POOL = 0xEB7e0191f4054868D97F33CA7a4176b226cCBd2F;
    address constant BTC_USDC_POOL = 0xD1356d360F37932059E5b89b7992692aA234EDA6;
    address constant USDT_USDC_POOL = 0x804226cA4EDb38e7eF56D16d16E92dc3223347A0;

    // Chainlink oracles from networks.json
    address constant AVAX_CHAINLINK_ORACLE = 0x0A77230d17318075983913bC2145DB16C7366156;
    address constant USDC_CHAINLINK_ORACLE = 0xF096872672F44d6EBA71458D74fe67F9a77a23B9;
    address constant USDT_CHAINLINK_ORACLE = 0xEBE676ee90Fe1112671f19b6B7459bC678B67e8a;
    address constant BTC_CHAINLINK_ORACLE = 0x86442E3a98558357d46E6182F4b262f76c4fa26F;
    address constant ETH_CHAINLINK_ORACLE = 0x976B3D034E162d8bD72D6b9C989d545b839003b0;
    address constant LINK_CHAINLINK_ORACLE = 0x49ccd9ca821EfEab2b98c60dC60F518E765EDe9a;

    uint256 avalancheFork;
    address testUser;

    function setUp() public {
        // Fork Avalanche mainnet at current block
        avalancheFork = vm.createFork("mainnet", 63997026);
        vm.selectFork(avalancheFork);

        // Deploy protocol normally
        vm.warp(365 days);

        // Deploy base contracts
        _deployTimelock();
        _deployToken();
        _deployEcosystem();
        _deployTreasury();
        _deployGovernor();
        _deployMarketFactory();

        // Deploy WAVAX market as base asset
        _deployMarket(WAVAX, "Lendefi Yield Token WAVAX", "LYTWAVAX");

        // Now warp to current time to match oracle data
        vm.warp(1750152636 + 3600); // Block timestamp + 1 hour

        // Create test user with AVAX
        testUser = makeAddr("testUser");
        vm.deal(testUser, 1000 ether);

        // Setup roles
        vm.startPrank(guardian);
        timelockInstance.revokeRole(PROPOSER_ROLE, ethereum);
        timelockInstance.revokeRole(EXECUTOR_ROLE, ethereum);
        timelockInstance.revokeRole(CANCELLER_ROLE, ethereum);
        timelockInstance.grantRole(PROPOSER_ROLE, address(govInstance));
        timelockInstance.grantRole(EXECUTOR_ROLE, address(govInstance));
        timelockInstance.grantRole(CANCELLER_ROLE, address(govInstance));
        vm.stopPrank();

        // TGE setup
        vm.prank(guardian);
        tokenInstance.initializeTGE(address(ecoInstance), address(treasuryInstance));

        // Configure assets - WAVAX is base asset, others are collateral
        _configureWAVAX();
        _configureUSDC();
        _configureUSDT();
        _configureBTC();
        _configureWETH();
        _configureLINK();
    }

    function _configureWAVAX() internal {
        vm.startPrank(address(timelockInstance));

        // Configure WAVAX as base asset
        assetsInstance.updateAssetConfig(
            WAVAX,
            IASSETS.Asset({
                active: 1,
                decimals: 18,
                borrowThreshold: 950, // Base asset threshold
                liquidationThreshold: 980,
                maxSupplyThreshold: 10_000_000 ether, // 10M AVAX
                isolationDebtCap: 0,
                assetMinimumOracles: 1,
                porFeed: address(0),
                primaryOracleType: IASSETS.OracleType.CHAINLINK,
                tier: IASSETS.CollateralTier.CROSS_A,
                chainlinkConfig: IASSETS.ChainlinkOracleConfig({oracleUSD: AVAX_CHAINLINK_ORACLE, active: 1}),
                poolConfig: IASSETS.UniswapPoolConfig({pool: AVAX_USDC_POOL, twapPeriod: 1800, active: 1})
            })
        );

        vm.stopPrank();
    }

    function _configureUSDC() internal {
        vm.startPrank(address(timelockInstance));

        // Configure USDC as stable collateral
        assetsInstance.updateAssetConfig(
            USDC_TOKEN,
            IASSETS.Asset({
                active: 1,
                decimals: 6,
                borrowThreshold: 950, // 95% - very safe for stablecoin
                liquidationThreshold: 980, // 98% - very safe for stablecoin
                maxSupplyThreshold: 100_000_000e6, // 100M USDC
                isolationDebtCap: 0,
                assetMinimumOracles: 1,
                porFeed: address(0),
                primaryOracleType: IASSETS.OracleType.CHAINLINK,
                tier: IASSETS.CollateralTier.STABLE,
                chainlinkConfig: IASSETS.ChainlinkOracleConfig({oracleUSD: USDC_CHAINLINK_ORACLE, active: 1}),
                poolConfig: IASSETS.UniswapPoolConfig({pool: AVAX_USDC_POOL, twapPeriod: 1800, active: 1})
            })
        );

        vm.stopPrank();
    }

    function _configureUSDT() internal {
        vm.startPrank(address(timelockInstance));

        // Configure USDT as stable collateral
        assetsInstance.updateAssetConfig(
            USDT,
            IASSETS.Asset({
                active: 1,
                decimals: 6,
                borrowThreshold: 950, // 95% - very safe for stablecoin
                liquidationThreshold: 980, // 98% - very safe for stablecoin
                maxSupplyThreshold: 100_000_000e6, // 100M USDT
                isolationDebtCap: 0,
                assetMinimumOracles: 1,
                porFeed: address(0),
                primaryOracleType: IASSETS.OracleType.CHAINLINK,
                tier: IASSETS.CollateralTier.STABLE,
                chainlinkConfig: IASSETS.ChainlinkOracleConfig({oracleUSD: USDT_CHAINLINK_ORACLE, active: 1}),
                poolConfig: IASSETS.UniswapPoolConfig({pool: USDT_USDC_POOL, twapPeriod: 1800, active: 1})
            })
        );

        vm.stopPrank();
    }

    function _configureBTC() internal {
        vm.startPrank(address(timelockInstance));

        // Configure BTC.b with USDC pool (no direct BTC/AVAX pool)
        assetsInstance.updateAssetConfig(
            BTC,
            IASSETS.Asset({
                active: 1,
                decimals: 8, // BTC.b has 8 decimals
                borrowThreshold: 700,
                liquidationThreshold: 750,
                maxSupplyThreshold: 500 * 1e8, // 500 BTC
                isolationDebtCap: 0,
                assetMinimumOracles: 1,
                porFeed: address(0),
                primaryOracleType: IASSETS.OracleType.CHAINLINK,
                tier: IASSETS.CollateralTier.CROSS_A,
                chainlinkConfig: IASSETS.ChainlinkOracleConfig({oracleUSD: BTC_CHAINLINK_ORACLE, active: 1}),
                poolConfig: IASSETS.UniswapPoolConfig({pool: BTC_USDC_POOL, twapPeriod: 1800, active: 1})
            })
        );

        vm.stopPrank();
    }

    function _configureWETH() internal {
        vm.startPrank(address(timelockInstance));

        // Configure WETH.e with AVAX pool
        assetsInstance.updateAssetConfig(
            WETH,
            IASSETS.Asset({
                active: 1,
                decimals: 18,
                borrowThreshold: 750,
                liquidationThreshold: 800,
                maxSupplyThreshold: 10_000 ether, // 10,000 WETH
                isolationDebtCap: 0,
                assetMinimumOracles: 1,
                porFeed: address(0),
                primaryOracleType: IASSETS.OracleType.CHAINLINK,
                tier: IASSETS.CollateralTier.CROSS_A,
                chainlinkConfig: IASSETS.ChainlinkOracleConfig({oracleUSD: ETH_CHAINLINK_ORACLE, active: 1}),
                poolConfig: IASSETS.UniswapPoolConfig({pool: WETH_AVAX_POOL, twapPeriod: 1800, active: 1})
            })
        );

        vm.stopPrank();
    }

    function _configureLINK() internal {
        vm.startPrank(address(timelockInstance));

        // Configure LINK.e with AVAX pool
        assetsInstance.updateAssetConfig(
            LINK,
            IASSETS.Asset({
                active: 1,
                decimals: 18,
                borrowThreshold: 650,
                liquidationThreshold: 700,
                maxSupplyThreshold: 100_000 * 1e18, // 100,000 LINK
                isolationDebtCap: 0,
                assetMinimumOracles: 1,
                porFeed: address(0),
                primaryOracleType: IASSETS.OracleType.CHAINLINK,
                tier: IASSETS.CollateralTier.CROSS_A,
                chainlinkConfig: IASSETS.ChainlinkOracleConfig({oracleUSD: LINK_CHAINLINK_ORACLE, active: 1}),
                poolConfig: IASSETS.UniswapPoolConfig({pool: LINK_AVAX_POOL, twapPeriod: 1800, active: 1})
            })
        );

        vm.stopPrank();
    }

    function test_ChainlinkOracleAVAX() public view {
        (uint80 roundId, int256 answer,, uint256 updatedAt,) =
            AggregatorV3Interface(AVAX_CHAINLINK_ORACLE).latestRoundData();

        console2.log("Direct AVAX/USD oracle call:");
        console2.log("  RoundId:", roundId);
        console2.log("  Price:", uint256(answer) / 1e8);
        console2.log("  Updated at:", updatedAt);
    }

    function test_ChainLinkOracleBTC() public view {
        (uint80 roundId, int256 answer,, uint256 updatedAt,) =
            AggregatorV3Interface(BTC_CHAINLINK_ORACLE).latestRoundData();
        console2.log("Direct BTC/USD oracle call:");
        console2.log("  RoundId:", roundId);
        console2.log("  Price:", uint256(answer) / 1e8);
        console2.log("  Updated at:", updatedAt);
    }

    function test_RealMedianPriceAVAX() public {
        // Get prices from both oracles
        uint256 chainlinkPrice = assetsInstance.getAssetPriceByType(WAVAX, IASSETS.OracleType.CHAINLINK);
        uint256 uniswapPrice = assetsInstance.getAssetPriceByType(WAVAX, IASSETS.OracleType.UNISWAP_V3_TWAP);

        console2.log("WAVAX Chainlink price:", chainlinkPrice);
        console2.log("WAVAX Uniswap price:", uniswapPrice);

        // Calculate expected median
        uint256 expectedMedian = (chainlinkPrice + uniswapPrice) / 2;

        // Get actual median
        uint256 actualMedian = assetsInstance.getAssetPrice(WAVAX);
        console2.log("WAVAX median price:", actualMedian);

        assertEq(actualMedian, expectedMedian, "Median calculation should be correct");
    }

    function test_RealMedianPriceBTC() public {
        // Get prices from both oracles
        uint256 chainlinkPrice = assetsInstance.getAssetPriceByType(BTC, IASSETS.OracleType.CHAINLINK);
        uint256 uniswapPrice = assetsInstance.getAssetPriceByType(BTC, IASSETS.OracleType.UNISWAP_V3_TWAP);

        console2.log("BTC.b Chainlink price:", chainlinkPrice);
        console2.log("BTC.b Uniswap price:", uniswapPrice);

        // Calculate expected median
        uint256 expectedMedian = (chainlinkPrice + uniswapPrice) / 2;

        // Get actual median
        uint256 actualMedian = assetsInstance.getAssetPrice(BTC);
        console2.log("BTC.b median price:", actualMedian);

        assertEq(actualMedian, expectedMedian, "Median calculation should be correct");
    }

    function test_RealMedianPriceLINK() public {
        // Get prices from both oracles
        uint256 chainlinkPrice = assetsInstance.getAssetPriceByType(LINK, IASSETS.OracleType.CHAINLINK);
        uint256 uniswapPrice = assetsInstance.getAssetPriceByType(LINK, IASSETS.OracleType.UNISWAP_V3_TWAP);

        console2.log("LINK.e Chainlink price:", chainlinkPrice);
        console2.log("LINK.e Uniswap price:", uniswapPrice);

        // Calculate expected median
        uint256 expectedMedian = (chainlinkPrice + uniswapPrice) / 2;

        // Get actual median
        uint256 actualMedian = assetsInstance.getAssetPrice(LINK);
        console2.log("LINK.e median price:", actualMedian);

        assertEq(actualMedian, expectedMedian, "Median calculation should be correct");
    }

    function testRevert_PoolLiquidityLimitReached() public {
        // Convert AVAX to WAVAX for testing
        vm.startPrank(testUser);
        (bool success,) = WAVAX.call{value: 500 ether}("");
        require(success, "AVAX to WAVAX conversion failed");

        // Create a position
        uint256 positionId = marketCoreInstance.createPosition(WAVAX, false);
        console2.log("Created position ID:", positionId);
        vm.stopPrank();

        // Set maxSupplyThreshold high to avoid hitting AssetCapacityReached
        vm.startPrank(address(timelockInstance));
        IASSETS.Asset memory wavaxConfig = assetsInstance.getAssetInfo(WAVAX);
        wavaxConfig.maxSupplyThreshold = 1_000_000 ether;
        assetsInstance.updateAssetConfig(WAVAX, wavaxConfig);
        vm.stopPrank();

        // Get actual WAVAX balance in the AVAX/USDC pool
        uint256 poolWavaxBalance = IERC20(WAVAX).balanceOf(AVAX_USDC_POOL);
        console2.log("WAVAX balance in pool:", poolWavaxBalance / 1e18, "AVAX");

        // Calculate 3% of pool balance
        uint256 threePercentOfPool = (poolWavaxBalance * 3) / 100;
        console2.log("3% of pool WAVAX:", threePercentOfPool / 1e18, "AVAX");

        // Add extra to ensure we exceed the limit
        uint256 supplyAmount = threePercentOfPool + 1 ether;
        console2.log("Amount to supply:", supplyAmount / 1e18, "AVAX");

        // Verify this will trigger the limit
        bool willHitLimit = assetsInstance.poolLiquidityLimit(WAVAX, supplyAmount);
        console2.log("Will hit pool liquidity limit:", willHitLimit);
        assertTrue(willHitLimit, "Our calculated amount should trigger pool liquidity limit");

        // Supply amount exceeding 3% of pool balance
        vm.startPrank(testUser);
        IERC20(WAVAX).approve(address(marketCoreInstance), supplyAmount);
        vm.expectRevert(IPROTOCOL.PoolLiquidityLimitReached.selector);
        marketCoreInstance.supplyCollateral(WAVAX, supplyAmount, positionId);
        vm.stopPrank();

        console2.log("Successfully tested PoolLiquidityLimitReached error");
    }

    function test_getAnyPoolTokenPriceInUSD_AVAXUSDC() public {
        uint256 avaxPriceInUSD = assetsInstance.getAssetPrice(WAVAX);
        console2.log("AVAX price in USD (from AVAX/USDC pool):", avaxPriceInUSD);

        // Assert that the price is within a reasonable range (e.g., $20 to $100)
        assertTrue(avaxPriceInUSD > 19 * 1e6, "AVAX price should be greater than $19");
        assertTrue(avaxPriceInUSD < 22 * 1e6, "AVAX price should be less than $22");
    }

    function test_getAnyPoolTokenPriceInUSD_BTCUSDC() public {
        uint256 btcPriceInUSD = assetsInstance.getAssetPrice(BTC);
        console2.log("BTC.b price in USD (from BTC/USDC pool):", btcPriceInUSD);

        // Assert that the price is within a reasonable range (e.g., $90,000 to $120,000)
        assertTrue(btcPriceInUSD > 90000 * 1e6, "BTC.b price should be greater than $90,000");
        assertTrue(btcPriceInUSD < 120000 * 1e6, "BTC.b price should be less than $120,000");
    }

    function test_getAnyPoolTokenPriceInUSD_LINKAVAX() public {
        uint256 linkPriceInUSD = assetsInstance.getAssetPrice(LINK);
        console2.log("LINK.e price in USD (from LINK/AVAX pool):", linkPriceInUSD);

        // Assert that the price is within a reasonable range (e.g., $10 to $30)
        assertTrue(linkPriceInUSD > 10 * 1e6, "LINK.e price should be greater than $10");
        assertTrue(linkPriceInUSD < 30 * 1e6, "LINK.e price should be less than $30");
    }

    function test_getAnyPoolTokenPriceInUSD_WETHAVAX() public {
        uint256 wethPriceInUSD = assetsInstance.getAssetPrice(WETH);
        console2.log("WETH.e price in USD (from WETH/AVAX pool):", wethPriceInUSD);

        // Assert that the price is within a reasonable range (e.g., $3000 to $5000)
        assertTrue(wethPriceInUSD > 2500 * 1e6, "WETH.e price should be greater than $3000");
        assertTrue(wethPriceInUSD < 2600 * 1e6, "WETH.e price should be less than $5000");
    }
}
