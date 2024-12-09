// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {IERC20}  from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {BaseTest} from "./BaseTest.t.sol";
import "forge-std/Test.sol";

contract InitialBuyTesting is BaseTest {
    address pool;
    address quoteToken;

    function test0_initial_buy() public {
        super.setUp();
        
        factory.setBaseTokenWhiteStatus(address(usdi), true);

        vm.startPrank(Bob, Bob);
        
        uint256 amountXIn = 0.1 ether;

        usdi.approve(address(router), amountXIn);
         (address quoteToken, address pool, uint256 amountYOut) = router.createLaunchPadAndInitialBuy(address(factory), address(usdi), amountXIn, "pepe0", "pepe0");
        vm.assertEq(IERC20(quoteToken).balanceOf(Bob), 37326869806094182);
        vm.stopPrank();
    }

    function test0_initial_buy_onNative() public {
        super.setUp();
        
        factory.setBaseTokenWhiteStatus(address(usdi), true);

        vm.startPrank(Bob, Bob);
        
        uint256 amountXIn = 0.1 ether;

        usdi.approve(address(router), amountXIn);
         (address quoteToken, address pool, uint256 amountYOut) = router.createLaunchPadAndInitialBuy{value: amountXIn}(address(factory), address(WETH), amountXIn, "pepe0", "pepe0");
        vm.assertEq(IERC20(quoteToken).balanceOf(Bob), 37326869806094182);
        vm.stopPrank();
    }
}