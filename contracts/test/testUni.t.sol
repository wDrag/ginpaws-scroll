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
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    address private constant DAI_WHALE =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant USDC_WHALE =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant WETH9_WHALE =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant USDT_WHALE =
        0x78C10214227E1489FB2f50D533814d77Ceb5A98a;

    address private constant UNISWAP_NFT_POSITION_MANAGER =
        0xC36442b4a4522E871399CD717aBDD847Ab11FE88;

    address private constant UNISWAP_ROUTER =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;

    IERC20 private constant usdc = IERC20(USDC);
    IERC20 private constant dai = IERC20(DAI);
    IERC20 private constant weth = IERC20(WETH9);
    IERC20 private constant usdt = IERC20(USDT);

    LiquidityFactory private LPFac = new LiquidityFactory();

    LiquidityHelper private uniLiquidityHelper =
        LiquidityHelper(
            LPFac.createLiquidityHelper(UNISWAP_NFT_POSITION_MANAGER)
        );

    SwapHelper private swap = new SwapHelper();

    function setUp() public {
        uint256 usdtAmount = 50 * 1e6;
        uint256 daiAmount = 50 * 1e18;
        uint256 usdcAmount = 50 * 1e6;
        uint256 wethAmount = 3 * 1e18;

        assert(usdt.balanceOf(USDT_WHALE) >= usdtAmount);

        vm.prank(DAI_WHALE);
        dai.transfer(address(this), daiAmount);

        vm.prank(USDC_WHALE);
        usdc.transfer(address(this), usdcAmount);

        vm.prank(WETH9_WHALE);
        weth.transfer(address(this), wethAmount);

        vm.prank(USDT_WHALE);
        usdt.safeTransfer(address(this), usdtAmount);

        dai.approve(address(uniLiquidityHelper), daiAmount);
        usdc.approve(address(uniLiquidityHelper), usdcAmount);
        weth.approve(address(uniLiquidityHelper), wethAmount);
        usdt.safeApprove(address(uniLiquidityHelper), usdtAmount);
    }

    // fee: 3000, tickSpacing: 60
    function testLiquidityUniSwap() public {
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
        ) = uniLiquidityHelper.mintNewPosition(mintParams);
        liquidity += liquidityDelta;

        console.log("--- Mint new position ---");
        console.log("token id", tokenId);
        console.log("liquidity", liquidity);
        console.log("amount 0", amount0);
        console.log("amount 1", amount1);

        // Collect fees
        (uint fee0, uint fee1) = uniLiquidityHelper.collectAllFees(tokenId);

        console.log("--- Collect fees ---");
        console.log("fee 0", fee0);
        console.log("fee 1", fee1);

        // Increase liquidity
        uint daiAmountToAdd = 1 * 1e18;
        uint usdcAmountToAdd = 1 * 1e6;
        LiquidityHelper.AddLPParams memory addParams = LiquidityHelper
            .AddLPParams(tokenId, daiAmountToAdd, usdcAmountToAdd);

        (liquidityDelta, amount0, amount1) = uniLiquidityHelper.addLiquidity(
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
        (amount0, amount1) = uniLiquidityHelper.removeLiquidity(removeParams);
        console.log("--- Decrease liquidity ---");
        console.log("amount 0", amount0);
        console.log("amount 1", amount1);
    }

    function testSwapExactInputSingleUniSwap() public {
        dai.approve(address(swap), 10 * 1e18);
        SwapHelper.SwapParams memory tradeInfo = SwapHelper.SwapParams(
            DAI,
            USDC,
            3000,
            address(this),
            block.timestamp + 1000,
            10 * 1e18,
            0,
            0,
            0,
            0,
            ""
        );
        SwapHelper.TradeParams memory params = SwapHelper.TradeParams(
            SwapHelper.SwapType.EXACT_INPUT,
            tradeInfo,
            UNISWAP_ROUTER
        );
        uint256 amountOut = swap.swapWithRouter(params);
        console.log("amount out", amountOut);
    }

    function testSwapExactOutputSingleUniSwap() public {
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
            UNISWAP_ROUTER
        );
        uint256 amountIn = swap.swapWithRouter(params);
        console.log("amount in", amountIn);
    }

    function testSwapExactInputMultihopUniSwap() public {
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
            UNISWAP_ROUTER
        );
        uint256 amountOut = swap.swapWithRouter(params);
        console.log("amount out", amountOut);
    }

    function testSwapExactOutputMultihopUniSwap() public {
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
            UNISWAP_ROUTER
        );
        uint256 amountIn = swap.swapWithRouter(params);
        console.log("amount in", amountIn);
    }
}
