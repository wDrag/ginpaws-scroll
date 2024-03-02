// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/LiquidityHelperFactory.sol";
import "../src/LiquidityHelper.sol";
import "../src/SwapHelper.sol";
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

contract TestLPAggreator is Test {
    using SafeERC20 for IERC20;
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address private constant DAI_WHALE =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant WETH9_WHALE =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address private constant SUSHISWAP_NFT_POSITION_MANAGER =
        0x2214A42d8e2A1d20635c2cb0664422c528B6A432;

    IERC20 private constant dai = IERC20(DAI);
    IERC20 private constant weth = IERC20(WETH9);

    LiquidityFactory private LPFac = new LiquidityFactory();

    LiquidityHelper private sushiLiquidityHelper =
        LiquidityHelper(
            LPFac.createLiquidityHelper(SUSHISWAP_NFT_POSITION_MANAGER)
        );

    SwapHelper private swap = new SwapHelper();

    function setUp() public {
        uint256 daiAmount = 50 * 1e18;
        uint256 wethAmount = 1 * 1e18;

        vm.prank(DAI_WHALE);
        dai.transfer(address(this), daiAmount);

        vm.prank(WETH9_WHALE);
        weth.transfer(address(this), wethAmount);

        dai.approve(address(sushiLiquidityHelper), daiAmount / 3);
        weth.approve(address(sushiLiquidityHelper), wethAmount / 3);
    }

    function testLiquiditySushiSwap() public {
        uint256 daiAmount = 10 * 1e18;
        uint256 wethAmount = 1 * 1e17;
        // Track total liquidity
        uint128 liquidity;

        LiquidityHelper.MintLPParams memory mintParams = LiquidityHelper
            .MintLPParams(
                DAI,
                WETH9,
                3000,
                (TickMath.MIN_TICK + 60) - ((TickMath.MIN_TICK + 60) % 60),
                (TickMath.MAX_TICK - 60) - ((TickMath.MAX_TICK - 60) % 60),
                daiAmount,
                wethAmount,
                address(this)
            );

        (
            uint tokenId,
            uint128 liquidityDelta,
            uint amount0,
            uint amount1
        ) = sushiLiquidityHelper.mintNewPosition(mintParams);
        liquidity += liquidityDelta;

        console.log("--- Mint new position ---");
        console.log("token id", tokenId);
        console.log("liquidity", liquidity);
        console.log("amount 0", amount0);
        console.log("amount 1", amount1);

        // Collect fees
        (uint fee0, uint fee1) = sushiLiquidityHelper.collectAllFees(tokenId);

        console.log("--- Collect fees ---");
        console.log("fee 0", fee0);
        console.log("fee 1", fee1);

        // Increase liquidity
        uint daiAmountToAdd = 1 * 1e18;
        uint wethAmountToAdd = 1 * 1e17;
        LiquidityHelper.AddLPParams memory addParams = LiquidityHelper
            .AddLPParams(tokenId, daiAmountToAdd, wethAmountToAdd);

        (liquidityDelta, amount0, amount1) = sushiLiquidityHelper.addLiquidity(
            addParams
        );
        liquidity += liquidityDelta;

        console.log("--- Increase liquidity ---");
        console.log("liquidity", liquidity);
        console.log("amount 0", amount0);
        console.log("amount 1", amount1);

        //Decrease liquidity
        LiquidityHelper.RemoveLPParams memory removeParams = LiquidityHelper
            .RemoveLPParams(tokenId, liquidity / 2);
        (amount0, amount1) = sushiLiquidityHelper.removeLiquidity(removeParams);
        console.log("--- Decrease liquidity ---");
        console.log("amount 0", amount0);
        console.log("amount 1", amount1);
    }
}
