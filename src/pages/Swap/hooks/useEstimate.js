import { useContext, useState } from "react";
import { useAccount, useEstimateGas } from "wagmi";
import { SignerContext } from "../../../Contexts/SignerContext";
import ERC20ABI from "../../../abi/ERC20ABI.json";
import { abi as LPAggregatorABI } from "../../../abi/LPAggregator.json";
import { maxUint256, parseGwei } from "viem";
import { ethers } from "ethers";
import axios from "axios";

const useEstimate = () => {
  const [estimatedGas, setEstimatedGas] = useState(undefined);
  const [estimatedTokenXAmount, setEstimatedTokenXAmount] = useState(undefined);
  const [estimatedTokenYAmount, setEstimatedTokenYAmount] = useState(undefined);
  const LP_AGGREGATOR_ADDRESS = import.meta.env.VITE_LP_AGGREGATOR_ADDRESS;
  const { address } = useAccount();

  const { signer } = useContext(SignerContext);

  const estimateGas = (
    tokenAAddress,
    tokenBAddress,
    tokenXAddress,
    tokenYAddress
  ) => {
    if (tokenAAddress && tokenBAddress && tokenXAddress && tokenYAddress) {
      const gas = "~0.3CFX";
      setEstimatedGas(gas);
    } else {
      setEstimatedGas(undefined);
      return;
    }
  };

  const estimateTokenAmount = async (
    tokenA,
    tokenB,
    tokenA_Amount,
    tokenB_Amount,
    tokenX,
    tokenY,
    removePercent,
    pairAddress
  ) => {
    console.log(removePercent);
    if (removePercent === 0) return;
    if (!tokenX || !tokenY) {
      setEstimatedTokenXAmount(undefined);
      setEstimatedTokenYAmount(undefined);
      return;
    }
    if (tokenA_Amount === undefined && tokenB_Amount === undefined) {
      setEstimatedTokenXAmount(undefined);
      setEstimatedTokenYAmount(undefined);
      return;
    } else {
      const allowanceRespond = await axios.get(
        import.meta.env.VITE_API_ENDPOINT + "/getAllowance",
        {
          params: {
            token: pairAddress,
            owner: address,
          },
        }
      );
      const isAllowed = allowanceRespond.data.allowance !== "0";

      console.log("isAllowed:", isAllowed);

      if (!isAllowed) {
        const pairContract = new ethers.Contract(pairAddress, ERC20ABI, signer);
        const tx = await pairContract.approve(
          LP_AGGREGATOR_ADDRESS,
          maxUint256
        );
        console.log("tx:", await tx.wait());
      }
      const txParams = await axios.get(
        import.meta.env.VITE_API_ENDPOINT + "/getSwapParams",
        {
          params: {
            tokenA,
            tokenB,
            removePercent: removePercent * 100,
            tokenX,
            tokenY,
            sender: address,
            isEncoded: false,
          },
        }
      );
      const swapContract = new ethers.Contract(
        LP_AGGREGATOR_ADDRESS,
        LPAggregatorABI,
        signer
      );

      console.log("txParams:", txParams.data.params.removeParams);
      console.log("txParams:", txParams.data.params.addParams);
      const swapTx = await swapContract.callStatic.swapLP(
        txParams.data.params.removeParams,
        txParams.data.params.addParams,
        { gasPrice: parseGwei("30"), gasLimit: 2_000_000 }
      );
      console.log("swapTx:", swapTx);
      console.log();
      console.log(swapTx.amountB.toString());

      setEstimatedTokenXAmount(
        ethers.utils.formatUnits(swapTx.amountA.toString(), 18).slice(0, 10)
      );
      setEstimatedTokenYAmount(
        ethers.utils.formatUnits(swapTx.amountB.toString(), 18).slice(0, 10)
      );
    }
  };

  return {
    estimatedTokenXAmount,
    estimatedTokenYAmount,
    estimateTokenAmount,
  };
};

export default useEstimate;
