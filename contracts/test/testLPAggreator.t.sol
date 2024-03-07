// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/LPAggreator.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/safeERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract TestLPAggreator is Test {
    using SafeERC20 for IERC20;
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    IERC20 constant pair = IERC20(0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852);

    address private constant DAI_WHALE =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant USDC_WHALE =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant WETH_WHALE =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant USDT_WHALE =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address private constant UNISWAP_ROUTER02_ADDRESS =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 private constant uniswapRouter =
        IUniswapV2Router02(UNISWAP_ROUTER02_ADDRESS);
    address private constant FACTORY =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    LPAggreator lpAggreator = new LPAggreator();

    IERC20 private constant usdc = IERC20(USDC);
    IERC20 private constant dai = IERC20(DAI);
    IERC20 private constant weth = IERC20(WETH);
    IERC20 private constant usdt = IERC20(USDT);

    uint256 private liquidity = 0;

    function setUp() public payable {
        deal(USDT, address(this), 1e6 * 1e6);
        deal(WETH, address(this), 1e18 * 1e6);
        // Approve uni for transferring
        usdt.safeApprove(UNISWAP_ROUTER02_ADDRESS, 1e6 * 1e6);
        weth.safeApprove(UNISWAP_ROUTER02_ADDRESS, 1e18 * 1e6);

        (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidityMinted
        ) = uniswapRouter.addLiquidity(
                WETH,
                USDT,
                1e6 * 1e18,
                1e6 * 1e6,
                1,
                1,
                address(this),
                block.timestamp
            );

        liquidity = liquidityMinted;
        console.log("Liquidity: %s", liquidity);
        console.log("amountA: %s, amountB: %s", amountA, amountB);
        console.log("pair balance: %s", pair.balanceOf(address(this)));
        assertGt(pair.balanceOf(address(this)), 0);
    }

    function testSwapLP() public {
        console.log("--------------------");
        console.log("pair balance: %s", pair.balanceOf(address(this)));

        LPAggreator.RemoveLPParams memory removeParams = LPAggreator
            .RemoveLPParams(
                USDT,
                WETH,
                liquidity,
                0,
                0,
                address(lpAggreator),
                block.timestamp
            );
        LPAggreator.AddLPParams memory addParams = LPAggreator.AddLPParams(
            DAI,
            WETH,
            0,
            0,
            0,
            0,
            address(this),
            block.timestamp
        );
        IERC20(pair).safeApprove(address(lpAggreator), liquidity);
        (uint256 amountA, uint256 amountB, uint256 liquidityMinted) = lpAggreator.swapLP(removeParams, addParams);
        console.log('Swap liquidity success, amountA: %s, amountB: %s, liquidity: %s', amountA, amountB, liquidityMinted);
    }
}
