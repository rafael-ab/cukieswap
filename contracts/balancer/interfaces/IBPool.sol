// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IBPool {
    function getNormalizedWeight(address token) external view returns (uint);
    function getBalance(address token) external view returns (uint);
    function setSwapFee(uint swapFee) external;

    function getSpotPrice(
        address tokenIn, 
        address tokenOut
    ) external view returns (uint spotPrice);

    function swapExactAmountIn(
        address tokenIn,
        uint tokenAmountIn,
        address tokenOut,
        uint minAmountOut,
        uint maxPrice
    ) external returns (uint tokenAmountOut, uint spotPriceAfter);

    function calcOutGivenIn(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint tokenAmountIn,
        uint swapFee
    ) external returns (uint tokenAmountOut);

}