const { sha256 } = require("js-sha256");

// node22 uses a different code contract than node-bt:
//  - the handler receives an `event` wrapper; the invoke body is at `event.req` (so the
//    invoke `args` are `event.req.args`) and configuration at `event.configuration`.
//    (node-bt receives `req` directly, with `req.args` and `req.configuration`.)
//  - the response is wrapped in `res` with a `body` and `statusCode` (node-bt returns `raw`).
module.exports = async function (event) {
  const {
    req: {
      args: { message },
    },
    configuration: { HMAC_KEY },
  } = event;

  return {
    res: {
      body: {
        runtime: "node22",
        digest: sha256.hmac(HMAC_KEY, message),
      },
      statusCode: 200,
    },
  };
};
