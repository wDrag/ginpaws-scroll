// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/Liquidity.sol";
import "../src/Swap.sol";

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

    LiquidityHelper private liquid =
        new LiquidityHelper(
            INonfungiblePositionManager(
                0xC36442b4a4522E871399CD717aBDD847Ab11FE88
            ),
            DAI,
            USDC
        );
    SwapHelper private swap = new SwapHelper(ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564), DAI, USDC);

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
        (
            uint tokenId,
            uint128 liquidityDelta,
            uint amount0,
            uint amount1
        ) = liquid.mintNewPosition(daiAmount, usdcAmount);
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

        (liquidityDelta, amount0, amount1) = liquid
            .increaseLiquidityCurrentRange(
                tokenId,
                daiAmountToAdd,
                usdcAmountToAdd
            );
        liquidity += liquidityDelta;

        console.log("--- Increase liquidity ---");
        console.log("liquidity", liquidity);
        console.log("amount 0", amount0);
        console.log("amount 1", amount1);

        //Decrease liquidity
        (amount0, amount1) = liquid.decreaseLiquidityCurrentRange(tokenId, liquidity);
        console.log("--- Decrease liquidity ---");
        console.log("amount 0", amount0);
        console.log("amount 1", amount1);
    }

    function testSwapExactInputSingle() public {
        dai.approve(address(swap), 1 * 1e18);
        uint256 amountIn = 1 * 1e18;
        uint256 amountOut = swap.swapExactInputSingle(amountIn);
        console.log("amount out", amountOut);
    }

    function testSwapExactOutputSingle() public {
        dai.approve(address(swap), 5 * 1e18);
        uint256 amountOut = 1 * 1e6;
        uint256 amountInMaximum = 5 * 1e18;
        uint256 amountIn = swap.swapExactOutputSingle(
            amountOut,
            amountInMaximum
        );
        console.log("amount in", amountIn);
    }

    function testSwapExactInputMultihop() public {
        dai.approve(address(swap), 1 * 1e18);
        uint256 amountIn = 1 * 1e18;
        uint24 fee = 3000;
        uint256 amountOut = swap.swapExactInputMultihop(amountIn, abi.encodePacked(DAI, fee, WETH9, fee, USDC));
        console.log("amount out", amountOut);
    }

    function testSwapExactOutputMultihop() public {
        dai.approve(address(swap), 5 * 1e18);
        uint256 amountOut = 1 * 1e6;
        uint256 amountInMaximum = 5 * 1e18;
        uint24 fee = 3000;
        uint256 amountIn = swap.swapExactOutputMultihop(
            amountOut,
            amountInMaximum,
            abi.encodePacked(USDC, fee, WETH9, fee, DAI)
        );
        console.log("amount in", amountIn);
    }
}
