const ethers = require("ethers");
const dotenv = require("dotenv");
dotenv.config();

let provider, wallet;
async function init() {
  provider = new ethers.providers.JsonRpcProvider("http://127.0.0.1:8545");
  wallet = new ethers.Wallet(
    "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
    provider
  );
}

async function main() {
  init();
  console.log(await wallet.getAddress());
  console.log((await wallet.getBalance()).toString());
}
main();
