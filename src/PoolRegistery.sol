// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {IPoolRegistery} from "./interfaces/IPoolRegistery.sol";

/// @title Pool Registery Contract
/// @notice This contract manages the registration and validation of factories and pools.
contract PoolRegistery is IPoolRegistery {
    // Address of the admin
    address public admin;

    // Mapping to keep track of valid factories
    mapping(address => bool) private _isFactoryValid; 

    // Mapping to keep track of valid pools
    mapping(address => bool) private _isPoolValid; 

    // Array to store all registered pools
    address[] public allPools;

    /// @notice Constructor to set the deployer as the initial admin
    constructor() {
        admin = msg.sender;
    }
    
    /// @notice Modifier to restrict access to only the admin
    modifier onlyAdmin() {
        if (msg.sender != admin) revert OnlyAdmin();
        _;
    }

    /// @notice Modifier to restrict access to only valid factories
    modifier onlyValidFactory() {
        if (!_isFactoryValid[msg.sender]) revert OnlyValidFactory();
        _;
    }

    /// @notice Resets the admin to a new address
    /// @param newAdmin The address of the new admin
    function resetAdmin(address newAdmin) external onlyAdmin() {
        require(newAdmin != address(0));
        address oldAdmin = admin;
        admin = newAdmin;
        emit ChangeAdmin(oldAdmin, newAdmin);
    }

    /// @notice Registers a new factory
    /// @param factory The address of the factory to register
    function registerFactory(address factory) external onlyAdmin {
        _isFactoryValid[factory] = true;
        emit RegisterFactory(factory);
    }

    /// @notice Registers a new pool
    /// @param baseToken The address of the base token of the pool
    /// @param quoteToken The address of the quote token of the pool
    /// @param pool The address of the pool
    function registerPool(
        address baseToken,
        address quoteToken,
        address pool
    ) external onlyValidFactory {
        _isPoolValid[pool] = true;
        allPools.push(pool);
        emit PoolCreated(baseToken, quoteToken, pool);
    }

    /// @notice Checks if a pool is valid
    /// @param pool The address of the pool to check
    /// @return bool indicating whether the pool is valid
    function isPoolValid(address pool) external view returns (bool) {
        return _isPoolValid[pool];
    }

    /// @notice Checks if a poolFactory is valid
    /// @param poolFactory The address of the pool to check
    /// @return bool indicating whether the pool is valid
    function isPoolFactoryValid(address poolFactory) external view returns (bool) {
        return _isFactoryValid[poolFactory];
    }

    /// @notice Gets the total number of registered pools
    /// @return uint256 The number of registered pools
    function allPoolsLength() external view returns (uint256) {
        return allPools.length;
    }

    /// @notice Gets the address of a pool by its index
    /// @param index The index of the pool
    /// @return address The address of the pool at the specified index
    function getPool(uint256 index) external view returns (address) {
        return allPools[index];
    }
}
