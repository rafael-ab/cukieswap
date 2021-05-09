// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

//import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
//import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
//import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "./CukieSwapV1.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IERC20.sol";
import "./balancer/interfaces/IBPool.sol";

import "hardhat/console.sol";

/// @title A Cukie Token Swapper V2
/// @author Rafael Romero
contract CukieSwapV2 is CukieSwapV1 {
    using SafeMathUpgradeable for uint256;

    address private _bpool = 0x44Ed13fca4ce66cAa29d03dDE9a74a24802CD6be;
    IBPool bpool;

    function initializeV2(
        address payable _recipient
    ) external {
        _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        router = IUniswapV2Router(_router);
        _weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        MAX_PROPORTION = 10000;
        recipient = _recipient;
        bpool = IBPool(_bpool);
    }

    function swapEthToTokensBAL(
        address[] memory toTokens,
        uint256[] memory amountProportions
    ) external payable {
        require(
            toTokens.length > 0 && amountProportions.length == toTokens.length,
            "CukieSwap: ZERO_LENGTH_TOKENS"
        );

        uint256 sum = 0;
        uint256 len = amountProportions.length;
        for (uint i; i < len; i++) {
            sum = sum.add(amountProportions[i]);
        }
        require(MAX_PROPORTION == sum, "CukieSwap: AMOUNT_PROPORTION_ERROR");

        uint256 amountIn = msg.value;
        require(amountIn > 0, "CukieSwap: ZERO_AMOUNT");

        // 0.1% of fees
        uint256 fees = amountIn.div(1000);
        (bool success, ) = recipient.call{value: fees}("");
        require(success, "CukieSwap: FEES_TRANSACTION_ERROR");
        _swapEthToTokensBAL(
            toTokens, 
            amountIn.sub(fees), 
            amountProportions
        );
    }

    function _swapEthToTokensBAL(
        address[] memory toTokens,
        uint256 amount,
        uint256[] memory amountProportions
    ) internal {
        require(
            toTokens.length > 0 && amountProportions.length == toTokens.length,
            "CukieSwap: ZERO_LENGTH_TOKENS"
        );
        IWETH weth = IWETH(_weth);
        weth.deposit{value: amount}();


        uint256 len = toTokens.length;
        for (uint i = 0; i < len; i++) {
            address toToken = toTokens[i];
            uint256 newAmount = amount.mul(amountProportions[i]).div(MAX_PROPORTION);
            weth.approve(_bpool, newAmount);
            (uint256 tokenAmountOut, ) = bpool.swapExactAmountIn(
                _weth,
                newAmount,
                toToken,
                1,
                99999999 * 10 ** 18
            );
            IERC20(toToken).transfer(_msgSender(), tokenAmountOut);

            emit LogSwap(_weth, toToken, newAmount);
        }
    }
}