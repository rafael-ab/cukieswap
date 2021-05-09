// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IExchangeProxy {
    function smartSwapExactIn(
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint totalAmountIn,
        uint minTotalAmountOut,
        uint nPools
    ) external payable returns (uint totalAmountOut);
}