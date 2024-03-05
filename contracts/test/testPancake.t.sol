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
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address private constant USDC_WHALE =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant USDT_WHALE =
        0x78C10214227E1489FB2f50D533814d77Ceb5A98a;
    address private constant WETH_WHALE = 
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address private constant PANCAKESWAP_NFT_POSITION_MANAGER =
        0x46A15B0b27311cedF172AB29E4f4766fbE7F4364;

    address private constant PANCAKESWAP_ROUTER =
        0x1b81D678ffb9C0263b24A97847620C99d213eB14;

    IERC20 private constant usdc = IERC20(USDC);
    IERC20 private constant usdt = IERC20(USDT);
    IERC20 private constant weth = IERC20(WETH9);

    LiquidityFactory private LPFac = new LiquidityFactory();

    LiquidityHelper private pancakeLiquidityHelper =
        LiquidityHelper(
            LPFac.createLiquidityHelper(PANCAKESWAP_NFT_POSITION_MANAGER)
        );

    SwapHelper private swap = new SwapHelper();

    function setUp() public {
        uint256 usdtAmount = 50 * 1e6;
        uint256 usdcAmount = 50 * 1e6;

        vm.prank(USDC_WHALE);
        usdc.transfer(address(this), usdcAmount);

        vm.prank(USDT_WHALE);
        usdt.safeTransfer(address(this), usdtAmount);

        usdc.approve(address(pancakeLiquidityHelper), usdcAmount / 3);
        usdt.safeApprove(address(pancakeLiquidityHelper), usdtAmount / 3);
    }

    // fee: 100, tickSpacing: 1
    function testLiquidityPancakeSwap() public {
        uint256 usdcAmount = 10 * 1e6;
        uint256 usdtAmount = 10 * 1e6;
        // Track total liquidity
        uint128 liquidity;

        LiquidityHelper.MintLPParams memory mintParams = LiquidityHelper
            .MintLPParams(
                USDC,
                USDT,
                100,
                (TickMath.MIN_TICK + 60) - ((TickMath.MIN_TICK + 60) % 60),
                (TickMath.MAX_TICK - 60) - ((TickMath.MAX_TICK - 60) % 60),
                usdcAmount,
                usdtAmount,
                address(this)
            );

        (
            uint tokenId,
            uint128 liquidityDelta,
            uint amount0,
            uint amount1
        ) = pancakeLiquidityHelper.mintNewPosition(mintParams);
        liquidity += liquidityDelta;

        console.log("--- Mint new position ---");
        console.log("token id", tokenId);
        console.log("liquidity", liquidity);
        console.log("amount 0", amount0);
        console.log("amount 1", amount1);

        // Collect fees
        (uint fee0, uint fee1) = pancakeLiquidityHelper.collectAllFees(tokenId);

        console.log("--- Collect fees ---");
        console.log("fee 0", fee0);
        console.log("fee 1", fee1);

        // Increase liquidity
        uint usdcAmountToAdd = 1 * 1e6;
        uint usdtAmountToAdd = 1 * 1e6;
        LiquidityHelper.AddLPParams memory addParams = LiquidityHelper
            .AddLPParams(tokenId, usdcAmountToAdd, usdtAmountToAdd);

        (liquidityDelta, amount0, amount1) = pancakeLiquidityHelper.addLiquidity(
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
        (amount0, amount1) = pancakeLiquidityHelper.removeLiquidity(removeParams);
        console.log("--- Decrease liquidity ---");
        console.log("amount 0", amount0);
        console.log("amount 1", amount1);
    }

    function testSwapExactInputSinglePancakeSwap() public {
        usdc.approve(address(swap), 10 * 1e6);
        SwapHelper.SwapParams memory tradeInfo = SwapHelper.SwapParams(
            USDC,
            USDT,
            100,
            address(this),
            block.timestamp + 1000,
            10 * 1e6,
            0,
            0,
            0,
            0,
            ""
        );
        SwapHelper.TradeParams memory params = SwapHelper.TradeParams(
            SwapHelper.SwapType.EXACT_INPUT,
            tradeInfo,
            PANCAKESWAP_ROUTER
        );
        uint256 amountOut = swap.swapWithRouter(params);
        console.log("amount out", amountOut);
    }

    function testSwapExactOutputSinglePancakeSwap() public {
        usdc.approve(address(swap), 10 * 1e6);
        SwapHelper.SwapParams memory tradeInfo = SwapHelper.SwapParams(
            USDC,
            USDT,
            100,
            address(this),
            block.timestamp + 1000,
            0,
            1 * 1e6,
            2 * 1e6,
            0,
            0,
            ""
        );
        SwapHelper.TradeParams memory params = SwapHelper.TradeParams(
            SwapHelper.SwapType.EXACT_OUTPUT,
            tradeInfo,
            PANCAKESWAP_ROUTER
        );
        uint256 amountIn = swap.swapWithRouter(params);
        console.log("amount in", amountIn);
    }

    function testSwapExactInputMultihop() public {
        usdc.approve(address(swap), 10 * 1e6);
        uint24 fee_usdc_weth = 500;
        uint24 fee_weth_usdt = 500;
        SwapHelper.SwapParams memory tradeInfo = SwapHelper.SwapParams(
            USDC,
            USDT,
            100,
            address(this),
            block.timestamp,
            10 * 1e6,
            0,
            0,
            0,
            0,
            abi.encodePacked(USDC, fee_usdc_weth, WETH9, fee_weth_usdt, USDT)
        );
        SwapHelper.TradeParams memory params = SwapHelper.TradeParams(
            SwapHelper.SwapType.EXACT_INPUT_MULTIHOP,
            tradeInfo,
            PANCAKESWAP_ROUTER
        );
        uint256 amountOut = swap.swapWithRouter(params);
        console.log("amount out", amountOut);
    }

    function testSwapExactOutputMultihop() public {
        usdc.approve(address(swap), 10 * 1e6);
        uint24 fee_usdc_weth = 500;
        uint24 fee_weth_usdt = 500;
        SwapHelper.SwapParams memory tradeInfo = SwapHelper.SwapParams(
            USDC,
            USDT,
            500,
            address(this),
            block.timestamp,
            0,
            9 * 1e6,
            10 * 1e6,
            0,
            0,
            abi.encodePacked(USDT, fee_weth_usdt, WETH9, fee_usdc_weth, USDC)
        );
        SwapHelper.TradeParams memory params = SwapHelper.TradeParams(
            SwapHelper.SwapType.EXACT_OUTPUT_MULTIHOP,
            tradeInfo,
            PANCAKESWAP_ROUTER
        );
        uint256 amountIn = swap.swapWithRouter(params);
        console.log("amount in", amountIn);
    }
}
