// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";

/// @notice Verified mainnet addresses on Robinhood Chain (chain id 4663).
/// @dev Each address below was confirmed on-chain by reading `name()`/`symbol()`
///      through https://robinhood-rpc.publicnode.com. Do not add an address here
///      without doing the same.
library RobinhoodChain {
    uint256 internal constant CHAIN_ID = 4663;

    /// @dev "Global Dollar" (USDG), 6 decimals. Native stablecoin of the chain.
    address internal constant USDG = 0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168;

    /// @dev "Steakhouse USDG" (steakUSDG), a MetaMorpho ERC-4626 vault curated by
    ///      Steakhouse Financial that allocates USDG across Morpho lending markets.
    ///      This is where the lending leg of the yield actually comes from.
    address internal constant STEAK_USDG = 0xBeEff033F34C046626B8D0A041844C5d1A5409dd;

    // ---------------------------------------------------------------------
    // Stock tokens. All 18 decimals, all BeaconProxies over one shared
    // implementation. Transfers are gated by a blocklist, not an allowlist, so
    // a contract may hold them. See docs/research/STOCK_TOKENS.md for the
    // issuer powers that come with them.
    // ---------------------------------------------------------------------

    address internal constant NVDA = 0xd0601CE157Db5bdC3162BbaC2a2C8aF5320D9EEC;
    address internal constant AAPL = 0xaF3D76f1834A1d425780943C99Ea8A608f8a93f9;
    address internal constant TSLA = 0x322F0929c4625eD5bAd873c95208D54E1c003b2d;
    address internal constant AMZN = 0x12f190a9F9d7D37a250758b26824B97CE941bF54;
    address internal constant AMD = 0x86923f96303D656E4aa86D9d42D1e57ad2023fdC;

    // ---------------------------------------------------------------------
    // Chainlink USD feeds, 8 decimals, standard EACAggregatorProxy.
    //
    // Most feeds exist at two addresses with identical answers; these are the
    // ones read and confirmed. Freshness varies enormously between them, so
    // each is registered with its own maxAge rather than a shared one.
    // ---------------------------------------------------------------------

    address internal constant NVDA_USD_FEED = 0x379EC4f7C378F34a1B47E4F3cbeBCbAC3E8E9F15;
    address internal constant AAPL_USD_FEED = 0x6B22A786bAa607d76728168703a39Ea9C99f2cD0;
    address internal constant TSLA_USD_FEED = 0x4A1166a659A55625345e9515b32adECea5547C38;
    address internal constant AMZN_USD_FEED = 0xD5a1508ceD74c084eBf3cBe853e2C968fB2a651C;
    address internal constant AMD_USD_FEED = 0x943A29E7ae51A4798823ca9eEd2ed533B2A22C72;

    /// @dev A feed for SPY exists (`0x319724394D3A0e3669269846abE664Cd621f9f6A`)
    ///      while no SPY token was found on this chain. A feed is not a
    ///      tradable asset; do not infer the basket from the feed list.

    // ---------------------------------------------------------------------
    // Uniswap v4
    // ---------------------------------------------------------------------

    address internal constant POOL_MANAGER = 0x8366a39CC670B4001A1121B8F6A443A643e40951;

    /// @dev The four basket tokens -- NVDA, AAPL, TSLA and AMZN -- each trade
    ///      against USDG in the standard 0.30% tier with no hook, and in every
    ///      case that pool holds essentially all of the depth. Found by reading
    ///      Initialize logs off the PoolManager and ranking by liquidity; the
    ///      runners-up are one to two orders of magnitude thinner, and the rest
    ///      are traps -- there are pools at 85% and 99.7% fees on these pairs.
    ///
    ///      AMD is the exception, which is why it is not in the basket. Its only
    ///      USDG pool at this tier carries a hook, so this key does not name it,
    ///      and that pool was initialised at a price of 1.0 with zero liquidity
    ///      and has never traded. Do not add AMD to a basket on the assumption
    ///      that it behaves like the others; `BasketPoolsForkTest` pins this.
    uint24 internal constant BASKET_POOL_FEE = 3000;
    int24 internal constant BASKET_POOL_TICK_SPACING = 60;

    /// @notice The USDG pool for a basket token.
    /// @dev The pair is ordered here rather than written out per token: v4 sorts
    ///      currencies by address, and USDG sits in the middle of this set --
    ///      above AMZN and TSLA, below AAPL, AMD and NVDA. Hand-writing five
    ///      keys means getting that backwards for two of them.
    function basketPool(address token) internal pure returns (PoolKey memory) {
        (address c0, address c1) = token < USDG ? (token, USDG) : (USDG, token);
        return PoolKey({
            currency0: Currency.wrap(c0),
            currency1: Currency.wrap(c1),
            fee: BASKET_POOL_FEE,
            tickSpacing: BASKET_POOL_TICK_SPACING,
            hooks: IHooks(address(0))
        });
    }
}
