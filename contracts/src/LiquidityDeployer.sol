//SPDX-Licenses-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import './LiquidityHelper.sol';

contract LiquidityHelperDeployer {
    struct Parameters {
        INonfungiblePositionManager nonfungiblePositionManager;
    }

    function deploy(
        address nonfungiblePositionManager
    ) internal returns (address liquidityHelper) {
        liquidityHelper = address(new LiquidityHelper(INonfungiblePositionManager(nonfungiblePositionManager)));
    }
}