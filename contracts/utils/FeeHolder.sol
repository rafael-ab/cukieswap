// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/// @title Fee Holder
/// @author Rafael Romero
contract FeeHolder is Context, Ownable {
    function getBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function withdraw(uint256 amount) external onlyOwner {
        _withdraw(amount);
    }

    function transfer(address to, uint256 amount)
        external
        onlyOwner
        returns (bool success)
    {
        success = _transfer(to, amount);
        require(success, "FeeHolder: TRANSACTION_FAILED");
    }

    function _withdraw(uint256 amount) internal onlyOwner {
        require(address(this).balance >= amount);
        payable(_msgSender()).transfer(amount);
    }

    function _transfer(address to, uint256 amount)
        internal
        onlyOwner
        returns (bool)
    {
        require(address(this).balance >= amount);
        payable(to).transfer(amount);
        return true;
    }

    receive() external payable {}
}
