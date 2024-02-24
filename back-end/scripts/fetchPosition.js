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
  getProvider,
} = require("./helper");
const {
  Token,
  NONFUNGIBLE_POSITION_MANAGER_ADDRESSES,
} = require("@uniswap/sdk-core");
const ERC20ABI = require("../abi/ERC20.json");

const INONFUNGIBLE_POSITION_MANAGER = require("@uniswap/v3-periphery/artifacts/contracts/NonfungiblePositionManager.sol/NonfungiblePositionManager.json");

async function fetchPostions() {
  const provider = new ethers.providers.JsonRpcProvider(RPC_URL);
  const chainId = (await provider.getNetwork()).chainId;

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
  const positionInfos = positions.map((position, id) => {
    return {
      positionId: parseInt(positionIds[id].toString()),
      tickLower: position.tickLower,
      tickUpper: position.tickUpper,
      liquidity: BigInt(position.liquidity),
      feeGrowthInside0LastX128: BigInt(position.feeGrowthInside0LastX128),
      feeGrowthInside1LastX128: BigInt(position.feeGrowthInside1LastX128),
      tokensOwed0: BigInt(position.tokensOwed0),
      tokensOwed1: BigInt(position.tokensOwed1),
    };
  });
  return positionInfos;
}
module.exports = {
  fetchPostions,
};

async function main() {
  console.log(await fetchPostions());
}
// main();
