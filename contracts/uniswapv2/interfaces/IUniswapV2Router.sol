//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IUniswapV2Router {
  function factory() external pure returns (address);

  function swapExactETHForTokens(
    uint amountOutMin, 
    address[] calldata path, 
    address to, 
    uint deadline
  ) external payable returns (uint[] memory amounts);
}