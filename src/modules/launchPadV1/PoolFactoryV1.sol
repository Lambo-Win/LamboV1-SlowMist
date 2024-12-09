// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {IPool} from "../../interfaces/IPool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Router} from "../../Router.sol";
import {LamboToken} from "../../tokens/LamboToken.sol";
import {IPoolFactory} from "../../interfaces/IPoolFactory.sol";
import {IPoolRegistery} from "../../interfaces/IPoolRegistery.sol";
import {LaunchPadUtils} from "./LaunchPadUtils.sol";

/// @title PoolFactoryV1 Contract
/// @notice This contract is responsible for creating and managing pools
contract PoolFactoryV1 is IPoolFactory, LaunchPadUtils {
    // State variables
    bool public isPaused;

    // Default fee:0.01. poolFeeRate = 100.
    uint256 public poolFeeRate;

    // nonce for the clone
    uint256 private nonce;

    address public vault;
    address public admin;
    address payable public router;
    address public pauser;
    address public poolFee;

    address public poolRegistery;
    address public immutable poolImplementation;
    address public immutable tokenImplementation;

    // Mappings
    mapping(address => bool) private _isPool; // Check if an address is a pool
    mapping(address => bool) public baseTokenWhiteList; // Whitelist for base tokens

    /// @notice Constructor to initialize the PoolFactoryV1 contract
    /// @param _poolRegistery Address of the pool registry
    /// @param _poolImplementation Address of the pool Implementation contract
    /// @param _tokenImplementation Address of the token Implementation contract
    constructor(
        address _poolRegistery,
        address _poolImplementation,
        address _tokenImplementation,
        address _poolFee,
        address _vault
    ) {
        poolRegistery = _poolRegistery;
        poolImplementation = _poolImplementation;
        tokenImplementation = _tokenImplementation;

        admin = msg.sender;
        pauser = msg.sender;
        isPaused = false;

        vault = _vault;
        poolFee = _poolFee;
        poolFeeRate = 100;
    }

    /// @notice Returns the address where the pool fees are collected
    /// @return The address of the pool fee collector
    function getPoolFee() external view returns (address) {
        return poolFee;
    }

    /// @notice Returns the current fee rate for the pool
    /// @return The fee rate as a percentage (in basis points, e.g., 300 means 3%)
    function getPoolFeeRate() external view returns (uint256) {
        return poolFeeRate;
    }

    /// @notice Checks if an address is a valid pool
    /// @param pool The address to check
    /// @return True if the address is a valid pool, false otherwise
    function isPool(address pool) external view returns (bool) {
        return _isPool[pool];
    }

    /// @notice Checks if an address is a valid pool
    /// @param _poolFeeRate The fee rate of pool  
    function setPoolFeeRate(uint256 _poolFeeRate) external {
        if (msg.sender != admin) revert NotLaunchPadManager();
        if (_poolFeeRate > 10000) revert InvalidFeeRate();

        poolFeeRate = _poolFeeRate;
        emit SetPoolFeeRate(_poolFeeRate);
    }

    /// @notice Sets the router address
    /// @param _router The address of the new router
    function setRouter(address _router) external {
        if (msg.sender != admin) revert NotLaunchPadManager();
        router = payable(_router);
        emit SetRouter(router);
    }

    /// @notice Sets the whitelist status of a base token
    /// @param baseToken The address of the base token
    /// @param status The whitelist status
    function setBaseTokenWhiteStatus(address baseToken, bool status) external {
        if (msg.sender != admin) revert NotLaunchPadManager();
        baseTokenWhiteList[baseToken] = status;
        emit SetBaseTokenWhiteStatus(baseToken, status);
    }

    /// @notice Sets the address of the pauser
    /// @param _pauser The address of the new pauser
    function setPauser(address _pauser) external {
        if (msg.sender != admin) revert NotLaunchPadManager();
        if (_pauser == address(0)) revert ZeroAddress();
        pauser = _pauser;
        emit SetPauser(_pauser);
    }

    /// @notice Sets the pause state of the contract
    /// @param _state The new pause state
    function setPauseState(bool _state) external {
        if (msg.sender != pauser) revert NotPauser();
        isPaused = _state;
        emit SetPauseState(_state);
    }

    /// @notice Internal function to deploy a quote token
    /// @param name The name of the quote token
    /// @param symbol The ticker name of the quote token
    /// @return quoteToken The address of the deployed quote token
    function _deployQuoteToken(string calldata name, string calldata symbol) internal returns (address quoteToken) {
        // quoteToken = address(new LamboToken(name, tickname));
        // emit TokenDeployed(quoteToken);
        bytes32 salt = keccak256(abi.encodePacked(name, symbol, nonce));
        quoteToken = Clones.cloneDeterministic(tokenImplementation, salt);

        return quoteToken;
    }

    function _deployPool(address baseToken, address quoteToken) internal returns (address pool) {
        // Ensure the base token is whitelisted
        if (baseToken == quoteToken) revert SameAddress();

        // Get token0 and token1
        (address token0, address token1) = baseToken < quoteToken ? (baseToken, quoteToken) : (quoteToken, baseToken);
        if (token0 == address(0)) revert ZeroAddress();

        // Create a deterministic clone of the poolImplementation
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        pool = Clones.cloneDeterministic(poolImplementation, salt);

        return pool;
    }

    /// @notice Creates a new launch pad
    /// @param baseToken The address of the base token
    /// @param name The name of the quote token
    /// @param symbol The ticker name of the quote token
    /// @return quoteToken The address of the deployed quote token
    /// @return pool The address of the created pool
    function createLaunchPad(address baseToken, string calldata name, string calldata symbol) public returns (address quoteToken, address pool)  {
        if (baseTokenWhiteList[baseToken] == false) revert InvalidBaseToken(); 

        // deploy
        quoteToken = _deployQuoteToken(name, symbol);
        pool = _deployPool(baseToken, quoteToken);
        
        // initialization
        LamboToken(quoteToken).initialize(pool, vault, name, symbol);
        IPool(pool).initialize(baseToken, quoteToken, router, vault);

        // store the pool address
        _isPool[pool] = true;

        // Register the pool
        IPoolRegistery(poolRegistery).registerPool(baseToken, quoteToken, pool);

        unchecked {
            ++nonce;
        }

        emit PoolCreated(baseToken, quoteToken, pool);
    }
}
