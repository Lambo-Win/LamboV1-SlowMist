pragma solidity ^0.8.20;
import "forge-std/Test.sol";

// Firstly, we implement a mock emulating the actual precompile behavior
contract YieldMock {
    address private constant baseWETH9 = 0x4300000000000000000000000000000000000002;

    mapping(address => uint8) public getConfiguration;

    function configure(address contractAddress, uint8 flags) external returns (uint256) {
        require(msg.sender == baseWETH9);

        getConfiguration[contractAddress] = flags;
        return 0;
    }

    function claim(address, address, uint256) external pure returns (uint256) {
        return 0;
    }

    function getClaimableAmount(address) external pure returns (uint256) {
        return 0;
    }
}