const JSZip = require("jszip");
const zip = new JSZip();

module.exports = async function (req) {
  const {
    configuration: {
      FILENAME
    },
    args: {
      contents
    }
  } = req;

  zip.file(FILENAME, contents);
  const base64 = await zip.generateAsync({ type: 'base64' });

  return {
    raw: {
      href: `data:application/zip;base64,${base64}`
    }
  }
}
