
import 'forge-std/Script.sol';
import "forge-std/Vm.sol";
import {LaunchPoolV1} from "../src/modules/launchPadV1/LaunchPoolV1.sol";
import {Router} from "../src/Router.sol";
import {PoolRegistery} from "../src/PoolRegistery.sol";
import {PoolFactoryV1} from "../src/modules/launchPadV1/PoolFactoryV1.sol";
import {MockToken} from "../src/tokens/MockToken.sol";
import {LamboToken} from "../src/tokens/LamboToken.sol";


contract CreatePoolandSwap is Script {

    // address mockWETH =  0xa62f4CB785B4cD32C684C3f834028899c94Fa392 ;
    // address poolRegistery =  0xE05c0cBC6db21411F9f2b93eAafB64dA01b8D5b6 ;
    // address router =  0xbce53db8C310Ce2b8aE67C04c1B7A0B9568c9221 ;
    // address vault =  0xA380598982C40eE2C6f7d6e2471ef8c8271e98D5 ;
    // address poolFees =  0x159159d09C046A363b37BBe9A23B0451534efd40 ;
    // address dexFees =  0xB608a7E7e95E61ec343AF87a10E257A99848FB05 ;
    // address factory =  0xbc135948462a0C3c7577C51CF31cdF93f8903827 ;


    address WETHAddress = 0xa62f4CB785B4cD32C684C3f834028899c94Fa392;
    address PoolRegisteryAddress = 0xE05c0cBC6db21411F9f2b93eAafB64dA01b8D5b6;
    address payable RouterAddress = payable(0xbce53db8C310Ce2b8aE67C04c1B7A0B9568c9221);
    address FactoryAddress = 0xbc135948462a0C3c7577C51CF31cdF93f8903827;
    
    // testnet
    // forge script script/createPoolandSwap.s.sol:CreatePoolandSwap --rpc-url https://sepolia.base.org  --verify --broadcast -vvvv
    
    // mainnet
    // forge script script/2.createPoolandSwap.s.sol:CreatePoolandSwap --rpc-url https://base-rpc.publicnode.com  --broadcast -vvvv

    function run() public virtual {
        uint256 deployerPrivateKey = vm.envUint("ADMIN_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);


        (address quoteToken, address pool) = PoolFactoryV1(FactoryAddress).createLaunchPad(WETHAddress, "FUCK Meme ", "FMeme");

        console.log("FMeme: ", quoteToken);
        console.log("Pool: ", pool);

        vm.stopBroadcast();

        vm.startBroadcast(deployerPrivateKey);
        // Buy Meme Token
        uint256 amountIn = 1 ether;
        MockToken(WETHAddress).approve(RouterAddress, amountIn);
        uint256 amountYOut = Router(RouterAddress).buyQuote(pool, amountIn, 0);
        vm.stopBroadcast();
        
        // See Meme Token
        vm.startBroadcast(deployerPrivateKey);
        MockToken(quoteToken).approve(RouterAddress, amountYOut);
        Router(RouterAddress).sellQuote(pool, amountYOut, 0);
        vm.stopBroadcast();
    }
}