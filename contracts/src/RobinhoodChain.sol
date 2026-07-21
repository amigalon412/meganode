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
}
