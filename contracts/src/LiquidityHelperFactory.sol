//SPDX-Licenses-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import './LiquidityDeployer.sol';
import './interfaces/ILiquidityFactory.sol';
import './LiquidityHelper.sol';

contract LiquidityFactory is ILiquidityHelperFactory, LiquidityHelperDeployer {
    address public owner;
    uint24 fee;
    mapping(address => address) public getLiquidityHelper;

    constructor() {
        owner = msg.sender;
    }

    function createLiquidityHelper(
        address nonfungiblePositionManager
    ) external override returns (address liquidityHelper) {
        require(msg.sender == owner, 'LiquidityFactory: FORBIDDEN');
        if(getLiquidityHelper[nonfungiblePositionManager] != address(0)) {
            return getLiquidityHelper[nonfungiblePositionManager];
        }
        liquidityHelper = deploy(nonfungiblePositionManager);
        getLiquidityHelper[nonfungiblePositionManager] = liquidityHelper;
    }

    function setOwner(address newOwner) external override {
        require(msg.sender == owner, 'LiquidityFactory: FORBIDDEN');
        owner = newOwner;
    }
}