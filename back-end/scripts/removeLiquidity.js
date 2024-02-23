const { ethers, Wallet } = require("ethers");
const {
  getProvider,
  getWalletAddress,
  getTokenTransferApproval,
  makeToken,
  getBalance,
  toReadableAmount,
  USDC_ADDRESS,
  DAI_ADDRESS,
} = require("./helper");
const ERC20ABI = require("../abi/ERC20.json");

const { NONFUNGIBLE_POSITION_MANAGER_ADDRESSES } = require("@uniswap/sdk-core");
const {
  abi: NonfungiblePositionManagerABI,
} = require("@uniswap/v3-periphery/artifacts/contracts/NonfungiblePositionManager.sol/NonfungiblePositionManager.json");
const { fetchPostions } = require("./fetchPosition");
const { DENOMINATOR } = require("./LP_Helper");

async function removeLiquidity(tokenId, token0, token1, fee, removePercent) {
  const provider = getProvider();
  const chainId = (await provider.getNetwork()).chainId;
  const tokenA = await makeToken(token0);
  const tokenB = await makeToken(token1);
  console.log(
    `Removing ${(removePercent / DENOMINATOR) * 100}% for: `,
    tokenA.symbol,
    tokenB.symbol,
    fee
  );
  console.log();

  const nftPositionManager = new ethers.Contract(
    NONFUNGIBLE_POSITION_MANAGER_ADDRESSES[chainId],
    NonfungiblePositionManagerABI,
    provider
  );

  const positionInfo = await nftPositionManager.callStatic.positions(tokenId);
  const liquidity = positionInfo.liquidity;

  const params = {
    tokenId,
    liquidity: (
      (BigInt(liquidity) / BigInt(DENOMINATOR)) *
      BigInt(removePercent)
    ).toString(),
    amount0Min: 0,
    amount1Min: 0,
    deadline: Math.floor(Date.now() / 1000) + 60 * 20,
  };
  const wallet = new Wallet(process.env.PRIVATE_KEY, provider);
  const tx = await nftPositionManager
    .connect(wallet)
    .decreaseLiquidity(params, {
      gasLimit: 1_000_000,
    });
  await tx.wait();
  console.log("Liquidity added");
  console.log("Transaction hash: ", tx.hash);
}

async function main() {
  const provider = getProvider();
  const walletAddress = getWalletAddress();
  const DAI_Contract = new ethers.Contract(DAI_ADDRESS, ERC20ABI, provider);
  const USDC_Contract = new ethers.Contract(USDC_ADDRESS, ERC20ABI, provider);
  console.log(
    "Before balance: ",
    ethers.utils.formatUnits(await getBalance(DAI_Contract, walletAddress), 18),
    " / ",
    ethers.utils.formatUnits(await getBalance(USDC_Contract, walletAddress), 6)
  );
  const positionsInfo = await fetchPostions();

  await removeLiquidity(
    positionsInfo[positionsInfo.length - 1].positionId,
    DAI_ADDRESS,
    USDC_ADDRESS,
    500,
    DENOMINATOR / 10
  );

  console.log(
    "After balance: ",
    ethers.utils.formatUnits(await getBalance(DAI_Contract, walletAddress), 18),
    " / ",
    ethers.utils.formatUnits(await getBalance(USDC_Contract, walletAddress), 6)
  );
}
main();
