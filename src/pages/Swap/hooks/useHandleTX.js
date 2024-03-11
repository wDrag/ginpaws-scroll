import { useAccount, useSendTransaction } from "wagmi";
import axios from "axios";
import { parseEther, parseGwei } from "viem";

const useHandleTx = () => {
  const { sendTransactionAsync, onSuccess } = useSendTransaction();
  const { address } = useAccount();
  const getSwapParams = async (
    tokenA,
    tokenB,
    removePercent,
    tokenX,
    tokenY
  ) => {
    try {
      const params = await axios.get(
        import.meta.env.VITE_API_ENDPOINT + "/getSwapParams",
        {
          params: {
            tokenA: tokenA,
            tokenB: tokenB,
            removePercent: removePercent * 100,
            tokenX: tokenX,
            tokenY: tokenY,
            sender: address,
          },
        }
      );
      return params.data.params;
    } catch (error) {
      console.error("Error while getting swap params:", error);
    }
  };

  const handleSendTransaction = async (tx) => {
    try {
      console.log(tx, "tx");
      const result = await sendTransactionAsync({
        to: tx.to,
        data: tx.calldata,
        value: parseEther("0"),
        gas: parseGwei("0.005"),
      });
      console.log(result, "send tx result");
      return result;
    } catch (error) {
      console.error("Error while sending transaction:", error);
    }
  };

  const handleApprove = async (
    tokenA,
    tokenB,
    removePercent,
    tokenX,
    tokenY,
    pairAddress
  ) => {
    if (!address) {
      console.error("No address found");
      return;
    }
    if (!tokenA || !tokenB || !tokenX || !tokenY) {
      console.error("Token addresses not found");
      return;
    }
    if (!removePercent) {
      console.error("Remove percent not set");
      return;
    }
    try {
      const tx = await getSwapParams(
        tokenA,
        tokenB,
        removePercent,
        tokenX,
        tokenY
      );
      console.log(tx, "approve tx");

      const tokenA_ApproveData = await axios.get(
        import.meta.env.VITE_API_ENDPOINT + "/approve"
      );

      console.log("tokenA_ApproveData:", tokenA_ApproveData, "approve data A");

      await handleSendTransaction({
        to: pairAddress,
        data: tokenA_ApproveData.data.calldata,
      });

      const result = await handleSendTransaction(tx);
      console.log(result, "approve result");
      return result;
    } catch (error) {
      console.error("Error while approving:", error);
    }
  };
  return { getSwapParams, handleSendTransaction, handleApprove };
};

export default useHandleTx;
