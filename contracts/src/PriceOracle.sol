// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IAggregatorV3 {
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

/// @title PriceOracle
/// @notice Values tokens in USD from Chainlink feeds, and refuses to answer
///         when the price behind the answer has gone stale.
///
/// @dev Prices are returned scaled to 1e18 USD per whole token, regardless of
///      the feed's own decimals or the token's. Callers never have to know
///      either, which removes the most common place this kind of code goes
///      wrong by a factor of a million.
///
///      Staleness is configured per feed, not globally. Measured on Robinhood
///      Chain with US markets shut, feed ages ranged from 15 minutes for
///      LINK/USD to 10 hours for RHSPY/USD, with AAPL and TSLA at 29 minutes.
///      A single threshold tight enough for AAPL would reject SPY forever, and
///      one loose enough for SPY would accept an AAPL price nobody is
///      maintaining. See docs/research/STOCK_TOKENS.md.
///
///      This contract deliberately has no fallback. If a feed is stale the
///      call reverts; it does not quietly return the last known figure. Every
///      path that prices money should stop rather than guess.
contract PriceOracle is Ownable {
    struct Feed {
        IAggregatorV3 aggregator;
        /// @dev Oldest answer still accepted, in seconds.
        uint32 maxAge;
        /// @dev Cached from the aggregator at registration.
        uint8 feedDecimals;
        bool set;
    }

    uint256 internal constant WAD = 1e18;

    mapping(address token => Feed) public feeds;

    event FeedSet(address indexed token, address aggregator, uint32 maxAge, string description);
    event FeedRemoved(address indexed token);

    error NoFeed(address token);
    error StalePrice(address token, uint256 updatedAt, uint32 maxAge);
    error BadPrice(address token, int256 answer);
    error ZeroMaxAge();

    constructor(address owner_) Ownable(owner_) {}

    // ---------------------------------------------------------------------
    // Reads
    // ---------------------------------------------------------------------

    /// @notice USD per whole token, scaled to 1e18. Reverts if stale or absent.
    function priceUsd(address token) public view returns (uint256) {
        (uint256 price, uint256 updatedAt) = _read(token);
        Feed memory f = feeds[token];
        if (block.timestamp - updatedAt > f.maxAge) revert StalePrice(token, updatedAt, f.maxAge);
        return price;
    }

    /// @notice The same reading without the freshness check, plus the verdict.
    /// @dev For monitoring and for UI that would rather show a stale number
    ///      labelled stale than show nothing. Never use it to price a trade.
    function priceUsdUnsafe(address token) external view returns (uint256 price, uint256 updatedAt, bool fresh) {
        (price, updatedAt) = _read(token);
        fresh = block.timestamp - updatedAt <= feeds[token].maxAge;
    }

    function isFresh(address token) external view returns (bool) {
        Feed memory f = feeds[token];
        if (!f.set) return false;
        (, int256 answer,, uint256 updatedAt,) = f.aggregator.latestRoundData();
        if (answer <= 0 || updatedAt == 0) return false;
        return block.timestamp - updatedAt <= f.maxAge;
    }

    /// @notice USD value of `amount` units of `token`, scaled to 1e18.
    /// @param amount Raw token units.
    /// @param tokenDecimals Decimals of `token`.
    /// @dev The quantity is passed in rather than read from a balance on
    ///      purpose. Robinhood's stock tokens apply splits through a
    ///      `uiMultiplier`, so `balanceOf` and `balanceOfUI` diverge after a
    ///      split and only the caller knows which one the position is measured
    ///      in. Guessing here would silently double or halve a valuation.
    function valueUsd(address token, uint256 amount, uint8 tokenDecimals) external view returns (uint256) {
        return (priceUsd(token) * amount) / (10 ** tokenDecimals);
    }

    function _read(address token) internal view returns (uint256 price, uint256 updatedAt) {
        Feed memory f = feeds[token];
        if (!f.set) revert NoFeed(token);

        int256 answer;
        (, answer,, updatedAt,) = f.aggregator.latestRoundData();
        if (answer <= 0 || updatedAt == 0) revert BadPrice(token, answer);

        price = (uint256(answer) * WAD) / (10 ** f.feedDecimals);
    }

    // ---------------------------------------------------------------------
    // Configuration
    // ---------------------------------------------------------------------

    /// @dev `maxAge` is per feed and must be set from that feed's observed
    ///      heartbeat. Zero is rejected because it would make the feed
    ///      permanently unusable, which is a silent way to brick a vault.
    function setFeed(address token, address aggregator, uint32 maxAge) external onlyOwner {
        if (maxAge == 0) revert ZeroMaxAge();

        IAggregatorV3 agg = IAggregatorV3(aggregator);
        uint8 dec = agg.decimals();

        // Prove the feed answers before trusting it with money.
        (, int256 answer,, uint256 updatedAt,) = agg.latestRoundData();
        if (answer <= 0 || updatedAt == 0) revert BadPrice(token, answer);

        feeds[token] = Feed({aggregator: agg, maxAge: maxAge, feedDecimals: dec, set: true});
        emit FeedSet(token, aggregator, maxAge, agg.description());
    }

    function removeFeed(address token) external onlyOwner {
        delete feeds[token];
        emit FeedRemoved(token);
    }
}
