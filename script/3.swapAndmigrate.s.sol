
import 'forge-std/Script.sol';
import "forge-std/Vm.sol";
import {LaunchPoolV1} from "../src/modules/launchPadV1/LaunchPoolV1.sol";
import {Router} from "../src/Router.sol";
import {PoolRegistery} from "../src/PoolRegistery.sol";
import {PoolFactoryV1} from "../src/modules/launchPadV1/PoolFactoryV1.sol";
import {MockToken} from "../src/tokens/MockToken.sol";
import {Vault} from "../src/Vault.sol";

contract SwapAndMigrate is Script {

    address mockWETH =  0xa62f4CB785B4cD32C684C3f834028899c94Fa392 ;
    address poolRegistery =  0xE05c0cBC6db21411F9f2b93eAafB64dA01b8D5b6 ;
    address payable router =  payable(0xbce53db8C310Ce2b8aE67C04c1B7A0B9568c9221) ;
    address payable vault =  payable(0xA380598982C40eE2C6f7d6e2471ef8c8271e98D5) ;
    address poolFees =  0x159159d09C046A363b37BBe9A23B0451534efd40 ;
    address dexFees =  0xB608a7E7e95E61ec343AF87a10E257A99848FB05 ;
    address factory =  0xbD8A0F3A4B5C61c3392aDa7d62087d4FD804813a ;

//   FMeme:  0xED6aB523Db5368Bd155AfB0D7969Bd0A8CDE59a1
//   Pool:  0x4A2e4fC7321874D69aEBdbeD24cBB149e843A972

    address FMeme =  0xED6aB523Db5368Bd155AfB0D7969Bd0A8CDE59a1;
    address FmemePool =  0x4A2e4fC7321874D69aEBdbeD24cBB149e843A972;

    // testnet
    // forge script script/swapAndmigrate.s.sol:SwapAndMigrate --rpc-url https://sepolia.base.org  --verify --broadcast -vvvv

    // mainnet
    // forge script script/3.swapAndmigrate.s.sol:SwapAndMigrate --rpc-url https://base-rpc.publicnode.com  --verify --broadcast -vvvv

    function run() public virtual {
        uint256 deployerPrivateKey = vm.envUint("ADMIN_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Buy Meme Token
        uint256 amountIn = 3.6 ether;
        MockToken(mockWETH).approve(router, amountIn);
        uint256 amountYOut = Router(router).buyQuote(FmemePool, amountIn, 0);

        // 0x57C223f896e045E6671d40640ea1e8d6632FFC66
        
        // Vault
        Vault(vault).migrate(FmemePool);

        vm.stopBroadcast();
    }
}