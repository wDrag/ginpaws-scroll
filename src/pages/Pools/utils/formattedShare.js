const formattedShare = (unformattedShare) => {
  if (unformattedShare === 0) {
    return "0";
  }
  if (unformattedShare < 0.01) {
    return "<0.01";
  }
  console.log("unformattedShare", unformattedShare);
  return unformattedShare.toFixed(2);
};

export default formattedShare;
