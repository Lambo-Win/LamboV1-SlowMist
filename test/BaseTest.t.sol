// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {LamboToken} from "../../src/tokens/LamboToken.sol";
import {MockToken} from "../../src/tokens/MockToken.sol";
import {PoolFactoryV1} from "../src/modules/launchPadV1/PoolFactoryV1.sol";
import {LaunchPoolV1} from "../src/modules/launchPadV1/LaunchPoolV1.sol";
import {Router} from "../src/Router.sol";
import {PoolRegistery} from "../src/PoolRegistery.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Vault} from "../src/Vault.sol";
 
// Mock Env
import {YieldMock} from "./tools/MockEnv.t.sol";
import {Utils} from "../src/Utils.sol";

abstract contract BaseTest is Test, Utils {
    // Test user
    address Bob;
    address public poolFees = address(0xaaaabbbb);

    PoolRegistery poolRegistery;
    PoolFactoryV1 factory;
    MockToken usdi;
    Router router;
    Vault vault;

    function setUp() public virtual {
        vm.createSelectFork("https://eth.llamarpc.com");
        // vm.createSelectFork("https://base-rpc.publicnode.com");
        // vm.createSelectFork("https://sepolia.base.org");

        // admin address
        Bob = 0x1D1e94634FBcB767ce8650269B2c4d33280f0130;
        vm.deal(Bob, 1000000 ether);

        usdi = new MockToken('usdi', 'usdi', 18, Bob, 100000000 * (10 ** 18));

        // YieldMock yieldMock = new YieldMock();
        // vm.etch(0x0000000000000000000000000000000000000100, address(yieldMock).code);

        _deployVault();
        _deployPoolRegistery();
        _deployFactories();
        _deployRotuer();

        factory.setRouter(address(router));
        factory.setBaseTokenWhiteStatus(address(NATIVE_TOKEN), true);
        factory.setBaseTokenWhiteStatus(address(WETH), true);
        
        poolRegistery.registerFactory(address(factory));
    }


    function _deployVault() public {
        vault = new Vault(Bob);
    }

    function _deployPoolRegistery() public {
        poolRegistery = new PoolRegistery();
    }

    function _deployRotuer() public {
        router = new Router(address(poolRegistery));
    }

    function _deployFactories() public {
        LaunchPoolV1 poolImplementation = new LaunchPoolV1();
        LamboToken tokenImplementation = new LamboToken();

        factory = new PoolFactoryV1(
            address(poolRegistery),
            address(poolImplementation),
            address(tokenImplementation),
            address(poolFees),
            address(vault)
        );


    }
}