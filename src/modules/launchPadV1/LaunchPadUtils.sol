// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {Utils} from "../../Utils.sol";

/// @title LaunchPadUtils Contract
/// @notice This contract stores constant values used in the LaunchPad system
contract LaunchPadUtils is Utils{

    /// @notice  The max amount of uint256 
    uint256 public constant MAX_AMOUNT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    /// @notice Offset amount for X
    uint256 public constant X_OFFSET_AMOUNT = 3.15 * 10**18;
    
    /// @notice Offset amount for Y
    uint256 public constant Y_OFFSET_AMOUNT = 0.525 * 10**18;
    
    /// @notice Terminal left amount for the quote token
    uint256 public constant QUOTE_TERMINAL_LEFT_AMOUNT = 60000000000;
    
    // TokenDistribution (80:20)
    /// @notice Total amount of the quote token in pool
    uint256 public constant QUOTE_TOKEN_TOTAL_AMOUNT_IN_POOL = 70 * 10**16;
    
    /// @notice Total amount of the quote token in dex
    uint256 public constant QUOTE_TOKEN_TOTAL_AMOUNT_IN_DEX = 30 * 10**16;

    /// @notice Target receive amount for the base token
    uint256 public constant BASE_TOKEN_TARGET_RECEIVE_AMOUNT = 42 * 10**17;

    /// @notice The Address of pool factory on uniswap
    address public constant UNISWAP_POOL_FACTORY_ = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    /// @notice The Address of router on uniswap
    address public constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

}
