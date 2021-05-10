// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./CukieSwapV1.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IERC20.sol";
import "./balancer/interfaces/IBPool.sol";
import "./uniswapv2/interfaces/IUniswapV2Factory.sol";
import "./uniswapv2/libraries/UniswapV2Library.sol";

import "hardhat/console.sol";

/// @title A Cukie Token Swapper V2
/// @author Rafael Romero
contract CukieSwapV2 is CukieSwapV1 {
    using SafeMathUpgradeable for uint256;

    IWETH public weth;
    address private _bpool;
    IBPool public bpool;

    event BestDexChoosed(
        string name,
        address indexed from,
        address indexed to
    );

    function initializeV2(
        address payable _recipient
    ) external initializer {
        _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        router = IUniswapV2Router(_router);
        _weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        MAX_PROPORTION = 10000;
        recipient = _recipient;
        weth = IWETH(_weth);
        _bpool = 0x44Ed13fca4ce66cAa29d03dDE9a74a24802CD6be;
        bpool = IBPool(_bpool);
    }

    function swapEthToTokenBestDEX(
        address token
    ) external payable {
        require(token != _weth, "CukieSwap: ETH_SAME_ADDRESS");

        uint256 amountIn = msg.value;
        require(amountIn > 0, "CukieSwap: ZERO_AMOUNT");

        uint256 fees = amountIn.div(1000);
        (bool success, ) = recipient.call{value: fees}("");
        require(success, "CukieSwap: FEES_TRANSACTION_ERROR");

        _swapEthToTokenBestDEX(token, amountIn.sub(fees), MAX_PROPORTION);
    }

    function swapEthToTokensBestDEX(
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

        _swapEthToTokensBestDEX(
            toTokens, 
            amountIn.sub(fees), 
            amountProportions
        );
    }

    function _swapEthToTokenBestDEX(
        address token,
        uint256 amount,
        uint256 proportion
    ) internal {
        require(token != _weth, "CukieSwap: ETH_SAME_ADDRESS");   
        require(amount > 0, "CukieSwap: ZERO_AMOUNT");

        string memory name;

        uint256 newAmount = amount.mul(proportion).div(MAX_PROPORTION);

        uint256 amountOutUNI = getTokenAmountOutFromUNI(token, newAmount);
        uint256 amountOutBAL = getTokenAmountOutFromBAL(token, newAmount);

        if (amountOutUNI > amountOutBAL) {
            _swapEthToTokenUNI(
                token,
                amount,
                proportion, 
                block.timestamp + 360
            );
            name = "UniswapV2";
        } else {
            weth.deposit{value: amount}();
            _swapEthToTokenBAL(token, amount, proportion);
            name = "Balancer";
        }

        emit BestDexChoosed(name, _weth, token);
    }

    function _swapEthToTokensBestDEX(
        address[] memory toTokens,
        uint256 amount,
        uint256[] memory amountProportions
    ) internal {
        require(    
            toTokens.length > 0 && amountProportions.length == toTokens.length,
            "CukieSwap: ZERO_LENGTH_TOKENS"
        );

        uint256 len = toTokens.length;
        for(uint i = 0; i < len; i++) {
            _swapEthToTokenBestDEX(
                toTokens[i], 
                amount, 
                amountProportions[i]
            );
        }
    }

    function getTokenAmountOutFromUNI(
        address token,
        uint256 amount
    ) public view returns (uint256) {
        require(token != _weth, "CukieSwap: ETH_SAME_ADDRESS");   
        require(amount > 0, "CukieSwap: ZERO_AMOUNT");

        uint256 compensation = 10 ** 7;

        IUniswapV2Factory factory = IUniswapV2Factory(router.factory());

        address pairAddress = factory.getPair(_weth, token);
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();

        uint256 amountOut = UniswapV2Library.getAmountOut(
            amount,
            reserve0,
            reserve1
        );
        return amountOut.mul(compensation);
    }

    function getTokenAmountOutFromBAL(
        address token,
        uint256 amount
    ) public returns (uint256) {
        require(token != _weth, "CukieSwap: ETH_SAME_ADDRESS");   
        require(amount > 0, "CukieSwap: ZERO_AMOUNT");

        uint256 tokenBalanceIn = bpool.getBalance(_weth);
        uint256 tokenBalanceOut = bpool.getBalance(token);
        uint256 tokenWeightIn = bpool.getNormalizedWeight(_weth);
        uint256 tokenWeightOut = bpool.getNormalizedWeight(token);

        uint256 amountOut = bpool.calcOutGivenIn(
            tokenBalanceIn,
            tokenWeightIn,
            tokenBalanceOut,
            tokenWeightOut,
            amount,
            0
        );
        return amountOut;
    }

    function swapEthToTokenBAL(
        address toToken
    ) external payable {
        require(toToken != _weth, "CukieSwap: ETH_SAME_ADDRESS");   

        uint256 amountIn = msg.value;
        require(amountIn > 0, "CukieSwap: ZERO_AMOUNT");

        uint256 fees = amountIn.div(1000);
        (bool success, ) = recipient.call{value: fees}("");
        require(success, "CukieSwap: FEES_TRANSACTION_ERROR");
        _swapEthToTokenBAL(
            toToken, 
            amountIn.sub(fees), 
            MAX_PROPORTION
        );
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

    function _swapEthToTokenBAL(
        address toToken,
        uint256 amount,
        uint256 proportion
    ) internal {
        require(toToken != _weth, "CukieSwap: ETH_SAME_ADDRESS");
        require(proportion > 0 && proportion <= MAX_PROPORTION, "CukieSwap: PROPORTION_ERROR");

        uint256 newAmount = amount.mul(proportion).div(MAX_PROPORTION);
        if(weth.balanceOf(address(this)) == 0) {
            weth.deposit{value: amount}();
        }
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

    function _swapEthToTokensBAL(
        address[] memory toTokens,
        uint256 amount,
        uint256[] memory amountProportions
    ) internal {
        require(
            toTokens.length > 0 && amountProportions.length == toTokens.length,
            "CukieSwap: ZERO_LENGTH_TOKENS"
        );

        weth.deposit{value: amount}();

        uint256 len = toTokens.length;
        for (uint i = 0; i < len; i++) {
            address toToken = toTokens[i];
            _swapEthToTokenBAL(toToken, amount, amountProportions[i]);
        }
    }
}