// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

interface ILiquidityHelperFactory {
    function createLiquidityHelper(
        address nonfungiblePositionManager
    ) external returns (address liquidityHelper);

    function setOwner(address newOwner) external;
}