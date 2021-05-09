// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address dst, uint wad) external returns (bool);
    function approve(address guy, uint wad) external returns (bool);
    function balanceOf(address owner) external returns (uint256);
}
