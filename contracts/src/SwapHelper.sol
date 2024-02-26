// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract SwapHelper {
    enum SwapType {
        EXACT_INPUT,
        EXACT_OUTPUT,
        EXACT_INPUT_MULTIHOP,
        EXACT_OUTPUT_MULTIHOP
    }

    struct SwapParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
        bytes path;
    }

    struct TradeParams {
        SwapType swapType;
        SwapParams tradeInfo;
        address SwapRouter;
    }

    function swapWithRouter(TradeParams calldata params) external returns (uint256 results) {
        if(params.swapType == SwapType.EXACT_INPUT) {
            uint256 amountOut = swapExactInputSingle(params);
            results = amountOut;
        } else if(params.swapType == SwapType.EXACT_OUTPUT) {
            uint256 amountIn = swapExactOutputSingle(params);
            results = amountIn;
        } else if(params.swapType == SwapType.EXACT_INPUT_MULTIHOP) {
            uint256 amountOut = swapExactInputMultihop(params);
            results = amountOut;
        } else if(params.swapType == SwapType.EXACT_OUTPUT_MULTIHOP) {
            uint256 amountIn = swapExactOutputMultihop(params);
            results = amountIn;
        }
    }

    function swapExactInputSingle(
        TradeParams calldata params
    ) internal returns (uint256 amountOut) {
        // msg.sender must approve this contract

        // Transfer the specified amount of firstToken to this contract.
        TransferHelper.safeTransferFrom(
            params.tradeInfo.tokenIn,
            params.tradeInfo.recipient,
            address(this),
            params.tradeInfo.amountIn
        );

        // Approve the router to spend firstToken.
        TransferHelper.safeApprove(params.tradeInfo.tokenIn, params.SwapRouter, params.tradeInfo.amountIn);

        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory swapParams = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: params.tradeInfo.tokenIn,
                tokenOut: params.tradeInfo.tokenOut,
                fee: params.tradeInfo.fee,
                recipient: params.tradeInfo.recipient,
                deadline: params.tradeInfo.deadline,
                amountIn: params.tradeInfo.amountIn,
                amountOutMinimum: params.tradeInfo.amountOutMinimum,
                sqrtPriceLimitX96: params.tradeInfo.sqrtPriceLimitX96
            });

        // The call to `exactInputSingle` executes the swap.
        amountOut = ISwapRouter(params.SwapRouter).exactInputSingle(swapParams);
    }

    function swapExactOutputSingle(
        TradeParams calldata params        
    ) internal returns (uint256 amountIn) {
        // Transfer the specified amount of firstToken to this contract.
        TransferHelper.safeTransferFrom(
            params.tradeInfo.tokenIn,
            params.tradeInfo.recipient,
            address(this),
            params.tradeInfo.amountInMaximum
        );

        // Approve the router to spend the specifed `amountInMaximum` of firstToken.
        // In production, you should choose the maximum amount to spend based on oracles or other data sources to acheive a better swap.
        TransferHelper.safeApprove(
            params.tradeInfo.tokenIn,
            params.SwapRouter,
            params.tradeInfo.amountInMaximum
        );

        ISwapRouter.ExactOutputSingleParams memory swapParams = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: params.tradeInfo.tokenIn,
                tokenOut: params.tradeInfo.tokenOut,
                fee: params.tradeInfo.fee,
                recipient: params.tradeInfo.recipient,
                deadline: params.tradeInfo.deadline,
                amountOut: params.tradeInfo.amountOut,
                amountInMaximum: params.tradeInfo.amountInMaximum,
                sqrtPriceLimitX96: params.tradeInfo.sqrtPriceLimitX96
            });

        // Executes the swap returning the amountIn needed to spend to receive the desired amountOut.
        amountIn = ISwapRouter(params.SwapRouter).exactOutputSingle(swapParams);

        // For exact output swaps, the amountInMaximum may not have all been spent.
        // If the actual amount spent (amountIn) is less than the specified maximum amount, we must refund the msg.sender and approve the swapRouter to spend 0.
        if (amountIn < params.tradeInfo.amountInMaximum) {
            TransferHelper.safeApprove(params.tradeInfo.tokenIn, params.SwapRouter, 0);
            TransferHelper.safeTransfer(
                params.tradeInfo.tokenIn,
                params.tradeInfo.recipient,
                params.tradeInfo.amountInMaximum - amountIn
            );
        }
    }

    /// @notice swapInputMultiplePools swaps a fixed amount of firstToken for a maximum possible amount of WETH9 through an intermediary pool.
    function swapExactInputMultihop(
        TradeParams calldata params
    ) internal returns (uint256 amountOut) {
        // Transfer `amountIn` of firstToken to this contract.
        TransferHelper.safeTransferFrom(
            params.tradeInfo.tokenIn,
            params.tradeInfo.recipient,
            address(this),
            params.tradeInfo.amountIn
        );

        // Approve the router to spend firstToken.
        TransferHelper.safeApprove(params.tradeInfo.tokenIn, params.SwapRouter, params.tradeInfo.amountIn);

        // Multiple pool swaps are encoded through bytes called a `path`. A path is a sequence of token addresses and poolFees that define the pools used in the swaps.
        // The format for pool encoding is (tokenIn, fee, tokenOut/tokenIn, fee, tokenOut) where tokenIn/tokenOut parameter is the shared token across the pools.
        // Since we are swapping firstToken to secondToken and then secondToken to WETH9 the path encoding is (firstToken, 0.3%, secondToken, 0.3%, WETH9).
        ISwapRouter.ExactInputParams memory swapParams = ISwapRouter
            .ExactInputParams({
                path: params.tradeInfo.path,
                recipient: params.tradeInfo.recipient,
                deadline: params.tradeInfo.deadline,
                amountIn: params.tradeInfo.amountIn,
                amountOutMinimum: params.tradeInfo.amountOutMinimum
            });

        // Executes the swap.
        amountOut = ISwapRouter(params.SwapRouter).exactInput(swapParams);
    }

    function swapExactOutputMultihop(
        TradeParams calldata params
    ) internal returns (uint256 amountIn) {
        // Transfer the specified `amountInMaximum` to this contract.
        TransferHelper.safeTransferFrom(
            params.tradeInfo.tokenIn,
            params.tradeInfo.recipient,
            address(this),
            params.tradeInfo.amountInMaximum
        );
        // Approve the router to spend  `amountInMaximum`.
        TransferHelper.safeApprove(
            params.tradeInfo.tokenIn,
            params.SwapRouter,
            params.tradeInfo.amountInMaximum
        );

        // The parameter path is encoded as (tokenOut, fee, tokenIn/tokenOut, fee, tokenIn)
        // The tokenIn/tokenOut field is the shared token between the two pools used in the multiple pool swap. In this case secondToken is the "shared" token.
        // For an exactOutput swap, the first swap that occurs is the swap which returns the eventual desired token.
        // In this case, our desired output token is WETH9 so that swap happpens first, and is encoded in the path accordingly.
        ISwapRouter.ExactOutputParams memory swapParams = ISwapRouter
            .ExactOutputParams({
                path: params.tradeInfo.path,
                recipient: params.tradeInfo.recipient,
                deadline: params.tradeInfo.deadline,
                amountOut: params.tradeInfo.amountOut,
                amountInMaximum: params.tradeInfo.amountInMaximum
            });

        // Executes the swap, returning the amountIn actually spent.
        amountIn = ISwapRouter(params.SwapRouter).exactOutput(swapParams);

        // If the swap did not require the full amountInMaximum to achieve the exact amountOut then we refund msg.sender and approve the router to spend 0.
        if (amountIn < params.tradeInfo.amountInMaximum) {
            TransferHelper.safeApprove(params.tradeInfo.tokenIn, params.SwapRouter, 0);
            TransferHelper.safeTransferFrom(
                params.tradeInfo.tokenIn,
                address(this),
                params.tradeInfo.recipient,
                params.tradeInfo.amountInMaximum - amountIn
            );
        }
    }
}
