// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IBRegistry {
    function getBestPools(address fromToken, address destToken)
        external
        view
        returns (address[] memory pools);

    function getBestPoolsWithLimit(
        address fromToken,
        address destToken,
        uint256 limit
    ) external view returns (address[] memory pools);
}
