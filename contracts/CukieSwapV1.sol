// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "./uniswapv2/interfaces/IUniswapV2Router.sol";
import "./uniswapv2/interfaces/IERC20.sol";

import "hardhat/console.sol";

/// @title A Cukie Token Swapper
/// @author Rafael Romero
contract CukieSwapV1 is Initializable, ContextUpgradeable {
    using SafeMathUpgradeable for uint256;

    IUniswapV2Router public constant router = IUniswapV2Router(
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    );
    address private constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint32 private constant AMOUNT_PROPORTION = 10000;
    address public recipient;

    event LogSwap(
        address indexed from,
        address indexed to,
        uint256 amount
    );

    function initialize(address _recipient) external initializer {
        recipient = payable(_recipient);
    }

    function swapEthToTokens(
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
        _ethToTokens(
            toTokens, 
            amountIn.sub(fees), 
            amountProportions
        );
    }

    function _ethToTokens(
        address[] memory _toTokens,
        uint256 amountIn,
        uint256[] memory amountProportions
    ) internal {
        require(
            _toTokens.length > 0 && amountProportions.length == _toTokens.length,
            "CukieSwap: ZERO_LENGTH_TOKENS"
        );
        
        address[] memory path = new address[](2);
        path[0] = weth;
        uint256 len = _toTokens.length;
        for (uint i = 0; i < len; i++) {
            address _toToken = _toTokens[i];
            uint256 newAmount = amountIn.mul(amountProportions[i]).div(AMOUNT_PROPORTION);
            path[1] = _toToken;
            router.swapExactETHForTokens{value: newAmount}(
                1,
                path,
                _msgSender(),
                block.timestamp + 360
            );
            emit LogSwap(weth, _toToken, newAmount);
        }
    }
}
