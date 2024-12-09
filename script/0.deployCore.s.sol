import 'forge-std/Script.sol';
import "forge-std/Vm.sol";
import {LaunchPoolV1} from "../src/modules/launchPadV1/LaunchPoolV1.sol";
import {Router} from "../src/Router.sol";
import {PoolRegistery} from "../src/PoolRegistery.sol";
import {PoolFactoryV1} from "../src/modules/launchPadV1/PoolFactoryV1.sol";
import {MockToken} from "../src/tokens/MockToken.sol";
import {Vault} from "../src/Vault.sol";
import {Utils} from "../src/Utils.sol";

contract DeployCore is Script, Utils {
    address multisign = 0x9E1823aCf0D1F2706F35Ea9bc1566719B4DE54B8;

    PoolRegistery poolRegistery;
    MockToken mockWETH;
    Router router;
    Vault vault;

    // Base testnet
    // forge script script/0.deployCore.s.sol:DeployCore --rpc-url https://sepolia.base.org  --verify --broadcast -vvvv

    // Base mainnet
    // forge script script/0.deployCore.s.sol:DeployCore --rpc-url https://base-rpc.publicnode.com --broadcast -vvvv
    
    function run() public virtual {
        uint256 deployerPrivateKey = vm.envUint("ADMIN_PRIVATE_KEY");
        address adminAddress = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);
 
        _deployVault(adminAddress);
        _prepareWETH(adminAddress);
        _deployPoolRegistery();
        _deployRotuer();

        console.log("address mockWETH = ", address(mockWETH), ";");
        console.log("address poolRegistery = ", address(poolRegistery), ";");
        console.log("address router = ", address(router), ";");
        console.log("address vault = ", address(vault), ";");

        vm.stopBroadcast();
    }


    function _deployVault(address adminAddress) public {
        vault = new Vault(adminAddress);
    }

    function _prepareWETH(address adminAddress) internal {
        mockWETH = new MockToken("mockWETH", "mockETH", 18, adminAddress, 100000 ether);
    }

    function _deployPoolRegistery() public {
        poolRegistery = new PoolRegistery();
    }

    function _deployRotuer() public {
        router = new Router(address(poolRegistery));
    }
}





