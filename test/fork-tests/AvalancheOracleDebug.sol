// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {IUniswapV3Pool} from "../../contracts/interfaces/IUniswapV3Pool.sol";
import {UniswapTickMath} from "../../contracts/markets/lib/UniswapTickMath.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {AggregatorV3Interface} from
    "../../contracts/vendor/@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract AvalancheOracleDebug is Test {
    // Avalanche mainnet addresses from networks.json
    address constant USDC = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;
    address constant USDT = 0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7;
    address constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address constant BTC = 0x152b9d0FdC40C096757F570A51E494bd4b943E50;
    address constant WETH = 0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB;
    address constant LINK = 0x5947BB275c521040051D82396192181b413227A3;

    // Pools from networks.json
    address constant USDT_USDC_POOL = 0x804226cA4EDb38e7eF56D16d16E92dc3223347A0;
    address constant AVAX_USDC_POOL = 0xfAe3f424a0a47706811521E3ee268f00cFb5c45E;
    address constant BTC_USDC_POOL = 0xD1356d360F37932059E5b89b7992692aA234EDA6;
    address constant WETH_AVAX_POOL = 0x7b602f98D71715916E7c963f51bfEbC754aDE2d0;
    address constant LINK_AVAX_POOL = 0xEB7e0191f4054868D97F33CA7a4176b226cCBd2F;

    // Chainlink oracles from networks.json
    address constant USDC_CHAINLINK_ORACLE = 0xF096872672F44d6EBA71458D74fe67F9a77a23B9;
    address constant USDT_CHAINLINK_ORACLE = 0xEBE676ee90Fe1112671f19b6B7459bC678B67e8a;
    address constant AVAX_CHAINLINK_ORACLE = 0x0A77230d17318075983913bC2145DB16C7366156;
    address constant BTC_CHAINLINK_ORACLE = 0x86442E3a98558357d46E6182F4b262f76c4fa26F;
    address constant ETH_CHAINLINK_ORACLE = 0x976B3D034E162d8bD72D6b9C989d545b839003b0;
    address constant LINK_CHAINLINK_ORACLE = 0x49ccd9ca821EfEab2b98c60dC60F518E765EDe9a;

    uint32 public constant TWAP_PERIOD = 1800; // 30 minutes

    uint256 avalancheFork;

    function setUp() public {
        // Fork Avalanche mainnet at current block
        avalancheFork = vm.createFork("mainnet", 63997026);
        vm.selectFork(avalancheFork);
        console2.log("=== Avalanche Oracle & Pool Debug ===");
        console2.log("Forked at block: 63997026");
        console2.log("Current block timestamp:", block.timestamp);
    }

    function test_AllChainlinkOracles() public view {
        console2.log("\n=== Chainlink Oracle Status ===");

        _debugChainlinkOracle("USDC", USDC_CHAINLINK_ORACLE);
        _debugChainlinkOracle("USDT", USDT_CHAINLINK_ORACLE);
        _debugChainlinkOracle("AVAX", AVAX_CHAINLINK_ORACLE);
        _debugChainlinkOracle("BTC", BTC_CHAINLINK_ORACLE);
        _debugChainlinkOracle("ETH", ETH_CHAINLINK_ORACLE);
        _debugChainlinkOracle("LINK", LINK_CHAINLINK_ORACLE);
    }

    function test_AllUniswapPools() public view {
        console2.log("\n=== Uniswap V3 Pool Status ===");

        _debugUniswapPool("USDT/USDC", USDT_USDC_POOL, USDT, USDC);
        _debugUniswapPool("AVAX/USDC", AVAX_USDC_POOL, WAVAX, USDC);
        _debugUniswapPool("BTC/USDC", BTC_USDC_POOL, BTC, USDC);
        _debugUniswapPool("WETH/AVAX", WETH_AVAX_POOL, WETH, WAVAX);
        _debugUniswapPool("LINK/AVAX", LINK_AVAX_POOL, LINK, WAVAX);
    }

    function test_OracleVsPoolPrices() public view {
        console2.log("\n=== Oracle vs Pool Price Comparison ===");

        // For tokens that have both Chainlink and Uniswap data
        _compareOracleVsPool("USDC", USDC_CHAINLINK_ORACLE, USDT_USDC_POOL, USDC, USDT);
        _compareOracleVsPool("AVAX", AVAX_CHAINLINK_ORACLE, AVAX_USDC_POOL, WAVAX, USDC);
        _compareOracleVsPool("BTC", BTC_CHAINLINK_ORACLE, BTC_USDC_POOL, BTC, USDC);
    }

    function _debugChainlinkOracle(string memory name, address oracle) internal view {
        console2.log(string.concat("\n--- ", name, " Oracle ---"));
        console2.log("Oracle Address:", oracle);

        try AggregatorV3Interface(oracle).latestRoundData() returns (
            uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound
        ) {
            console2.log("RoundId:", roundId);
            console2.log("Price (8 decimals):", uint256(answer));
            console2.log("Updated at:", updatedAt);
            console2.log("Staleness (seconds):", block.timestamp - updatedAt);
            console2.log("Is stale (>8hrs)?", (block.timestamp - updatedAt) > 28800);
            console2.log("Started at:", startedAt);
            console2.log("Answered in round:", answeredInRound);
        } catch {
            console2.log("ERROR: Oracle call failed");
        }
    }

    function _debugUniswapPool(string memory name, address pool, address expectedToken0, address expectedToken1)
        internal
        view
    {
        console2.log(string.concat("\n--- ", name, " Pool ---"));
        console2.log("Pool Address:", pool);

        try IUniswapV3Pool(pool).token0() returns (address token0) {
            address token1 = IUniswapV3Pool(pool).token1();

            console2.log("Token0:", token0);
            console2.log("Token1:", token1);
            console2.log("Expected Token0:", expectedToken0);
            console2.log("Expected Token1:", expectedToken1);
            console2.log("Tokens match expected:", token0 == expectedToken0 && token1 == expectedToken1);

            // Check decimals
            uint8 decimals0 = IERC20Metadata(token0).decimals();
            uint8 decimals1 = IERC20Metadata(token1).decimals();
            console2.log("Token0 decimals:", decimals0);
            console2.log("Token1 decimals:", decimals1);

            // Try to get TWAP price
            try this.getTWAPPrice(pool, true, 10 ** decimals0) returns (uint256 price) {
                console2.log("TWAP price (token0/token1):", price);
            } catch {
                console2.log("TWAP price: FAILED");
            }
        } catch {
            console2.log("ERROR: Pool call failed");
        }
    }

    function _compareOracleVsPool(string memory name, address oracle, address pool, address token, address quoteToken)
        internal
        view
    {
        console2.log(string.concat("\n--- ", name, " Comparison ---"));

        // Get Chainlink price
        try AggregatorV3Interface(oracle).latestRoundData() returns (
            uint80, int256 answer, uint256, uint256 updatedAt, uint80
        ) {
            uint256 chainlinkPrice = uint256(answer);
            bool isStale = (block.timestamp - updatedAt) > 28800;
            // Chainlink returns 1e8, normalize to 1e6 for comparison
            uint256 chainlinkNormalized = chainlinkPrice / 100; // 1e8 -> 1e6
            console2.log("Chainlink price:", chainlinkNormalized);
            console2.log("Chainlink stale:", isStale);

            // Get pool price if oracle is not stale
            if (!isStale) {
                // For AVAX, we want token0/token1 (WAVAX/USDC) so zeroForOne = true
                bool zeroForOne = (token == WAVAX) ? true : (token < quoteToken);
                console2.log("Using zeroForOne:", zeroForOne);

                // Use correct decimals for baseAmount
                uint8 tokenDecimals = IERC20Metadata(token).decimals();
                uint256 baseAmount = 10 ** tokenDecimals;
                console2.log("Token decimals:", tokenDecimals);
                console2.log("Base amount:", baseAmount);

                try this.getTWAPPrice(pool, zeroForOne, baseAmount) returns (uint256 poolPrice) {
                    // getRawPrice returns 1e6, so use directly
                    console2.log("Pool TWAP price (raw):", poolPrice);
                    console2.log("Pool TWAP price (1e6):", poolPrice);

                    // Calculate difference (both now in 1e6)
                    if (chainlinkNormalized > 0 && poolPrice > 0) {
                        uint256 diff = chainlinkNormalized > poolPrice
                            ? chainlinkNormalized - poolPrice
                            : poolPrice - chainlinkNormalized;
                        uint256 diffPercent = (diff * 100) / chainlinkNormalized;
                        console2.log("Price difference:", diffPercent, "%");
                    }
                } catch Error(string memory reason) {
                    console2.log("Pool TWAP failed:", reason);
                } catch {
                    console2.log("Pool TWAP price: 0 (unknown error)");
                }
            }
        } catch {
            console2.log("Chainlink price: FAILED");
        }
    }

    // External function to handle try/catch with TWAP
    function getTWAPPrice(address pool, bool zeroForOne, uint256 baseAmount) external view returns (uint256) {
        return UniswapTickMath.getRawPrice(IUniswapV3Pool(pool), zeroForOne, baseAmount, TWAP_PERIOD);
    }

    function test_FailingPoolsDebug() public view {
        console2.log("\n=== Failing Pools Debug ===");

        // Test 1: BTCForkTest - USDC in BTC/USDC pool
        console2.log("\n--- BTCForkTest: USDC in BTC/USDC Pool ---");
        _debugFailingPool("BTC/USDC", BTC_USDC_POOL, USDC, BTC);

        // Test 2: USDCForkTest - USDC in USDT/USDC pool (corrected)
        console2.log("\n--- USDCForkTest: USDC in USDT/USDC Pool ---");
        _debugFailingPool("USDT/USDC", USDT_USDC_POOL, USDC, USDT);

        // Compare with working USDT in USDT/USDC pool
        console2.log("\n--- Working: USDT in USDT/USDC Pool ---");
        _debugFailingPool("USDT/USDC", USDT_USDC_POOL, USDT, USDC);
    }

    function _debugFailingPool(string memory poolName, address poolAddr, address targetToken, address otherToken)
        internal
        view
    {
        console2.log(string.concat("Pool: ", poolName));
        console2.log("Pool Address:", poolAddr);
        console2.log("Target Token:", targetToken);
        console2.log("Other Token:", otherToken);

        IUniswapV3Pool pool = IUniswapV3Pool(poolAddr);
        address token0 = pool.token0();
        address token1 = pool.token1();

        console2.log("Pool Token0:", token0);
        console2.log("Pool Token1:", token1);

        bool isToken0 = (targetToken == token0);
        console2.log("Target token is token0:", isToken0);

        uint8 targetDecimals = IERC20Metadata(targetToken).decimals();
        console2.log("Target token decimals:", targetDecimals);

        uint8 otherDecimals = IERC20Metadata(otherToken).decimals();
        console2.log("Other token decimals:", otherDecimals);

        // Call getRawPrice with target token precision
        uint256 baseAmount = 10 ** targetDecimals;
        console2.log("Base amount (10^decimals):", baseAmount);

        try this.getTWAPPrice(poolAddr, isToken0, baseAmount) returns (uint256 rawPrice) {
            console2.log("Raw TWAP price:", rawPrice);

            // Also try with opposite direction
            try this.getTWAPPrice(poolAddr, !isToken0, baseAmount) returns (uint256 oppositePrice) {
                console2.log("Opposite direction price:", oppositePrice);
            } catch {
                console2.log("Opposite direction failed");
            }

            // Try with other token precision
            uint256 otherBaseAmount = 10 ** otherDecimals;
            try this.getTWAPPrice(poolAddr, isToken0, otherBaseAmount) returns (uint256 otherPrecisionPrice) {
                console2.log("Other token precision price:", otherPrecisionPrice);
            } catch {
                console2.log("Other precision failed");
            }
        } catch Error(string memory reason) {
            console2.log("TWAP failed:", reason);
        } catch {
            console2.log("TWAP failed: Unknown error");
        }

        console2.log("---");
    }
}
