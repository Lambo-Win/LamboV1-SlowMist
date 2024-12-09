import 'forge-std/Script.sol';
import "forge-std/Vm.sol";
import {LaunchPoolV1} from "../src/modules/launchPadV1/LaunchPoolV1.sol";
import {Router} from "../src/Router.sol";
import {PoolRegistery} from "../src/PoolRegistery.sol";
import {PoolFactoryV1} from "../src/modules/launchPadV1/PoolFactoryV1.sol";
import {MockToken} from "../src/tokens/MockToken.sol";
import {LamboToken} from "../src/tokens/LamboToken.sol";

import {Vault} from "../src/Vault.sol";
import {Utils} from "../src/Utils.sol";

contract DeployBondingCurve is Script, Utils {
    // Base testnet
    // forge script script/1.deployBondingCurve.s.sol:DeployBondingCurve --rpc-url https://sepolia.base.org  --verify --broadcast -vvvv

    // Base mainnet
    // forge script script/1.deployBondingCurve.s.sol:DeployBondingCurve --rpc-url https://base-rpc.publicnode.com  --broadcast -vvvv
    
    address mockWETH =  0xa62f4CB785B4cD32C684C3f834028899c94Fa392 ;
    address poolRegistery =  0xE05c0cBC6db21411F9f2b93eAafB64dA01b8D5b6 ;
    address router =  0xbce53db8C310Ce2b8aE67C04c1B7A0B9568c9221 ;
    address vault =  0xA380598982C40eE2C6f7d6e2471ef8c8271e98D5 ;
    address multisign = 0x9E1823aCf0D1F2706F35Ea9bc1566719B4DE54B8;
    PoolFactoryV1 factory;

    function run() public virtual {
        uint256 deployerPrivateKey = vm.envUint("ADMIN_PRIVATE_KEY");
        address adminAddress = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        _deployFactories();

        PoolRegistery(poolRegistery).registerFactory(address(factory));

        factory.setRouter(address(router));
        factory.setBaseTokenWhiteStatus(address(NATIVE_TOKEN), true);
        factory.setBaseTokenWhiteStatus(address(WETH), true);
        factory.setBaseTokenWhiteStatus(address(mockWETH), true);

        console.log("address factory = ", address(factory), ";");

        vm.stopBroadcast();
    }

    function _deployFactories() public {
        LaunchPoolV1 poolImplementation = new LaunchPoolV1();
        LamboToken tokenImplementation = new LamboToken();

        factory = new PoolFactoryV1(
            address(poolRegistery),
            address(poolImplementation),
            address(tokenImplementation),
            address(multisign),
            address(vault)
        );


    }
}





