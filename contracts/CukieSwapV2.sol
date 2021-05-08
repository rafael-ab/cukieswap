// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./CukieSwapV1.sol";

import "hardhat/console.sol";

/// @title A Cukie Token Swapper V2
/// @author Rafael Romero
contract CukieSwapV2 is CukieSwapV1 {

    function initializeV2(address _recipient) external initializer {
        recipient = _recipient;
    }
}