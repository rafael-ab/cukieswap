// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./balancer/interfaces/IBPool.sol";
import "./balancer/interfaces/IExchangeProxy.sol";
import "./interfaces/IWETH.sol";

import "hardhat/console.sol";

/// @title A Cukie Token Swapper V2
/// @author Rafael Romero
contract CukieSwapV2 is Initializable, ContextUpgradeable {
    using SafeMathUpgradeable for uint256;

    address private weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint32 private AMOUNT_PROPORTION = 10000;
    address public recipient;

    address private _bpool = 0x44Ed13fca4ce66cAa29d03dDE9a74a24802CD6be;
    IBPool bpool;

    address private _exchange = 0x3E66B66Fd1d0b02fDa6C811Da9E0547970DB2f21;
    IExchangeProxy exchange;


    event LogSwap(
        address indexed from,
        address indexed to,
        uint256 amount
    );

    function initializeV2(
        address _recipient
    ) external {
        recipient = _recipient;
        bpool = IBPool(_bpool);
        exchange = IExchangeProxy(_exchange);
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
            require(weth != toTokens[i], "CukieSwap: WETH_ADDRESS_ERROR");
        }
        require(AMOUNT_PROPORTION == sum, "CukieSwap: NOT_PROPORTIONAL");

        uint256 amountIn = msg.value;
        require(amountIn > 0, "CukieSwap: ZERO_AMOUNT");

        // 0.1% of fees
        uint256 fees = amountIn.mul(1).div(1000);
        (bool success, ) = payable(recipient).call{value: fees}("");
        require(success, "CukieSwap: FEES_TRANSACTION_ERROR");
        _swapEthToTokensBAL(
            toTokens, 
            amountIn.sub(fees), 
            amountProportions
        );
    }

    function _swapEthToTokensBAL(
        address[] memory _toTokens,
        uint256 amountIn,
        uint256[] memory amountProportions
    ) internal {
        require(
            _toTokens.length > 0 && amountProportions.length == _toTokens.length,
            "CukieSwap: ZERO_LENGTH_TOKENS"
        );
        IWETH _weth = IWETH(weth);
        _weth.deposit{value: amountIn}();


        uint256 len = _toTokens.length;
        for (uint i = 0; i < len; i++) {
            address _toToken = _toTokens[i];
            uint256 newAmount = amountIn.mul(amountProportions[i]).div(AMOUNT_PROPORTION);
            _weth.approve(_bpool, newAmount);
            (uint256 tokenAmountOut, ) = bpool.swapExactAmountIn(
                weth,
                newAmount,
                _toToken,
                1,
                99999999 * 10 ** 18
            );
            IERC20(_toToken).transfer(_msgSender(), tokenAmountOut);

            emit LogSwap(weth, _toToken, newAmount);
        }
    }
}