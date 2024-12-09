// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {IWETH} from "../../interfaces/IWETH.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ILaunchpad} from "../../interfaces/ILaunchpad.sol";
import {IPoolFactory} from "../../interfaces/IPoolFactory.sol";
import {LaunchPadUtils} from "./LaunchPadUtils.sol";
import {stdStorage, StdStorage, Test, console2} from "forge-std/Test.sol";

/// @title LaunchPoolV1 Contract
/// @notice This contract manages a liquidity pool for token swaps without fees
contract LaunchPoolV1 is ILaunchpad, LaunchPadUtils {
    using SafeERC20 for IERC20;

    bool public isPoolEnded;

    uint256 public reserveX;
    uint256 public reserveY;

    // State variables
    address public vault;
    address public baseToken;
    address public quoteToken;
    address public factory;
    address public router;

    /// @notice Initialize the pool with the given parameters
    /// @param _baseToken The address of the base token
    /// @param _quoteToken The address of the quote token
    /// @param _router The address of the router
    function initialize(
        address _baseToken, 
        address _quoteToken, 
        address _router,
        address _vault
    ) public {
        if(factory != address(0)) revert LaunchPoolhHasBeenInited();
        baseToken = _baseToken;
        quoteToken = _quoteToken;
        router = _router;
        vault = _vault;

        isPoolEnded = false;

        // Factory Create launchPool
        factory = msg.sender;

        // Update the reserve state
        _update(0, QUOTE_TOKEN_TOTAL_AMOUNT_IN_POOL);

        IERC20(baseToken).approve(vault, MAX_AMOUNT);
        IERC20(quoteToken).approve(vault, MAX_AMOUNT);

        // Emit pool initialization event
        emit PoolInit(baseToken, quoteToken, factory, QUOTE_TOKEN_TOTAL_AMOUNT_IN_POOL);
    }

    /// @notice Calculates the product of the reserves with offsets (K value)
    /// @param x The reserve of the base token
    /// @param y The reserve of the quote token
    /// @return The product of the reserves with offsets
    function _k(uint256 x, uint256 y) internal view returns (uint256) {
        return (x + X_OFFSET_AMOUNT) * (y + Y_OFFSET_AMOUNT); 
    }

    /// @notice Updates the reserve values
    /// @param balance0 The new balance of the base token
    /// @param balance1 The new balance of the quote token
    function _update(uint256 balance0, uint256 balance1) internal {
        reserveX = balance0;
        reserveY = balance1;
        emit Sync(balance0, balance1);
    }

    function swap(
        uint256 amountXIn,
        uint256 amountYIn,
        uint256 amountXOut, 
        uint256 amountYOut, 
        address to
    ) external {
        if (msg.sender != router) revert OnlyRouter();
        if (IPoolFactory(factory).isPaused()) revert IsPaused();
        if (amountXOut == 0 && amountYOut == 0) revert InsufficientOutputAmount();
        if (amountXOut > reserveX || amountYOut > reserveY) revert InsufficientLiquidity();
        if (to == baseToken || to == quoteToken) revert InvalidTo();
        if (isPoolEnded) revert PoolIsEnd();

        // Transfer the output tokens
        if (amountXOut > 0) IERC20(baseToken).safeTransfer(to, amountXOut);
        if (amountYOut > 0) IERC20(quoteToken).safeTransfer(to, amountYOut);

        uint256 _balanceX = IERC20(baseToken).balanceOf(address(this));
        uint256 _balanceY = IERC20(quoteToken).balanceOf(address(this));
        uint256 newReserveX = reserveX + amountXIn - amountXOut;
        uint256 newReserveY = reserveY + amountYIn - amountYOut;

        // Ensure the product of the reserves with offsets does not decrease
        if (_k(newReserveX, newReserveY) < _k(reserveX, reserveY)) revert K();
        if (_k(_balanceX, _balanceY) < _k(newReserveX, newReserveY)) revert K2();

        // Update the reserve values
        _update(newReserveX, newReserveY);

        // Check and adjust the terminal balance if the pool has ended
        if (newReserveY <= QUOTE_TERMINAL_LEFT_AMOUNT) {
             isPoolEnded = true;
        }
    }

    /// @notice Calculates the output amount for a given input amount
    /// @param amountIn The input amount
    /// @param tokenIn The address of the input token
    /// @param _reserve0 The reserve of the base token
    /// @param _reserve1 The reserve of the quote token
    /// @return The output amount
    function _getAmountOut(
        uint256 amountIn,
        address tokenIn,
        uint256 _reserve0,
        uint256 _reserve1
    ) internal view returns (uint256) {
        (uint256 reserveA, uint256 reserveB) = tokenIn == baseToken ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
        return (amountIn * reserveB) / (reserveA + amountIn);
    }

    /// @notice Checks if the pool has ended
    /// @return True if the pool has ended, false otherwise
    function IsPoolEnd() public view returns (bool) {
        return isPoolEnded;
    }

    /// @notice Returns the current state of the pool
    /// @return The base token address, quote token address, base token reserve, and quote token reserve
    function getPoolState() external view returns (address, address, uint256, uint256) {
        return (baseToken, quoteToken, reserveX, reserveY);
    }


    function getTargetReceiveAmount() external view returns (uint256) {
        return BASE_TOKEN_TARGET_RECEIVE_AMOUNT;
    }

    /// @notice Calculates the price for buying tokens, router should handle the fee 
    /// @param amount The input amount
    /// @return amountYOut The output amount of quote tokens
    function getBuyPrice(uint256 amount) public view returns (uint256 amountYOut) {
        amountYOut = _getAmountOut(amount, baseToken, reserveX + X_OFFSET_AMOUNT, reserveY + Y_OFFSET_AMOUNT);

        if (amountYOut >= reserveY)  {        
            amountYOut = reserveY;
        }
    }

    /// @notice Calculates the price for selling tokens
    /// @param amount The input amount
    /// @return amountXOut The output amount of base tokens
    function getSellPrice(uint256 amount) public view returns (uint256 amountXOut) {
        uint256 poolFeeRate = IPoolFactory(factory).getPoolFeeRate();
        amountXOut = _getAmountOut(amount, quoteToken, reserveX + X_OFFSET_AMOUNT, reserveY + Y_OFFSET_AMOUNT);

        if (amountXOut >= reserveX)  {
            amountXOut = reserveX;
        }
    }

    function getPoolFeeRate() external view returns (uint256) {
        return IPoolFactory(factory).getPoolFeeRate();
    }

    function getPoolFee() external view returns (address) {
        return IPoolFactory(factory).getPoolFee();
    }

    receive() payable external {}
}
