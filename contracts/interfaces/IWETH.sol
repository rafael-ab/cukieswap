// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address dst, uint256 wad) external returns (bool);

    function approve(address guy, uint256 wad) external returns (bool);

    function balanceOf(address owner) external returns (uint256);
}
