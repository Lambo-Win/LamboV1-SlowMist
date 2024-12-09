// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

/// @title Utils Contract
/// @notice This contract stores constant values used in the system
contract Utils {
    // Address of the Wrapped ETH (WETH) contract on Base mainnnet
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // Constant for Router
    uint256 public constant POOL_END_TYPE = uint256(1);
    uint256 public constant POOL_NOT_END_TYPE = uint256(0);
    uint256 public constant BUY_QUOTE_TYPE = uint256(1);
    uint256 public constant SELL_QUOTE_TYPE = uint256(0);
    uint256 public constant INITIAL_BUY_LIMIT = 3 ether;
    address public constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

}
