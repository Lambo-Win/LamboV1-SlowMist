// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPoolFactory {
    event setTargetAmount(uint256 targetReceiveAmount);
    event SetQuoteTokenTotolAmount(uint256 totalAmount);
    event SetFeeManager(address feeManager);
    event SetPauser(address pauser);
    event SetPauseState(bool state);
    event SetVoter(address voter);
    event SetBaseTokenWhiteStatus(address baseToken, bool status);
    event PoolCreated(address indexed token0, address indexed token1, address pool, uint256);
    event SetCustomFee(address indexed pool, uint256 fee);
    event TokenDeployed(address tokenAddress);
    event SetRouter(address router);
    event PoolCreated(address baseToken, address quoteToken, address pool);
    event SetPoolFeeRate(uint256 poolFeeRate);

    error InvalidBaseToken();
    error FeeInvalid();
    error FeeTooHigh();
    error InvalidPool();
    error NotLaunchPadManager();
    error InvalidFeeRate();
    error NotFeeManager();
    error NotPauser();
    error NotVoter();
    error PoolAlreadyExists();
    error SameAddress();
    error ZeroFee();
    error ZeroAddress();
    
    function getPoolFeeRate() external view returns (uint256);

    function getPoolFee() external view returns (address);

    function isPool(address pool) external view returns (bool);

    function setPauser(address _pauser) external;

    function setPauseState(bool _state) external;

    function createLaunchPad(address baseToken, string calldata name, string calldata symbol) external returns (address, address);

    function isPaused() external view returns (bool);
}
