// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/LiquidityHelperFactory.sol";
import "../src/LiquidityHelper.sol";
import "../src/SwapHelper.sol";

contract UniswapV3LiquidityTest is Test {
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant DAI_WHALE =
        0xe81D6f03028107A20DBc83176DA82aE8099E9C42;
    address private constant USDC_WHALE =
        0xe81D6f03028107A20DBc83176DA82aE8099E9C42;

    IERC20 private constant usdc = IERC20(USDC);
    IERC20 private constant dai = IERC20(DAI);

    LiquidityFactory private LPFac = new LiquidityFactory();

    LiquidityHelper private liquid =
        LiquidityHelper(
            LPFac.createLiquidityHelper(0xC36442b4a4522E871399CD717aBDD847Ab11FE88)
        );
    SwapHelper private swap = new SwapHelper();

    function setUp() public {
        uint256 daiAmount = 50 * 1e18;
        uint256 usdcAmount = 50 * 1e6;
        vm.prank(DAI_WHALE);
        dai.transfer(address(this), daiAmount);

        vm.prank(USDC_WHALE);
        usdc.transfer(address(this), usdcAmount);

        dai.approve(address(liquid), daiAmount);
        usdc.approve(address(liquid), usdcAmount);

        console.log("address: ", address(this));
        console.log("DAI WHALE", dai.balanceOf(DAI_WHALE));
        console.log("DAI balance", dai.balanceOf(address(this)));
        console.log("USDC WHALE", usdc.balanceOf(USDC_WHALE));
        console.log("USDC balance", usdc.balanceOf(address(this)));

        assertEq(dai.balanceOf(address(this)), daiAmount);
        assertEq(usdc.balanceOf(address(this)), usdcAmount);
    }

    function testLiquidity() public {
        uint256 daiAmount = 10 * 1e18;
        uint256 usdcAmount = 10 * 1e6;
        // Track total liquidity
        uint128 liquidity;

        LiquidityHelper.MintLPParams memory mintParams = LiquidityHelper
            .MintLPParams(
                DAI,
                USDC,
                3000,
                (TickMath.MIN_TICK + 60) - ((TickMath.MIN_TICK + 60) % 60),
                (TickMath.MAX_TICK - 60) - ((TickMath.MAX_TICK - 60) % 60),
                daiAmount,
                usdcAmount,
                address(this)
            );

        (
            uint tokenId,
            uint128 liquidityDelta,
            uint amount0,
            uint amount1
        ) = liquid.mintNewPosition(mintParams);
        liquidity += liquidityDelta;

        console.log("--- Mint new position ---");
        console.log("token id", tokenId);
        console.log("liquidity", liquidity);
        console.log("amount 0", amount0);
        console.log("amount 1", amount1);

        // Collect fees
        (uint fee0, uint fee1) = liquid.collectAllFees(tokenId);

        console.log("--- Collect fees ---");
        console.log("fee 0", fee0);
        console.log("fee 1", fee1);

        // Increase liquidity
        uint daiAmountToAdd = 1 * 1e18;
        uint usdcAmountToAdd = 1 * 1e6;
        LiquidityHelper.AddLPParams memory addParams = LiquidityHelper
            .AddLPParams(tokenId, daiAmountToAdd, usdcAmountToAdd);

        (liquidityDelta, amount0, amount1) = liquid.addLiquidity(addParams);
        liquidity += liquidityDelta;

        console.log("--- Increase liquidity ---");
        console.log("liquidity", liquidity);
        console.log("amount 0", amount0);
        console.log("amount 1", amount1);

        //Decrease liquidity
        LiquidityHelper.RemoveLPParams memory removeParams = LiquidityHelper
            .RemoveLPParams(tokenId, liquidity / 2);
        (amount0, amount1) = liquid.removeLiquidity(removeParams);
        console.log("--- Decrease liquidity ---");
        console.log("amount 0", amount0);
        console.log("amount 1", amount1);
    }

    function testSwapExactInputSingle() public {
        dai.approve(address(swap), 1 * 1e18);
        SwapHelper.SwapParams memory tradeInfo = SwapHelper.SwapParams(
            DAI,
            USDC,
            3000,
            address(this),
            block.timestamp + 1000,
            1 * 1e18,
            0,
            0,
            0,
            0,
            ""
        );
        SwapHelper.TradeParams memory params = SwapHelper.TradeParams(
            SwapHelper.SwapType.EXACT_INPUT,
            tradeInfo,
            0xE592427A0AEce92De3Edee1F18E0157C05861564
        );
        uint256 amountOut = swap.swapWithRouter(params);
        console.log("amount out", amountOut);
    }

    function testSwapExactOutputSingle() public {
        dai.approve(address(swap), 2 * 1e18);
        SwapHelper.SwapParams memory tradeInfo = SwapHelper.SwapParams(
            DAI,
            USDC,
            3000,
            address(this),
            block.timestamp + 1000,
            0,
            1 * 1e6,
            2 * 1e18,
            0,
            0,
            ""
        );
        SwapHelper.TradeParams memory params = SwapHelper.TradeParams(
            SwapHelper.SwapType.EXACT_OUTPUT,
            tradeInfo,
            0xE592427A0AEce92De3Edee1F18E0157C05861564
        );
        uint256 amountIn = swap.swapWithRouter(params);
        console.log("amount in", amountIn);
    }

    function testSwapExactInputMultihop() public {
        dai.approve(address(swap), 1 * 1e18);
        uint24 fee = 3000;
        SwapHelper.SwapParams memory tradeInfo = SwapHelper.SwapParams(
            DAI,
            USDC,
            3000,
            address(this),
            block.timestamp,
            1 * 1e18,
            0,
            0,
            0,
            0,
            abi.encodePacked(DAI, fee, WETH9, fee, USDC)
        );
        SwapHelper.TradeParams memory params = SwapHelper.TradeParams(
            SwapHelper.SwapType.EXACT_INPUT_MULTIHOP,
            tradeInfo,
            0xE592427A0AEce92De3Edee1F18E0157C05861564
        );
        uint256 amountOut = swap.swapWithRouter(params);
        console.log("amount out", amountOut);
    }

    function testSwapExactOutputMultihop() public {
        dai.approve(address(swap), 2 * 1e18);
        uint24 fee = 3000;
        SwapHelper.SwapParams memory tradeInfo = SwapHelper.SwapParams(
            DAI,
            USDC,
            3000,
            address(this),
            block.timestamp,
            0,
            1 * 1e6,
            2 * 1e18,
            0,
            0,
            abi.encodePacked(USDC, fee, WETH9, fee, DAI)
        );
        SwapHelper.TradeParams memory params = SwapHelper.TradeParams(
            SwapHelper.SwapType.EXACT_OUTPUT_MULTIHOP,
            tradeInfo,
            0xE592427A0AEce92De3Edee1F18E0157C05861564
        );
        uint256 amountIn = swap.swapWithRouter(params);
        console.log("amount in", amountIn);
    }
}
