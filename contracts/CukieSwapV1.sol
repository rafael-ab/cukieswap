// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "./uniswapv2/interfaces/IUniswapV2Router.sol";

import "hardhat/console.sol";

/// @title A Cukie Token Swapper
/// @author Rafael Romero
contract CukieSwapV1 is Initializable, ContextUpgradeable {
    using SafeMathUpgradeable for uint256;

    address private _router;
    IUniswapV2Router public router;
    address private _weth;
    uint32 private MAX_PROPORTION;
    address payable public recipient;

    event LogSwap(
        address indexed from,
        address indexed to,
        uint256 amount
    );

    function initialize(address payable _recipient) external initializer {
        _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        router = IUniswapV2Router(_router);
        _weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        MAX_PROPORTION = 10000;
        recipient = _recipient;
    }

    function swapEthToToken(
        address toToken
    ) external payable {
        require(toToken != _weth, "CukieSwap: ETH_SAME_ADDRESS");

        uint256 amountIn = msg.value;
        require(amountIn > 0, "CukieSwap: ZERO_AMOUNT");

        uint256 fees = amountIn.div(1000);
        (bool success, ) = recipient.call{value: fees}("");
        require(success, "CukieSwap: FEES_TRANSACTION_ERROR");

        _swapEthToTokenUNI(
            toToken, 
            amountIn.sub(fees), 
            MAX_PROPORTION, 
            block.timestamp + 360
        );
    }


    function swapEthToTokensUNI(
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
        _swapEthToTokensUNI(
            toTokens, 
            amountIn.sub(fees), 
            amountProportions,
            block.timestamp + 360
        );
    }

    function _swapEthToTokenUNI(
        address toToken,
        uint256 amount,
        uint256 proportion,
        uint256 deadline 
    ) internal {
        require(toToken != _weth, "CukieSwap: ETH_SAME_ADDRESS");
        require(proportion > 0 && proportion <= MAX_PROPORTION, "CukieSwap: PROPORTION_ERROR");
        require(deadline > block.timestamp, "CukieSwap: INVALID_DEADLINE");

        address[] memory path = new address[](2);
        path[0] = _weth;
        path[1] = toToken;
        uint256 newAmount = amount.mul(proportion).div(MAX_PROPORTION);
        router.swapExactETHForTokens{value: newAmount}(
            1,
            path,
            _msgSender(),
            deadline
        );
        emit LogSwap(_weth, toToken, newAmount);
    }

    function _swapEthToTokensUNI(
        address[] memory toTokens,
        uint256 amountIn,
        uint256[] memory amountProportions,
        uint256 deadline
    ) internal {
        require(
            toTokens.length > 0 && amountProportions.length == toTokens.length,
            "CukieSwap: ZERO_LENGTH_TOKENS"
        );
        
        uint256 len = toTokens.length;
        for (uint i = 0; i < len; i++) {
            _swapEthToTokenUNI(
                toTokens[i], 
                amountIn, 
                amountProportions[i], 
                deadline
            );
        }
    }
}
