// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IUniswapV2Pair {
    function getReserves()
        external
        view
        returns (
            uint256 reserve0,
            uint256 reserve1,
            uint32 blockTimestampLast
        );
}
