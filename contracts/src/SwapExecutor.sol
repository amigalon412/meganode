// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {IUnlockCallback} from "v4-core/src/interfaces/callback/IUnlockCallback.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {TickMath} from "v4-core/src/libraries/TickMath.sol";

/// @title SwapExecutor
/// @notice Exact-input swaps through the Uniswap v4 singleton.
///
/// @dev v4 has no per-pair pool contract. A caller asks the manager to `unlock`,
///      the manager calls back, and inside that callback the swap is performed
///      and the resulting balance delta is settled — pay what is owed, take what
///      is due. Everything below exists to do that one round trip correctly.
///
///      `minAmountOut` is checked here, on the amount actually received, rather
///      than being left to the price limit. A price limit bounds where the swap
///      stops; it does not promise what arrives.
abstract contract SwapExecutor is IUnlockCallback {
    using SafeERC20 for IERC20;

    struct SwapRequest {
        PoolKey key;
        bool zeroForOne;
        uint256 amountIn;
        uint256 minAmountOut;
    }

    IPoolManager public immutable poolManager;

    error NotPoolManager();
    error InsufficientOutput(uint256 received, uint256 minimum);
    error NothingReceived();

    constructor(IPoolManager poolManager_) {
        poolManager = poolManager_;
    }

    /// @notice Swap `amountIn` of the input side for at least `minAmountOut`.
    /// @dev Virtual so a test can substitute a deterministic fill and measure
    ///      the decision around the swap rather than the venue.
    function _executeSwap(SwapRequest memory req) internal virtual returns (uint256 amountOut) {
        bytes memory result = poolManager.unlock(abi.encode(req));
        amountOut = abi.decode(result, (uint256));
    }

    /// @inheritdoc IUnlockCallback
    function unlockCallback(bytes calldata data) external returns (bytes memory) {
        if (msg.sender != address(poolManager)) revert NotPoolManager();

        SwapRequest memory req = abi.decode(data, (SwapRequest));

        // Negative amountSpecified means exact input. The price limit is pushed
        // to the extreme so the swap is bounded by minAmountOut below, not by a
        // limit that would silently return a partial fill instead of reverting.
        BalanceDelta delta = poolManager.swap(
            req.key,
            IPoolManager.SwapParams({
                zeroForOne: req.zeroForOne,
                amountSpecified: -int256(req.amountIn),
                sqrtPriceLimitX96: req.zeroForOne ? TickMath.MIN_SQRT_PRICE + 1 : TickMath.MAX_SQRT_PRICE - 1
            }),
            ""
        );

        (Currency input, Currency output) =
            req.zeroForOne ? (req.key.currency0, req.key.currency1) : (req.key.currency1, req.key.currency0);

        int256 inputDelta = req.zeroForOne ? delta.amount0() : delta.amount1();
        int256 outputDelta = req.zeroForOne ? delta.amount1() : delta.amount0();

        // What we owe the pool, paid by sync-transfer-settle.
        if (inputDelta < 0) {
            uint256 owed = uint256(-inputDelta);
            poolManager.sync(input);
            IERC20(Currency.unwrap(input)).safeTransfer(address(poolManager), owed);
            poolManager.settle();
        }

        if (outputDelta <= 0) revert NothingReceived();
        uint256 received = uint256(outputDelta);
        if (received < req.minAmountOut) revert InsufficientOutput(received, req.minAmountOut);

        poolManager.take(output, address(this), received);

        return abi.encode(received);
    }
}
