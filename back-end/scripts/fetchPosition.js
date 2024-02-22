const ethers = require("ethers");
const { computePoolAddress } = require("@uniswap/v3-sdk");
const IUniswapV3PoolABI = require("@uniswap/v3-core/artifacts/contracts/interfaces/IUniswapV3Pool.sol/IUniswapV3Pool.json");
const Quoter = require("@uniswap/v3-periphery/artifacts/contracts/lens/Quoter.sol/Quoter.json");
const {
  WETH_ADDRESS,
  QUOTER_ADDRESS,
  RPC_URL,
  FACTORY_ADDRESS,
  getPoolInfo,
  getWalletAddress,
} = require("./helper");
const {
  Token,
  NONFUNGIBLE_POSITION_MANAGER_ADDRESSES,
} = require("@uniswap/sdk-core");
const ERC20ABI = require("../abi/ERC20.json");

const INONFUNGIBLE_POSITION_MANAGER = require("@uniswap/v3-periphery/artifacts/contracts/NonfungiblePositionManager.sol/NonfungiblePositionManager.json");

async function fetchPostions(tokenIn, tokenOut) {
  const provider = new ethers.providers.JsonRpcProvider(RPC_URL);
  const chainId = (await provider.getNetwork()).chainId;

  const tokenA = new Token(
    chainId,
    tokenIn,
    await new ethers.Contract(tokenIn, ERC20ABI, provider).callStatic.decimals()
  );
  const tokenB = new Token(
    chainId,
    tokenOut,
    await new ethers.Contract(
      tokenOut,
      ERC20ABI,
      provider
    ).callStatic.decimals()
  );

  const nfpmContract = new ethers.Contract(
    NONFUNGIBLE_POSITION_MANAGER_ADDRESSES[chainId],
    INONFUNGIBLE_POSITION_MANAGER.abi,
    provider
  );
  const walletAddress = getWalletAddress();
  const numPositions = await nfpmContract.callStatic.balanceOf(walletAddress);
  const calls = [];
  for (let i = 0; i < numPositions; i++) {
    calls.push(nfpmContract.callStatic.tokenOfOwnerByIndex(walletAddress, i));
  }
  const positionIds = await Promise.all(calls);
  const positionCalls = [];
  for (let id of positionIds) {
    positionCalls.push(nfpmContract.callStatic.positions(id));
  }
  const positions = await Promise.all(positionCalls);
  const positionInfos = positions.map((position) => {
    return {
      tickLower: position.tickLower,
      tickUpper: position.tickUpper,
      liquidity: BigInt(position.liquidity),
      feeGrowthInside0LastX128: BigInt(position.feeGrowthInside0LastX128),
      feeGrowthInside1LastX128: BigInt(position.feeGrowthInside1LastX128),
      tokensOwed0: BigInt(position.tokensOwed0),
      tokensOwed1: BigInt(position.tokensOwed1),
    };
  });
  console.log(positionInfos);
}

module.exports = {
  fetchPostions,
};
fetchPostions(
  WETH_ADDRESS,
  "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48" // USDC
);

// async function main() {
//   console.log(
//     await getOutputQuote(
//       WETH_ADDRESS,
//       "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", // USDC
//       3000,
//       ethers.utils.parseEther("1")
//     )
//   );
// }
// main();
