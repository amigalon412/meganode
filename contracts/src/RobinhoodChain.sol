// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

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
}
