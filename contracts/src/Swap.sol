// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';

contract SwapHelper {
    // For the scope of these swap examples,
    // we will detail the design considerations when using
    // `exactInput`, `exactInputSingle`, `exactOutput`, and  `exactOutputSingle`.

    // It should be noted that for the sake of these examples, we purposefully pass in the swap router instead of inherit the swap router for simplicity.
    // More advanced example contracts will detail how to inherit the swap router safely.

    address public immutable firstToken;
    address public immutable secondToken;
    ISwapRouter public immutable swapRouter;

    // For this example, we will set the pool fee to 0.3%.
    uint24 public constant poolFee = 3000;

    constructor(ISwapRouter _swapRouter, address _firstToken, address _secondToken) {
        swapRouter = _swapRouter;
        firstToken = _firstToken;
        secondToken = _secondToken;
    }

    /// @notice swapExactInputSingle swaps a fixed amount of firstToken for a maximum possible amount of WETH9
    /// using the firstToken/WETH9 0.3% pool by calling `exactInputSingle` in the swap router.
    /// @dev The calling address must approve this contract to spend at least `amountIn` worth of its firstToken for this function to succeed.
    /// @param amountIn The exact amount of firstToken that will be swapped for WETH9.
    /// @return amountOut The amount of WETH9 received.
    function swapExactInputSingle(uint256 amountIn) external returns (uint256 amountOut) {
        // msg.sender must approve this contract

        // Transfer the specified amount of firstToken to this contract.
        TransferHelper.safeTransferFrom(firstToken, msg.sender, address(this), amountIn);

        // Approve the router to spend firstToken.
        TransferHelper.safeApprove(firstToken, address(swapRouter), amountIn);

        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: firstToken,
                tokenOut: secondToken,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        amountOut = swapRouter.exactInputSingle(params);
    }

    /// @notice swapExactOutputSingle swaps a minimum possible amount of firstToken for a fixed amount of WETH.
    /// @dev The calling address must approve this contract to spend its firstToken for this function to succeed. As the amount of input firstToken is variable,
    /// the calling address will need to approve for a slightly higher amount, anticipating some variance.
    /// @param amountOut The exact amount of WETH9 to receive from the swap.
    /// @param amountInMaximum The amount of firstToken we are willing to spend to receive the specified amount of WETH9.
    /// @return amountIn The amount of firstToken actually spent in the swap.
    function swapExactOutputSingle(uint256 amountOut, uint256 amountInMaximum) external returns (uint256 amountIn) {
        // Transfer the specified amount of firstToken to this contract.
        TransferHelper.safeTransferFrom(firstToken, msg.sender, address(this), amountInMaximum);

        // Approve the router to spend the specifed `amountInMaximum` of firstToken.
        // In production, you should choose the maximum amount to spend based on oracles or other data sources to acheive a better swap.
        TransferHelper.safeApprove(firstToken, address(swapRouter), amountInMaximum);

        ISwapRouter.ExactOutputSingleParams memory params =
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: firstToken,
                tokenOut: secondToken,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum,
                sqrtPriceLimitX96: 0
            });

        // Executes the swap returning the amountIn needed to spend to receive the desired amountOut.
        amountIn = swapRouter.exactOutputSingle(params);

        // For exact output swaps, the amountInMaximum may not have all been spent.
        // If the actual amount spent (amountIn) is less than the specified maximum amount, we must refund the msg.sender and approve the swapRouter to spend 0.
        if (amountIn < amountInMaximum) {
            TransferHelper.safeApprove(firstToken, address(swapRouter), 0);
            TransferHelper.safeTransfer(firstToken, msg.sender, amountInMaximum - amountIn);
        }
    }

    /// @notice swapInputMultiplePools swaps a fixed amount of firstToken for a maximum possible amount of WETH9 through an intermediary pool.
    /// For this example, we will swap firstToken to secondToken, then secondToken to WETH9 to achieve our desired output.
    /// @dev The calling address must approve this contract to spend at least `amountIn` worth of its firstToken for this function to succeed.
    /// @param amountIn The amount of firstToken to be swapped.
    /// @return amountOut The amount of WETH9 received after the swap.
    function swapExactInputMultihop(uint256 amountIn, bytes calldata swapPath) external returns (uint256 amountOut) {
        // Transfer `amountIn` of firstToken to this contract.
        TransferHelper.safeTransferFrom(firstToken, msg.sender, address(this), amountIn);

        // Approve the router to spend firstToken.
        TransferHelper.safeApprove(firstToken, address(swapRouter), amountIn);

        // Multiple pool swaps are encoded through bytes called a `path`. A path is a sequence of token addresses and poolFees that define the pools used in the swaps.
        // The format for pool encoding is (tokenIn, fee, tokenOut/tokenIn, fee, tokenOut) where tokenIn/tokenOut parameter is the shared token across the pools.
        // Since we are swapping firstToken to secondToken and then secondToken to WETH9 the path encoding is (firstToken, 0.3%, secondToken, 0.3%, WETH9).
        ISwapRouter.ExactInputParams memory params =
            ISwapRouter.ExactInputParams({
                path: swapPath,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0
            });

        // Executes the swap.
        amountOut = swapRouter.exactInput(params);
    }

    /// @notice swapExactOutputMultihop swaps a minimum possible amount of firstToken for a fixed amount of WETH through an intermediary pool.
    /// For this example, we want to swap firstToken for WETH9 through a secondToken pool but we specify the desired amountOut of WETH9. Notice how the path encoding is slightly different in for exact output swaps.
    /// @dev The calling address must approve this contract to spend its firstToken for this function to succeed. As the amount of input firstToken is variable,
    /// the calling address will need to approve for a slightly higher amount, anticipating some variance.
    /// @param amountOut The desired amount of WETH9.
    /// @param amountInMaximum The maximum amount of firstToken willing to be swapped for the specified amountOut of WETH9.
    /// @return amountIn The amountIn of firstToken actually spent to receive the desired amountOut.
    function swapExactOutputMultihop(uint256 amountOut, uint256 amountInMaximum, bytes calldata swapPath) external returns (uint256 amountIn) {
        // Transfer the specified `amountInMaximum` to this contract.
        TransferHelper.safeTransferFrom(firstToken, msg.sender, address(this), amountInMaximum);
        // Approve the router to spend  `amountInMaximum`.
        TransferHelper.safeApprove(firstToken, address(swapRouter), amountInMaximum);

        // The parameter path is encoded as (tokenOut, fee, tokenIn/tokenOut, fee, tokenIn)
        // The tokenIn/tokenOut field is the shared token between the two pools used in the multiple pool swap. In this case secondToken is the "shared" token.
        // For an exactOutput swap, the first swap that occurs is the swap which returns the eventual desired token.
        // In this case, our desired output token is WETH9 so that swap happpens first, and is encoded in the path accordingly.
        ISwapRouter.ExactOutputParams memory params =
            ISwapRouter.ExactOutputParams({
                path: swapPath,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum
            });

        // Executes the swap, returning the amountIn actually spent.
        amountIn = swapRouter.exactOutput(params);

        // If the swap did not require the full amountInMaximum to achieve the exact amountOut then we refund msg.sender and approve the router to spend 0.
        if (amountIn < amountInMaximum) {
            TransferHelper.safeApprove(firstToken, address(swapRouter), 0);
            TransferHelper.safeTransferFrom(firstToken, address(this), msg.sender, amountInMaximum - amountIn);
        }
    }
}