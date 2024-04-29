import "./Swap.scss";
import { Modal } from "antd";
import { Slider } from "@mui/material";
import useSwapType from "./hooks/useSwapType";
import useTokens from "./hooks/useTokens";
import { useContext, useEffect } from "react";
import { ChainContext } from "../../Contexts/ChainContext";
import useModal from "./hooks/useModal";
import { useParams } from "react-router-dom";
import useHandleTx from "./hooks/useHandleTX";
import useEstimate from "./hooks/useEstimate";

const Swap = () => {
  const { swapType, setSwapType } = useSwapType();

  const { activeChain } = useContext(ChainContext);

  const { poolPair } = useParams();
  const [
    pairAddress,
    tokenASymbol,
    tokenBSymbol,
    tokenA_Amount,
    tokenB_Amount,
  ] = poolPair.split("&");

  const { handleApprove } = useHandleTx();

  const {
    estimatedTokenXAmount,
    estimatedTokenYAmount,
    estimatedGas,
    estimateGas,
    estimateTokenAmount,
  } = useEstimate();

  const {
    pair_Percent,
    getToken,
    handleChangeToken,
    onPairPercentChange,
    getTokenList,
    loadToken,
  } = useTokens(activeChain.chainID);

  const { isOpen, closeModal, openModal, changeToken } = useModal();

  useEffect(() => {
    loadToken({ tokenASymbol, tokenBSymbol });
  }, []);

  return (
    <div className="SwapPage">
      <div className="SwapContainer">
        <div className="SwapTypeContainer">
          <span
            className={`SwapType ${swapType === "a/b-x/y" ? "SwapTypeActive" : ""
              }`}
            onClick={() => setSwapType("a/b-x/y")}
          >
            a/b-x/y
          </span>
          <span
            className={`SwapType ${swapType === "e-x/y" ? "SwapTypeActive" : ""
              }`}
            onClick={() => setSwapType("e-x/y")}
          >
            e-x/y
          </span>
        </div>
        <div className="SwapBoxContainer">
          <div className="SwapBoxTitle">
            <span>LP Swap</span>
          </div>
          <div className="SwapBoxInputContainer">
            {swapType === "a/b-x/y" && (
              <div className="SwapBoxInput">
                <div className="SwapBoxInputTitle">
                  <span>Swap Amount</span>
                </div>
                <div className="SwapBoxInputLabelContainer">
                  <div
                    className={`SwapBoxInputLabel ${getToken("tokenA").img
                      ? ""
                      : "SwapBoxInputLabelNotSelected"
                      }`}
                    onClick={() => { }}
                  >
                    {getToken("tokenA").img && (
                      <img src={getToken("tokenA").img} alt="icon" />
                    )}
                    {getToken("tokenA").symbol}
                  </div>
                  <div
                    className={`SwapBoxInputLabel ${getToken("tokenB").img
                      ? ""
                      : "SwapBoxInputLabelNotSelected"
                      }`}
                    onClick={() => { }}
                  >
                    {getToken("tokenB").img && (
                      <img src={getToken("tokenB").img} alt="icon" />
                    )}
                    {getToken("tokenB").symbol}
                  </div>
                </div>
                <div className="SwapBoxInputSliderContainer">
                  <div className="SwapBoxInputSliderValue">
                    <span>{pair_Percent}%</span>
                  </div>
                  <Slider
                    value={pair_Percent}
                    onChange={(e, newValue) => {
                      onPairPercentChange(newValue);
                      estimateTokenAmount(
                        tokenA_Amount,
                        tokenB_Amount,
                        getToken("tokenX").address,
                        getToken("tokenY").address,
                        pair_Percent
                      );
                      estimateGas(
                        getToken("tokenA").address,
                        getToken("tokenB").address,
                        getToken("tokenX").address,
                        getToken("tokenY").address,
                        swapType
                      );
                    }}
                    className="SwapBoxInputSlider"
                    defaultValue={0}
                  />
                  <div className="SwapBoxInputSliderValueMarks">
                    <span
                      onClick={() => {
                        onPairPercentChange(25);
                        estimateTokenAmount(
                          tokenA_Amount,
                          tokenB_Amount,
                          getToken("tokenX").address,
                          getToken("tokenY").address,
                          pair_Percent
                        );
                        estimateGas(
                          getToken("tokenA").address,
                          getToken("tokenB").address,
                          getToken("tokenX").address,
                          getToken("tokenY").address,
                          swapType
                        );
                      }}
                    >
                      25%
                    </span>
                    <span
                      onClick={() => {
                        onPairPercentChange(50);
                        estimateTokenAmount(
                          tokenA_Amount,
                          tokenB_Amount,
                          getToken("tokenX").address,
                          getToken("tokenY").address,
                          pair_Percent
                        );
                        estimateGas(
                          getToken("tokenA").address,
                          getToken("tokenB").address,
                          getToken("tokenX").address,
                          getToken("tokenY").address,
                          swapType
                        );
                      }}
                    >
                      50%
                    </span>
                    <span
                      onClick={() => {
                        onPairPercentChange(75);
                        estimateTokenAmount(
                          tokenA_Amount,
                          tokenB_Amount,
                          getToken("tokenX").address,
                          getToken("tokenY").address,
                          pair_Percent
                        );
                        estimateGas(
                          getToken("tokenA").address,
                          getToken("tokenB").address,
                          getToken("tokenX").address,
                          getToken("tokenY").address,
                          swapType
                        );
                      }}
                    >
                      75%
                    </span>
                    <span
                      onClick={() => {
                        onPairPercentChange(100);
                        estimateTokenAmount(
                          tokenA_Amount,
                          tokenB_Amount,
                          getToken("tokenX").address,
                          getToken("tokenY").address,
                          pair_Percent
                        );
                        estimateGas(
                          getToken("tokenA").address,
                          getToken("tokenB").address,
                          getToken("tokenX").address,
                          getToken("tokenY").address,
                          swapType
                        );
                      }}
                    >
                      Max
                    </span>
                  </div>
                </div>
              </div>
            )}

            <div className="seperatorArrContainer">
              <span className="seperatorArr">&#129123;</span>
            </div>
            <div className="SwapBoxOutput">
              <span className="SwapBoxOutputTitle">Estimated Pool</span>
              <div className="SwapBoxOutputContainer">
                <span>{estimatedTokenXAmount || "-"}</span>
                <div
                  onClick={() => {
                    openModal("tokenX");
                  }}
                  className="SwapBoxOutputLabel"
                >
                  {getToken("tokenX").img && (
                    <img src={getToken("tokenX").img} alt="icon" />
                  )}
                  {getToken("tokenX").symbol}
                  <span>&#9660;</span>
                </div>
              </div>
              <div className="SwapBoxOutputContainer">
                <span>{estimatedTokenYAmount || "-"}</span>
                <div
                  onClick={() => {
                    openModal("tokenY");
                  }}
                  className="SwapBoxOutputLabel"
                >
                  {getToken("tokenY").img && (
                    <img src={getToken("tokenY").img} alt="icon" />
                  )}
                  {getToken("tokenY").symbol}
                  <span>&#9660;</span>
                </div>
              </div>
              <div className="EstimatedGas">
                <span>Estimated Gas</span>
                <span>{estimatedGas || "-"}</span>
              </div>
            </div>
          </div>

          <button
            className="SwapBoxButton"
            disabled={
              estimatedTokenXAmount === undefined ||
              estimatedTokenYAmount === undefined
            }
            onClick={() => {
              handleApprove(
                getToken("tokenA").address,
                getToken("tokenB").address,
                pair_Percent,
                getToken("tokenX").address,
                getToken("tokenY").address,
                pairAddress
              );
            }}
          >
            Approve
          </button>
        </div>
      </div>
      <Modal
        open={isOpen}
        title="Select a token"
        footer={null}
        width={300}
        onCancel={() => {
          closeModal();
        }}
      >
        <div className="SwapModal">
          {getTokenList().map((token, index) => {
            return (
              <div
                key={index}
                onClick={() => {
                  handleChangeToken(index, changeToken);
                  closeModal();
                }}
                className="SwapModalItem"
              >
                {token.img && <img src={token.img} alt="icon" />}
                {token.name}
              </div>
            );
          })}
        </div>
      </Modal>
    </div>
  );
};

export default Swap;
