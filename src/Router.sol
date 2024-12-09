// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {IWETH} from "./interfaces/IWETH.sol";
import {IERC20}  from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IRouter} from "./interfaces/IRouter.sol";
import {ILaunchpad} from "./interfaces/ILaunchpad.sol";
import {IPoolFactory} from "./interfaces/IPoolFactory.sol";
import {IApproveProxy} from "./interfaces/IApproveProxy.sol";
import {IPoolRegistery} from "./interfaces/IPoolRegistery.sol";
import {stdStorage, StdStorage, Test, console2} from "forge-std/Test.sol";

import {Utils} from "./Utils.sol";

/// @title Router Contract
/// @notice This contract is responsible for routing buy and sell quotes to the respective pools.
contract Router is IRouter, Utils {
    // Address of the pool registry
    address public immutable poolRegistery;

    /// @notice Constructor to initialize the pool registry and WETH addresses
    /// @param _poolRegistery Address of the pool registry
    constructor(address _poolRegistery)  {
        poolRegistery = _poolRegistery;
    }

    /// @notice Gets the buy quote for a specified pool and input amount
    /// @param pool Address of the target pool
    /// @param amountXIn Amount of token X to be input
    /// @return amountYOutWithoutFee The amount of token Y with fee 
    /// @return fee The fee from baseToken
    function getBuyQuote(
        address pool,
        uint256 amountXIn
    ) public view returns (uint256 amountYOutWithoutFee, uint256 fee, uint256 amountXInDuringSwap) {
        uint256 poolFeeRate = ILaunchpad(pool).getPoolFeeRate();
        uint256 BASE_TOKEN_TARGET_RECEIVE_AMOUNT = ILaunchpad(pool).getTargetReceiveAmount();

        (,,uint256 reserveX, ) = ILaunchpad(pool).getPoolState();

        fee = (amountXIn * poolFeeRate) / 10000;
        amountXIn = amountXIn - fee;
        
        if (amountXIn + reserveX > BASE_TOKEN_TARGET_RECEIVE_AMOUNT) {
            amountXIn = BASE_TOKEN_TARGET_RECEIVE_AMOUNT - reserveX ;
        }

        amountXInDuringSwap = amountXIn;
        amountYOutWithoutFee = ILaunchpad(pool).getBuyPrice(amountXIn);

    }

    /// @notice Gets the sell quote for a specified pool and input amount
    /// @param pool Address of the target pool
    /// @param amountYIn Amount of token Y to be input
    /// @return amountXOutWithoutFee The amount of token X with fee 
    /// @return fee The fee from baseToken
    function getSellQuote(
        address pool,
        uint256 amountYIn
    ) public view returns (uint256 amountXOutWithoutFee, uint256 fee) {
        uint256 amountXOut = ILaunchpad(pool).getSellPrice(amountYIn);
        uint256 poolFeeRate = ILaunchpad(pool).getPoolFeeRate();
        fee = (amountXOut * poolFeeRate) / 10000;
        amountXOutWithoutFee = amountXOut - fee;
    }

    /// @notice Creates a new launch pad and do initial swap
    /// @param baseToken The address of the base token
    /// @param amountXIn The amount of initial buy 
    /// @param name The name of the quote token
    /// @param tickname The ticker name of the quote token
    function createLaunchPadAndInitialBuy(
        address poolFactory,
        address baseToken, 
        uint256 amountXIn,
        string calldata name, 
        string calldata tickname
    ) external payable returns (address quoteToken, address pool, uint256 amountYOut) {
        if (!IPoolRegistery(poolRegistery).isPoolFactoryValid(poolFactory)) revert InvalidPoolFactory();
        if (amountXIn > INITIAL_BUY_LIMIT) revert InitialBuyLimit();

        (quoteToken,  pool) = IPoolFactory(poolFactory).createLaunchPad(baseToken, name, tickname);

        amountYOut = buyQuote(pool, amountXIn, 0);

        emit CreateLaunchPadAndInitialBuy(baseToken, quoteToken, pool, amountXIn, amountYOut);
    }

    /// @notice Executes a buy quote by swapping token X for token Y in the specified pool
    /// @param pool Address of the target pool
    /// @param amountXIn Amount of token X to be input
    /// @param minReturn Minimum amount of token Y expected to be received
    /// @return amountYOut The amount of token Y received
    function buyQuote(
        address pool,
        uint256 amountXIn,
        uint256 minReturn
    ) public payable returns(uint256 amountYOut) {
        // Check if the pool is valid
        if (!IPoolRegistery(poolRegistery).isPoolValid(pool)) revert InvalidPool();
        (address baseToken, address quoteToken, uint256 reserveX, ) = ILaunchpad(pool).getPoolState();
        
        uint256 fee;
        address poolFee = ILaunchpad(pool).getPoolFee();

        // udpate amountXIn to amountXInDuringSwap
        (amountYOut, fee, amountXIn) = getBuyQuote(pool, amountXIn);
        if (amountYOut < minReturn) revert MinReturnNotReach(); //@note 提前判断

        // Handle native token and WETH
        if (msg.value > 0 && baseToken == WETH) {
            // transfer fee:
            payable(poolFee).call{value: fee}("");

            // transfer pool
            IWETH(WETH).deposit{value: amountXIn}();
            IWETH(WETH).transfer(pool, amountXIn);
            ILaunchpad(pool).swap(amountXIn, 0, 0, amountYOut, msg.sender);

            // if eth left, send back to msg.sender
            // TIPS: prevent the Re-Entrance Attack
            if (address(this).balance > 0) {
                (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
                require(success);
            }

        } else {
            if (IERC20(baseToken).balanceOf(msg.sender) < amountXIn) revert NotEnoughBaseToken();

            // transfer fee
            IERC20(baseToken).transferFrom(msg.sender, poolFee, fee);

            // transfer to pool
            IERC20(baseToken).transferFrom(msg.sender, pool, amountXIn);
            ILaunchpad(pool).swap(amountXIn, 0, 0, amountYOut, msg.sender);
        }
        

        bool isPoolEnd = ILaunchpad(pool).IsPoolEnd();
        uint256 encodePool = isPoolEnd? 
            uint256(uint160(pool)) | (uint256(POOL_END_TYPE) << 255) | (BUY_QUOTE_TYPE << 254):
            uint256(uint160(pool)) | (uint256(POOL_NOT_END_TYPE) << 255) | (BUY_QUOTE_TYPE << 254);
        
        emit Trade(encodePool, baseToken, quoteToken, amountXIn, amountYOut, minReturn);
    }

    /// @notice Executes a sell quote by swapping token Y for token X in the specified pool
    /// @param pool Address of the target pool
    /// @param amountYIn Amount of token Y to be input
    /// @param minReturn Minimum amount of token X expected to be received
    /// @return amountXOut The amount of token X received
    function sellQuote(
        address pool,
        uint256 amountYIn,
        uint256 minReturn
    ) public returns(uint256 amountXOut){
        // Check if the pool is valid
        if (!IPoolRegistery(poolRegistery).isPoolValid(pool)) revert InvalidPool();

        // Get baseToken and QuoteToken
        (address baseToken, address quoteToken, ,)  = ILaunchpad(pool).getPoolState();

        // amountXOut = amountXOutWithoutFee - fee,
        // But when swap occurs, Pool need amountXOutWithoutFee amount,
        // Otherwise, The pool will raise K() error.
        uint256 fee;
        (amountXOut,  fee) = getSellQuote(pool, amountYIn);        
        uint256 amountXOutWithoutFee = amountXOut + fee;

        // Ensure the return amount meets the minimum requirement
        if (amountXOut < minReturn) revert MinReturnNotReach(); 

        // Transfer Token and swap
        IERC20(quoteToken).transferFrom(msg.sender, pool, amountYIn);
        ILaunchpad(pool).swap(0, amountYIn, amountXOutWithoutFee, 0, address(this));

        address poolFee = ILaunchpad(pool).getPoolFee();

        // Handle baseToken is WETH
        if (baseToken == WETH) {
            IWETH(WETH).withdraw(amountXOut + fee);

            // transfer fee to poolFee
            address(poolFee).call{value: fee}("");
            
            // transfer amountOut to user            
            (bool success, ) = address(msg.sender).call{value: amountXOut}("");
            require(success);
        } else {
            // transfer fee to poolFees
            IERC20(baseToken).transfer(poolFee, fee);

            // transfer amountOut to user
            IERC20(baseToken).transfer(msg.sender, amountXOut);
        }

        bool isPoolEnd = ILaunchpad(pool).IsPoolEnd();
      
        uint256 encodePool = isPoolEnd? 
            uint256(uint160(pool)) | (uint256(POOL_END_TYPE) << 255) | (SELL_QUOTE_TYPE << 254):
            uint256(uint160(pool)) | (uint256(POOL_NOT_END_TYPE) << 255) | (SELL_QUOTE_TYPE << 254);

        emit Trade(encodePool, quoteToken, baseToken,  amountYIn, amountXOut, minReturn);
    }

    receive() payable external {}
}
