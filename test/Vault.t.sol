
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;
import {stdStorage, StdStorage, Test, console2} from "forge-std/Test.sol";
import {BaseTest} from "./BaseTest.t.sol";
import {IERC20}  from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {LaunchPadUtils} from "../src/modules/launchPadV1/LaunchPadUtils.sol";
import {Vault} from "../src/Vault.sol";
import {ILaunchpad} from "../src/interfaces/ILaunchpad.sol";
import {IPool} from "../src/interfaces/Uniswap/IPool.sol";
import {IUniswapV2Router01} from "../src/interfaces/Uniswap/IRouter.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// forge test --match-contract VaultTesting -vvvv
// forge test --mt test_migrateFor -vvvv
contract VaultTesting is BaseTest, LaunchPadUtils {
    address pool;
    address quoteToken;
    uint256 deployerPrivateKey;

    function setUp() public override {
        super.setUp();

        deployerPrivateKey = vm.envUint("ADMIN_PRIVATE_KEY");

        factory.setBaseTokenWhiteStatus(address(usdi), true);
        (quoteToken,  pool) = factory.createLaunchPad(address(usdi), "pepe", "pepe");
    }

    function _packRsv(bytes32 r, bytes32 s, uint8 v) internal pure returns (bytes memory) {
        bytes memory sig = new bytes(65);
        assembly {
            mstore(add(sig, 32), r)
            mstore(add(sig, 64), s)
            mstore8(add(sig, 96), v)
        }
        return sig;
    }

    function signOrder(uint256 key, bytes32 digest)
        public
        pure
        returns (bytes memory)
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, digest);
        bytes memory sigBytes = _packRsv(r, s, v);

        return sigBytes;
    }

    function test_abiencode() public {
        string memory _name = "FUCK Meme";
        string memory _symbol = "FMeme";
        bytes memory res = abi.encode(string(abi.encodePacked(_name, " Lambo Token")), _symbol);
        console2.logBytes(res);
    }

    function test_fillUpLauchPad() public {
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
        router.sellQuote(pool, amountYIn, 0);

        vm.stopPrank();
    }

    function test_migrateFor() public {
        vm.startPrank(Bob, Bob);

        // buy Quote
        uint256 amountXIn = 4.3 ether;
        usdi.approve(address(router), amountXIn);
        router.buyQuote(pool, amountXIn, 0);
  
        vm.assertEq(ILaunchpad(pool).IsPoolEnd(), true);
        vm.assertEq(IERC20(quoteToken).balanceOf(address(vault)), QUOTE_TOKEN_TOTAL_AMOUNT_IN_DEX);
        address uniswapPool = vault.migrate(pool);
        
        vm.stopPrank();
    }

    function test_migrateForAndSwap() public {
        vm.startPrank(Bob, Bob);

        // buy Quote
        uint256 amountXIn = 4.3 ether;
        usdi.approve(address(router), amountXIn);
        router.buyQuote(pool, amountXIn, 0);
  
        vm.assertEq(ILaunchpad(pool).IsPoolEnd(), true);
        vm.assertEq(IERC20(quoteToken).balanceOf(address(vault)), QUOTE_TOKEN_TOTAL_AMOUNT_IN_DEX);
        address uniswapPool = vault.migrate(pool);
        console2.log(uniswapPool);

        // uint256 reserveA = usdi.balanceOf(uniswapPool);
        // uint256 reserveB = IERC20(quoteToken).balanceOf(uniswapPool);
        // uint256 amountOut = IUniswapV2Router01(UNISWAP_ROUTER_ADDRESS).getAmountOut(1 ether, reserveA, reserveB);

        // uint256 beforeAmount = IERC20(quoteToken).balanceOf(Bob);
        // IERC20(address(usdi)).transfer(uniswapPool, 1 ether);
        // if (IPool(uniswapPool).token0() == address(usdi)) {
        //     IPool(uniswapPool).swap(0, amountOut, Bob, "");
        // } else {
        //     IPool(uniswapPool).swap(amountOut, 0, Bob, "");
        // }
        // uint256 afterAmount = IERC20(quoteToken).balanceOf(Bob);

        // // 0.003 fee
        // vm.assertEq(afterAmount - beforeAmount, 55425839448521236);

        vm.stopPrank();
    }
          
}