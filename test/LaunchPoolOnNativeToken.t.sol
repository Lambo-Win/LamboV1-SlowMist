// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;
import {stdStorage, StdStorage, Test, console2} from "forge-std/Test.sol";
import {BaseTest} from "./BaseTest.t.sol";
import {LaunchPoolV1} from "../src/modules/launchPadV1/LaunchPoolV1.sol";
import {Router} from "../src/Router.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {IERC20}  from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ILaunchpad} from "../src/interfaces/ILaunchpad.sol";
import {IWETH} from "../src/interfaces/IWETH.sol";

contract PoolV1TestingOnNative is BaseTest {
    address pool;
    address quoteToken;

    function setUp() public override {
        super.setUp();

        
        factory.setBaseTokenWhiteStatus(WETH, true);
        (quoteToken,  pool) = factory.createLaunchPad(WETH, "Trump", "Trump");
    }

    function test_doBuyQuoteAndSellQuote_WithUsdi10() public {
        vm.startPrank(Bob, Bob);

        uint256 amountXIn = 3.1 ether;

        uint256 amountYOut = router.buyQuote{value: amountXIn}(pool, amountXIn, 0);

        console2.log(amountYOut);
        console2.log(IERC20(quoteToken).balanceOf(Bob));

        uint256 amountYIn = amountYOut;
        IERC20(quoteToken).approve(address(router), amountYIn);

        // Check Fee
        vm.assertEq(amountXIn - amountXIn *  100 / 10000, IERC20(WETH).balanceOf(pool));
        vm.assertEq(amountXIn *  100 / 10000, address(poolFees).balance);

        // Pool will be not Ended, becuase of the fee
        uint256 beforeSellQuoteTokenBalance = Bob.balance;
        uint256 amountXOutWithoutFee = ILaunchpad(pool).getSellPrice(amountYIn);

        uint256 amountXOut = router.sellQuote(pool, amountYIn, amountXOutWithoutFee * (10000 - 100) / 10000);
        uint256 afterSellQuoteTokenBalance = Bob.balance;

        // Check Fee
        vm.assertEq(amountXOutWithoutFee * (10000 - 100) / 10000 + 1, amountXOut);
        vm.assertEq(afterSellQuoteTokenBalance - beforeSellQuoteTokenBalance, amountXOut);

        vm.stopPrank();
    }

    function test_doBuyQuoteAndSellQuote_WithUsdi20() public {
        vm.startPrank(Bob, Bob);

        uint256 amountXIn = 3.6 ether;

        uint256 amountYOut = router.buyQuote{value: amountXIn}(pool, amountXIn, 0);
        console2.log(amountYOut);
        console2.log(IERC20(quoteToken).balanceOf(Bob));

        uint256 amountYIn = amountYOut;
        IERC20(quoteToken).approve(address(router), amountYIn);

        // Check Fee
        // 3.6 * 0.01
        vm.assertEq(amountXIn - amountXIn *  100 / 10000 , IERC20(address(WETH)).balanceOf(pool));
        vm.assertEq(amountXIn *  100 / 10000, address(poolFees).balance);

        // Pool will be not Ended, becuase of the fee
        router.sellQuote(pool, amountYIn, 0);

        vm.stopPrank();
    }

    function test_doBuyQuoteAndSellQuote_WithUsdi30() public {
        vm.startPrank(Bob, Bob);

        uint256 beforeBalance = Bob.balance;
        uint256 amountXIn = 6.0 ether;

        uint256 amountYOut = router.buyQuote{value: amountXIn}(pool, amountXIn, 0);
        
        uint256 afterBalance = Bob.balance ;
        // Get ALl Token, and Pay WETH back to Bob 
        vm.assertEq(amountYOut, 700000000000000000);
        vm.assertEq(beforeBalance - afterBalance, 4.2 ether + (amountXIn / 100));

        vm.stopPrank();
    }

    function test_doBuyQuoteAndSellQuote_WithUsdi40() public {
        vm.startPrank(Bob, Bob);

        uint256 amountXIn = 4.5 ether;

        uint256 amountYOut = router.buyQuote{value: amountXIn}(pool, amountXIn, 0);
        uint256 amountYIn = amountYOut;

        IERC20(quoteToken).approve(address(router), amountYIn);
        console2.log(amountYOut);

        // Pool is Ended, So can't SellQuote
        vm.expectRevert(0xedfc006c);
        router.sellQuote(pool, amountYIn, 0);

        vm.stopPrank();
    }

    function test_doBuyQuoteAndSellQuote_WithUsdi50() public {
        vm.startPrank(Bob, Bob);

        uint256 beforeBalance = Bob.balance;
        uint256 amountXIn = 1.0 ether;

        uint256 amountYOut = router.buyQuote{value: amountXIn}(pool, amountXIn, 0);
        uint256 amountYIn = amountYOut;
        IERC20(quoteToken).approve(address(router), amountYIn);
        
        vm.assertEq(amountYIn, IERC20(address(quoteToken)).balanceOf(Bob));
        
        router.sellQuote(pool, amountYIn, 0);
        uint256 afterBalance = Bob.balance;

        // some gas wei will be left in the contarct, ignore.
        vm.assertEq(beforeBalance - afterBalance, address(poolFees).balance + 1);

        vm.stopPrank();
    }

}