const CryptoJS = require("crypto-js");

module.exports = async function (req) {
  const {
    configuration: { HMAC_KEY },
    args: { message },
  } = req;

  return {
    raw: {
      runtime: "node-bt",
      digest: CryptoJS.HmacSHA256(message, HMAC_KEY).toString(),
    },
  };
};
