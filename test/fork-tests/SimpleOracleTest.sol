// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {AggregatorV3Interface} from
    "../../contracts/vendor/@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract SimpleOracleTest is Test {
    // Chainlink oracles from networks.json
    address constant USDC_ORACLE = 0xF096872672F44d6EBA71458D74fe67F9a77a23B9;
    address constant AVAX_ORACLE = 0x0A77230d17318075983913bC2145DB16C7366156;
    address constant BTC_ORACLE = 0x86442E3a98558357d46E6182F4b262f76c4fa26F;

    function setUp() public {
        vm.createSelectFork("mainnet", 63997026);
        console2.log("Block timestamp:", block.timestamp);
    }

    function test_USDCOracle() public view {
        console2.log("=== USDC Oracle ===");
        console2.log("Oracle address:", USDC_ORACLE);

        (, int256 answer,, uint256 updatedAt,) = AggregatorV3Interface(USDC_ORACLE).latestRoundData();

        console2.log("Price:", uint256(answer));
        console2.log("Updated at:", updatedAt);
        console2.log("Current time:", block.timestamp);
        console2.log("Staleness (seconds):", block.timestamp - updatedAt);
        console2.log("Stale (>8hrs)?", (block.timestamp - updatedAt) > 28800);
    }

    function test_AVAXOracle() public view {
        console2.log("=== AVAX Oracle ===");
        console2.log("Oracle address:", AVAX_ORACLE);

        (, int256 answer,, uint256 updatedAt,) = AggregatorV3Interface(AVAX_ORACLE).latestRoundData();

        console2.log("Price:", uint256(answer));
        console2.log("Updated at:", updatedAt);
        console2.log("Current time:", block.timestamp);
        console2.log("Staleness (seconds):", block.timestamp - updatedAt);
        console2.log("Stale (>8hrs)?", (block.timestamp - updatedAt) > 28800);
    }

    function test_BTCOracle() public view {
        console2.log("=== BTC Oracle ===");
        console2.log("Oracle address:", BTC_ORACLE);

        (, int256 answer,, uint256 updatedAt,) = AggregatorV3Interface(BTC_ORACLE).latestRoundData();

        console2.log("Price:", uint256(answer));
        console2.log("Updated at:", updatedAt);
        console2.log("Current time:", block.timestamp);
        console2.log("Staleness (seconds):", block.timestamp - updatedAt);
        console2.log("Stale (>8hrs)?", (block.timestamp - updatedAt) > 28800);
    }
}
