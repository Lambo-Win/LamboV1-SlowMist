// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ILaunchpad} from  "../src/interfaces/ILaunchpad.sol";
import {LaunchPadUtils} from "../src/modules/launchPadV1/LaunchPadUtils.sol";

// DEX
import {IPoolFactory} from "../src/interfaces/Uniswap/IPoolFactory.sol";
import {IPool} from "../src/interfaces/Uniswap/IPool.sol";

contract Vault is LaunchPadUtils {    
    using SafeERC20 for IERC20;

    /// @notice the address of admin
    address private admin;

    error PoolIsNotEnd();
    error OnlyAdmin();

    event CreatePoolAndMigration(address uniswapPool, uint256 baseAmount, uint256 quoteAmount);

    constructor(address _admin)  {
        admin = _admin;
    }

    function migrate(address pool) external returns (address uniswapPool) {
        if (!ILaunchpad(pool).IsPoolEnd()) revert PoolIsNotEnd();
        if (msg.sender != admin) revert OnlyAdmin();

        // GetPoolState
        (address baseToken, address quoteToken, , ) = ILaunchpad(pool).getPoolState();

        // Create Pool
        uniswapPool = IPoolFactory(UNISWAP_POOL_FACTORY_).createPair(baseToken, quoteToken);

        // Add Liquidity
        uint256 baseTokenBalance = IERC20(baseToken).balanceOf(pool);
        IERC20(baseToken).transferFrom(pool, uniswapPool, baseTokenBalance);
        IERC20(quoteToken).safeTransfer(uniswapPool, QUOTE_TOKEN_TOTAL_AMOUNT_IN_DEX);

        // Mint and burn LP tokens
        IPool(uniswapPool).mint(address(this));
        IERC20(uniswapPool).safeTransfer(address(0), IERC20(uniswapPool).balanceOf(address(this)));

        emit CreatePoolAndMigration(uniswapPool, baseTokenBalance, QUOTE_TOKEN_TOTAL_AMOUNT_IN_DEX);
    }
}