// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;
import {stdStorage, StdStorage, Test, console2} from "forge-std/Test.sol";
import {BaseTest} from "./BaseTest.t.sol";
import {LaunchPoolV1} from "../src/modules/launchPadV1/LaunchPoolV1.sol";
import {Router} from "../src/Router.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {IERC20}  from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ILaunchpad} from "../src/interfaces/ILaunchpad.sol";

// forge test --match-contract PoolV1Testing -vvvv
// forge test --mt test_doBuyQuoteAndSellQuote_WithUsdi1 -vvvv
contract PoolV1Testing is BaseTest {
    address pool;
    address quoteToken;

    function setUp() public override {
        super.setUp();
        
        factory.setBaseTokenWhiteStatus(address(usdi), true);
        (quoteToken,  pool) = factory.createLaunchPad(address(usdi), "pepe", "pepe");
        (address quoteToken2,  address pool2) = factory.createLaunchPad(address(usdi), "pepe", "pepe");

    }

    function test_doBuyQuoteAndSellQuote_WithUsdi1() public {
        vm.startPrank(Bob, Bob);

        uint256 amountXIn = 3.5 ether;
        usdi.approve(address(router), amountXIn);
        uint256 amountYOut = router.buyQuote(pool, amountXIn, 0);
        console2.log(amountYOut);
        console2.log(IERC20(quoteToken).balanceOf(Bob));

        uint256 amountYIn = amountYOut;
        IERC20(quoteToken).approve(address(router), amountYIn);

        // Check Fee
        vm.assertEq(amountXIn - amountXIn *  100 / 10000, IERC20(address(usdi)).balanceOf(pool));
        vm.assertEq(amountXIn *  100 / 10000, IERC20(address(usdi)).balanceOf(address(poolFees)));

        // Pool will be not Ended, becuase of the fee
        uint256 beforeSellQuoteTokenBalance = usdi.balanceOf(Bob);
        uint256 amountXOutWithoutFee = ILaunchpad(pool).getSellPrice(amountYIn);

        uint256 amountXOut = router.sellQuote(pool, amountYIn, amountXOutWithoutFee * (10000 - 100) / 10000);
        uint256 afterSellQuoteTokenBalance = usdi.balanceOf(Bob);

        // Check Fee
        vm.assertEq(amountXOutWithoutFee * (10000 - 100) / 10000 + 1, amountXOut);
        vm.assertEq(afterSellQuoteTokenBalance - beforeSellQuoteTokenBalance, amountXOut);

        vm.stopPrank();
    }

    function test_doBuyQuoteAndSellQuote_WithUsdi2() public {
        vm.startPrank(Bob, Bob);

        uint256 amountXIn = 3.6 ether;
        usdi.approve(address(router), amountXIn);
        uint256 amountYOut = router.buyQuote(pool, amountXIn, 0);
        console2.log(amountYOut);
        console2.log(IERC20(quoteToken).balanceOf(Bob));

        uint256 amountYIn = amountYOut;
        IERC20(quoteToken).approve(address(router), amountYIn);

        // Check Fee
        vm.assertEq(amountXIn - amountXIn *  100 / 10000, IERC20(address(usdi)).balanceOf(pool));
        vm.assertEq(amountXIn *  100 / 10000, IERC20(address(usdi)).balanceOf(address(poolFees)));

        router.sellQuote(pool, amountYIn, 0);

        vm.stopPrank();
    }

    function test_doBuyQuoteAndSellQuote_WithUsdi3() public {
        vm.startPrank(Bob, Bob);

        uint256 beforeBalance = usdi.balanceOf(Bob);
        uint256 amountXIn = 5.0 ether;
        usdi.approve(address(router), amountXIn);
        uint256 amountYOut = router.buyQuote(pool, amountXIn, 0);
        uint256 afterBalance = usdi.balanceOf(Bob);

        // Get ALl Token, and Pay WETH back to Bob 
        vm.assertEq(amountYOut, 700000000000000000);
        vm.assertEq(beforeBalance - afterBalance, 4.2 ether + (amountXIn / 100));

        vm.stopPrank();
    }

    function test_doBuyQuoteAndSellQuote_WithUsdi4() public {
        vm.startPrank(Bob, Bob);

        uint256 amountXIn = 4.5 ether;
        usdi.approve(address(router), amountXIn);
        uint256 amountYOut = router.buyQuote(pool, amountXIn, 0);
        uint256 amountYIn = amountYOut;
        IERC20(quoteToken).approve(address(router), amountYIn);
        console2.log(amountYOut);

        // Pool is Ended, So can't SellQuote
        vm.expectRevert(0xedfc006c);
        router.sellQuote(pool, amountYIn, 0);

        vm.stopPrank();
    }

    function test_doBuyQuoteAndSellQuote_WithUsdi5() public {
        vm.startPrank(Bob, Bob);

        uint256 beforeBalance = usdi.balanceOf(Bob);
        uint256 amountXIn = 1.0 ether;
        usdi.approve(address(router), amountXIn);
        uint256 amountYOut = router.buyQuote(pool, amountXIn, 0);
        uint256 amountYIn = amountYOut;
        IERC20(quoteToken).approve(address(router), amountYIn);
        
        // 408333333333333333, 
        vm.assertEq(amountYIn, IERC20(address(quoteToken)).balanceOf(Bob));
        
        router.sellQuote(pool, amountYIn, 0);
        uint256 afterBalance = usdi.balanceOf(Bob);

        // some gas wei will be left in the contarct, ignore.
        vm.assertEq(beforeBalance - afterBalance, usdi.balanceOf(address(poolFees)) + 1 );

        vm.stopPrank();
    }

}











