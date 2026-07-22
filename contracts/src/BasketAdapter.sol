// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {PriceOracle} from "./PriceOracle.sol";
import {SwapExecutor} from "./SwapExecutor.sol";

interface IScaledUIToken {
    function uiMultiplier() external view returns (uint256);
}

/// @title BasketAdapter
/// @notice Holds the equity side of a vault and reports what it is worth.
///
/// @dev Assets leave only to the vault that owns this adapter — there is no
///      path that sends them anywhere else, which is what lets the vault's
///      custody claim survive a second leg. Trading is restricted the same way:
///      only the vault may trade, only into registered constituents, and only
///      through the pool the owner fixed for each.
contract BasketAdapter is Ownable, SwapExecutor {
    using SafeERC20 for IERC20;

    uint256 internal constant DENOMINATOR = 1e18;

    struct Constituent {
        uint16 weightBps;
        uint8 decimals;
        /// @dev `uiMultiplier` as of the last time an operator confirmed it.
        uint256 acknowledgedMultiplier;
        bool set;
    }

    PriceOracle public immutable oracle;

    /// @notice The only address assets may be sent to.
    address public immutable vault;

    /// @notice The vault's underlying asset, the other side of every swap.
    address public immutable stable;

    /// @notice The pool each constituent trades in, fixed by the owner.
    /// @dev Routing is configuration, not an argument. If the caller could name
    ///      the pool, a compromised caller could route through one it had just
    ///      created and priced to its liking.
    mapping(address token => PoolKey) public poolKeys;

    address[] public tokens;
    mapping(address token => Constituent) public constituents;

    event ConstituentAdded(address indexed token, uint16 weightBps, uint256 multiplier);
    event ConstituentRemoved(address indexed token);
    event WeightUpdated(address indexed token, uint16 weightBps);
    event MultiplierAcknowledged(address indexed token, uint256 oldMultiplier, uint256 newMultiplier);
    event SentToVault(address indexed token, uint256 amount);
    event PoolSet(address indexed token, address currency0, address currency1, uint24 fee, int24 tickSpacing);
    event Bought(address indexed token, uint256 stableIn, uint256 received);
    event Sold(address indexed token, uint256 amountIn, uint256 stableOut);

    error NotVault();
    error UnknownToken(address token);
    error AlreadyAdded(address token);
    error WeightsExceedTotal(uint256 total);
    error MultiplierChanged(address token, uint256 acknowledged, uint256 current);
    error StillHoldingBalance(address token, uint256 balance);
    error NoPool(address token);
    error PoolAssetMismatch();
    error InsufficientStable(uint256 have, uint256 want);

    modifier onlyVault() {
        if (msg.sender != vault) revert NotVault();
        _;
    }

    constructor(address owner_, PriceOracle oracle_, address vault_, address stable_, IPoolManager poolManager_)
        Ownable(owner_)
        SwapExecutor(poolManager_)
    {
        oracle = oracle_;
        vault = vault_;
        stable = stable_;
    }

    // ---------------------------------------------------------------------
    // Valuation
    // ---------------------------------------------------------------------

    /// @notice USD value of everything held, scaled to 1e18.
    /// @dev Reverts if any price is stale or any split multiplier has moved.
    ///      A basket that cannot be valued honestly must not be valued at all —
    ///      the number feeds a share price.
    function totalValueUsd() external view returns (uint256 total) {
        uint256 n = tokens.length;
        for (uint256 i; i < n; ++i) {
            total += valueOf(tokens[i]);
        }
    }

    /// @notice USD value of one holding, scaled to 1e18.
    function valueOf(address token) public view returns (uint256) {
        Constituent memory c = constituents[token];
        if (!c.set) revert UnknownToken(token);
        _requireMultiplierUnchanged(token, c);

        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance == 0) return 0;
        return oracle.valueUsd(token, balance, c.decimals);
    }

    /// @notice Raw balance held of each constituent, in the same order as `tokens`.
    function holdings() external view returns (address[] memory addrs, uint256[] memory balances) {
        addrs = tokens;
        balances = new uint256[](addrs.length);
        for (uint256 i; i < addrs.length; ++i) {
            balances[i] = IERC20(addrs[i]).balanceOf(address(this));
        }
    }

    function tokensLength() external view returns (uint256) {
        return tokens.length;
    }

    /// @notice True when every constituent can be priced right now.
    /// @dev Lets a caller check before attempting something that would revert.
    function isValuable() external view returns (bool) {
        uint256 n = tokens.length;
        for (uint256 i; i < n; ++i) {
            address token = tokens[i];
            Constituent memory c = constituents[token];
            if (IScaledUIToken(token).uiMultiplier() != c.acknowledgedMultiplier) return false;
            if (!oracle.isFresh(token)) return false;
        }
        return true;
    }

    // ---------------------------------------------------------------------
    // Moving assets
    // ---------------------------------------------------------------------

    /// @notice Send part of a holding to the vault, for in-kind redemption.
    /// @dev The vault is the only possible destination, and it is immutable.
    function sendToVault(address token, uint256 amount) external onlyVault {
        if (!constituents[token].set) revert UnknownToken(token);
        IERC20(token).safeTransfer(vault, amount);
        emit SentToVault(token, amount);
    }

    /// @notice Send a pro-rata slice of every holding to the vault.
    /// @param shareNum Numerator of the fraction being redeemed.
    /// @param shareDen Denominator of the fraction being redeemed.
    /// @dev In-kind exit needs no price, so it deliberately does not consult
    ///      the oracle. It keeps working when feeds are stale and when the
    ///      equity market is shut, which is exactly when it matters most.
    function sendSliceToVault(uint256 shareNum, uint256 shareDen)
        external
        onlyVault
        returns (address[] memory addrs, uint256[] memory amounts)
    {
        addrs = tokens;
        amounts = new uint256[](addrs.length);
        for (uint256 i; i < addrs.length; ++i) {
            IERC20 token = IERC20(addrs[i]);
            uint256 amount = (token.balanceOf(address(this)) * shareNum) / shareDen;
            amounts[i] = amount;
            if (amount > 0) {
                token.safeTransfer(vault, amount);
                emit SentToVault(addrs[i], amount);
            }
        }
    }

    // ---------------------------------------------------------------------
    // Trading
    //
    // Only the vault can trade, only into registered constituents, and only
    // through the pool the owner fixed for each. `minOut` is supplied by the
    // caller and enforced on the amount actually received.
    // ---------------------------------------------------------------------

    /// @notice Spend stablecoin already sitting here on `token`.
    function buy(address token, uint256 stableIn, uint256 minOut)
        external
        virtual
        onlyVault
        returns (uint256 received)
    {
        if (!constituents[token].set) revert UnknownToken(token);
        uint256 have = IERC20(stable).balanceOf(address(this));
        if (have < stableIn) revert InsufficientStable(have, stableIn);

        received = _swapVia(token, stable, stableIn, minOut);
        emit Bought(token, stableIn, received);
    }

    /// @notice Sell `amountIn` of `token` and forward the proceeds to the vault.
    function sell(address token, uint256 amountIn, uint256 minOut)
        external
        virtual
        onlyVault
        returns (uint256 stableOut)
    {
        if (!constituents[token].set) revert UnknownToken(token);

        stableOut = _swapVia(token, token, amountIn, minOut);
        IERC20(stable).safeTransfer(vault, stableOut);
        emit Sold(token, amountIn, stableOut);
    }

    /// @notice Return stablecoin held here to the vault.
    /// @dev Covers a `buy` that spent less than was sent over.
    function sweepStableToVault() external onlyVault returns (uint256 amount) {
        amount = IERC20(stable).balanceOf(address(this));
        if (amount > 0) IERC20(stable).safeTransfer(vault, amount);
    }

    function _swapVia(address token, address inputToken, uint256 amountIn, uint256 minOut) internal returns (uint256) {
        PoolKey memory key = poolKeys[token];
        if (Currency.unwrap(key.currency0) == address(0) && Currency.unwrap(key.currency1) == address(0)) {
            revert NoPool(token);
        }
        bool zeroForOne = Currency.unwrap(key.currency0) == inputToken;
        return _executeSwap(SwapRequest({key: key, zeroForOne: zeroForOne, amountIn: amountIn, minAmountOut: minOut}));
    }

    // ---------------------------------------------------------------------
    // Configuration
    // ---------------------------------------------------------------------

    /// @dev Rejects a pool that is not exactly this token against the stable,
    ///      so a mis-typed key cannot quietly point trading at another market.
    function setPool(address token, PoolKey calldata key) external onlyOwner {
        if (!constituents[token].set) revert UnknownToken(token);
        address c0 = Currency.unwrap(key.currency0);
        address c1 = Currency.unwrap(key.currency1);
        bool pairMatches = (c0 == stable && c1 == token) || (c0 == token && c1 == stable);
        if (!pairMatches) revert PoolAssetMismatch();

        poolKeys[token] = key;
        emit PoolSet(token, c0, c1, key.fee, key.tickSpacing);
    }

    function addConstituent(address token, uint16 weightBps) external onlyOwner {
        if (constituents[token].set) revert AlreadyAdded(token);

        uint256 multiplier = IScaledUIToken(token).uiMultiplier();
        constituents[token] = Constituent({
            weightBps: weightBps,
            decimals: IERC20Metadata(token).decimals(),
            acknowledgedMultiplier: multiplier,
            set: true
        });
        tokens.push(token);
        _requireWeightsSane();

        emit ConstituentAdded(token, weightBps, multiplier);
    }

    function setWeight(address token, uint16 weightBps) external onlyOwner {
        if (!constituents[token].set) revert UnknownToken(token);
        constituents[token].weightBps = weightBps;
        _requireWeightsSane();
        emit WeightUpdated(token, weightBps);
    }

    /// @dev Refuses while a balance remains, so a position cannot be orphaned
    ///      into an adapter that no longer counts it.
    function removeConstituent(address token) external onlyOwner {
        if (!constituents[token].set) revert UnknownToken(token);
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance != 0) revert StillHoldingBalance(token, balance);

        uint256 n = tokens.length;
        for (uint256 i; i < n; ++i) {
            if (tokens[i] == token) {
                tokens[i] = tokens[n - 1];
                tokens.pop();
                break;
            }
        }
        delete constituents[token];
        emit ConstituentRemoved(token);
    }

    /// @notice Accept a new split multiplier and resume valuing this token.
    /// @dev The stock tokens schedule multiplier changes and apply them by
    ///      timestamp, so one can take effect with no transaction of ours.
    ///      `balanceOf` is unchanged by it while `balanceOfUI` moves, and which
    ///      of the two the price feed refers to is not something to guess at
    ///      with a share price downstream. So valuation halts on any change and
    ///      an operator has to look before it resumes.
    function acknowledgeMultiplier(address token) external onlyOwner {
        Constituent storage c = constituents[token];
        if (!c.set) revert UnknownToken(token);

        uint256 current = IScaledUIToken(token).uiMultiplier();
        uint256 old = c.acknowledgedMultiplier;
        c.acknowledgedMultiplier = current;
        emit MultiplierAcknowledged(token, old, current);
    }

    // ---------------------------------------------------------------------

    function _requireMultiplierUnchanged(address token, Constituent memory c) internal view {
        uint256 current = IScaledUIToken(token).uiMultiplier();
        if (current != c.acknowledgedMultiplier) {
            revert MultiplierChanged(token, c.acknowledgedMultiplier, current);
        }
    }

    function _requireWeightsSane() internal view {
        uint256 total;
        uint256 n = tokens.length;
        for (uint256 i; i < n; ++i) {
            total += constituents[tokens[i]].weightBps;
        }
        if (total > 10_000) revert WeightsExceedTotal(total);
    }
}
