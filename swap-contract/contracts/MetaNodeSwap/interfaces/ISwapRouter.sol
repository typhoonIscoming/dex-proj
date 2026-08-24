// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;
pragma abicoder v2;

import "./IPool.sol";

interface ISwapRouter is ISwapCallback {
    event Swap(
        address indexed sender,
        bool zeroForOne,
        uint256 amountIn,
        uint256 amountInRemaining,
        uint256 amountOut
    );

    struct ExactInputParams {
        address tokenIn;
        address tokenOut;
        uint32[] indexPath;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum; // 最小输出数量
        uint160 sqrtPriceLimitX96;
    }

    function exactInput(
        ExactInputParams calldata params
    ) external payable returns (uint256 amountOut);

    struct ExactOutputParams {
        address tokenIn;
        address tokenOut;
        uint32[] indexPath;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    function exactOutput(
        ExactOutputParams calldata params
    ) external payable returns (uint256 amountIn);

    struct QuoteExactInputParams {
        address tokenIn;
        address tokenOut;
        uint32[] indexPath;
        uint256 amountIn;
        uint160 sqrtPriceLimitX96;
    }

    function quoteExactInput(
        QuoteExactInputParams calldata params
    ) external returns (uint256 amountOut);

    struct QuoteExactOutputParams {
        address tokenIn;
        address tokenOut;
        uint32[] indexPath;
        uint256 amountOut;
        uint160 sqrtPriceLimitX96;
    }

    function quoteExactOutput(
        QuoteExactOutputParams calldata params
    ) external returns (uint256 amountIn);

    /// @notice 批量调用 Router 自身方法（Uniswap 风格）：按顺序 delegatecall 执行 data 中的每一项调用数据。
    /// @dev 该方法为 payable，可与需要 ETH/value 的子调用一起使用；返回每个子调用的原始返回值 bytes。
    function multicall(
        bytes[] calldata data
    ) external payable returns (bytes[] memory results);

    /// @notice 将本次调用携带的 ETH 全部包装成 WETH9，WETH 保留在 Router 中，便于后续 multicall 子调用使用。
    function wrapETH() external payable;

    /// @notice 将 Router 持有的全部 WETH9 解包为 ETH 并转给 recipient。
    function unwrapWETH9(
        uint256 amountMinimum,
        address recipient
    ) external payable;

    /// @notice 将 Router 当前持有的 ETH 退回给调用者。
    function refundETH() external payable;

    /// @notice 将 Router 持有的指定 ERC20 全部转给 recipient。
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;

    /// @notice 使用 EIP-2612 permit 为 Router 授权，无需单独发 approve 交易。
    function selfPermit(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    /// @notice 当 allowance 不足时才执行 permit，避免重复签名/调用。
    function selfPermitIfNecessary(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}
