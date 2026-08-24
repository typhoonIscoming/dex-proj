// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

/// @title Multicall
/// @notice 提供同合约上下文的批量调用能力（Uniswap 风格）。
/// @dev 通过 delegatecall(address(this), data[i]) 执行；失败时原样透传 revert data。
abstract contract Multicall {
    function multicall(
        bytes[] calldata data
    ) public payable virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(
                data[i]
            );
            if (!success) {
                assembly {
                    revert(add(result, 0x20), mload(result))
                }
            }
            results[i] = result;
        }
    }
}
