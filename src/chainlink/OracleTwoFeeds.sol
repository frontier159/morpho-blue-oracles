// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {IOracle} from "morpho-blue/interfaces/IOracle.sol";

import {AggregatorV3Interface, DataFeedLib} from "./libraries/DataFeedLib.sol";

contract OracleTwoFeeds is IOracle {
    using DataFeedLib for AggregatorV3Interface;

    /* CONSTANT */

    /// @notice Base feed.
    AggregatorV3Interface public immutable BASE_FEED;
    /// @notice Quote feed.
    AggregatorV3Interface public immutable QUOTE_FEED;
    /// @notice Price scale factor, computed at contract creation.
    uint256 public immutable SCALE_FACTOR;

    /* CONSTRUCTOR */

    /// @param baseFeed Base feed. Pass address zero if the price = 1.
    /// @param quoteFeed Quote feed. Pass address zero if the price = 1.
    /// @param baseTokenDecimals Base token decimals.
    /// @param quoteTokenDecimals Quote token decimals.
    constructor(
        AggregatorV3Interface baseFeed,
        AggregatorV3Interface quoteFeed,
        uint256 baseTokenDecimals,
        uint256 quoteTokenDecimals
    ) {
        BASE_FEED = baseFeed;
        QUOTE_FEED = quoteFeed;
        // Let pB be the base price, and pQ the quote price (price of 1e(decimals) asset).
        // Chainlink feeds return pB * bFeedPrecision and pQ * qFeedPrecision.
        // `price()` should return 1e36 * (pB/1e(bDecimals) / (pQ/1e(qDecimals)).
        // Yet `price()` returns pB * 1e(bFeedPrecision) * SCALE_FACTOR / (pQ * 1e(qFeedPrecision))
        // So 1e36 * (pB/1e(bDecimals) / (pQ/1e(qDecimals) = pB*1e(bFeedPrecision) * SCALE_FACTOR /
        // (pQ*1e(qFeedPrecision))
        // So SCALE_FACTOR = 1e36 / 1e(bDecimals) * 1e(qDecimals) * 1e(qFeedPrecision) / 1e(bFeedPrecision)
        //                 = 1e(36 + qDecimals + qFeedPrecision - bDecimals - bFeedPrecision)
        SCALE_FACTOR =
            10 ** (36 + quoteTokenDecimals + quoteFeed.getDecimals() - baseFeed.getDecimals() - baseTokenDecimals);
    }

    /* PRICE */

    /// @inheritdoc IOracle
    function price() external view returns (uint256) {
        return (BASE_FEED.getPrice() * SCALE_FACTOR) / QUOTE_FEED.getPrice();
    }
}
