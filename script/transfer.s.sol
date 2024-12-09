// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import 'forge-std/Script.sol';
import "forge-std/Vm.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TransferTest is Script {

    // testnet
    // forge script script/transfer.s.sol:TransferTest --rpc-url https://sepolia.base.org  --verify --broadcast -vvvv
    
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("ADMIN_PRIVATE_KEY");
        address adminAddress = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);


        address[30] memory userlist = [
            0x0488CaA0847a315e1B76d6F7Af42caae7dd5fDbE,
            0xE570B47230379ed9a83eBc335Aa0928C6f798272,
            0xece84B524e3E70c2d97080e0fEe140e27583b319,
            0x3e6d1AB01613154C190A2E8f9E6132C48b935F3A,
            0x1f6B36cC1d9ADe3713f58543dB3C57da4E841599,
            0x1f065310AED94f8fB9DF2e2Bf1201db936586fC0,
            0xf71D046F4e6f9407f3e913cba7A3D8FC0f652f76,
            0xAE5eD1f565ACb9b4254af0e1792505499acCdd8B,
            0x13088F336c918b1b31Eb7ecE87752EBC86c312Bb,
            0x5AaACB69D94c08E99dfCFF125BBA6b9061A2a94a,
            0xE2986606527910bfDbbc55219565c5B997e56153,
            0x9d12b861e6d78478902d20477a1F422367c647B4,
            0x2b58515C803E960D83F89628176394Fb6C1Ee913,
            0x8cDBE20FfbA52C57Af99C6e30ca6a97065A93B13,
            0x907796932Ba29419F4516AA727D437FaAdf6F87F,
            0xf3BA20897d1300f84915bEc5Ce375F678250557a,
            0x77Fa2529e830a1fB4EbCd83CE0281912c5CC4Ebc,
            0x37450C3bD3FA5F5Afc5A13b80CeA5ccD72746C43,
            0x97F040eE3e16BD3BF0116e9117f869ADD9Cb2692,
            0x795BD85d04405Cad5a9fb16639Bf5568bd5a978b,
            0xabdF5f14f06A1086924318789bC4754c1Cd6c441,
            0x8F2eB44aa42D191D32dd5063Af70E09d27869518,
            0xe4B4ad9864E68E3605625A5ebf52552aB21A53Da,
            0x820b59263f399442ef0c3b86A25D7c515861b464,
            0x2498F0515663aF008227eD0440450EFAEdD374b6,
            0x3660a2B355047DD434BF5B258E9F8D8C4d20F21D,
            0x584deD47c060AE1c3FE0f38549D854607d488b40,
            0x8827DF1a64f3Ba03F6Ffd1b18B9FAdecBb53CA4f,
            0x3f248482Cf38eC62A6035A2962BdA8C530BCCc3a,
            0xbfbA54563EB9fd30d77bC3b2c2C2188F92F508CB
        ];

        for (uint256 i = 0; i < userlist.length; i++) {
            payable(userlist[i]).call{value: 0.0002 ether}("");
            // ERC20(0x9C80F556f34d39286f2cfD145b98e93f66580295).transfer(userlist[i], 100 ether);
        }
        // ERC20(0x9C80F556f34d39286f2cfD145b98e93f66580295).transfer(0x46F564Cf38B5D186e2FE07B3d7Cb3af421290062, 100 ether);
        
        vm.stopBroadcast();

    }
}