(() => {
  "use strict";

  const ASSETS = [
    "rvtt-ui.css.gz.b64",
    "rvtt-ui.js.gz.b64.1",
    "rvtt-ui.js.gz.b64.2",
    "rvtt-ui.js.gz.b64.3",
    "rvtt-ui.js.gz.b64.4",
  ];

  const REMOTE_ROOT =
    "https://raw.githubusercontent.com/Kaetaeru/RVTT/planning/rvtt-remake/docs/remake/user-guides/html/assets/";

  async function readText(assetName) {
    const relativeUrl = `assets/${assetName}`;

    try {
      const response = await fetch(relativeUrl, { cache: "no-store" });
      if (response.ok) {
        return (await response.text()).replace(/\s+/g, "");
      }
    } catch (_) {
      // file:// viewers commonly block relative fetch; use the public branch copy below.
    }

    const response = await fetch(`${REMOTE_ROOT}${assetName}`, { cache: "no-store" });
    if (!response.ok) {
      throw new Error(`RVTT UI asset load failed: ${assetName} (${response.status})`);
    }
    return (await response.text()).replace(/\s+/g, "");
  }

  async function ungzipBase64(base64Text) {
    if (typeof DecompressionStream !== "function") {
      throw new Error("This browser does not support DecompressionStream('gzip').");
    }

    const binary = atob(base64Text);
    const bytes = new Uint8Array(binary.length);
    for (let index = 0; index < binary.length; index += 1) {
      bytes[index] = binary.charCodeAt(index);
    }

    const decompressed = new Blob([bytes])
      .stream()
      .pipeThrough(new DecompressionStream("gzip"));
    return new Response(decompressed).text();
  }

  async function boot() {
    const [cssPayload, ...appPayloadParts] = await Promise.all(
      ASSETS.map(readText),
    );

    const [cssText, appText] = await Promise.all([
      ungzipBase64(cssPayload),
      ungzipBase64(appPayloadParts.join("")),
    ]);

    const style = document.createElement("style");
    style.dataset.rvttGuide = "high-fidelity";
    style.textContent = cssText;
    document.head.appendChild(style);

    (0, eval)(`${appText}\n//# sourceURL=rvtt-high-fidelity-app.js`);

    if (!globalThis.__RVTT_HIGH_FIDELITY_GUIDE__) {
      throw new Error("RVTT high-fidelity renderer registry was not created.");
    }

    document.body.classList.remove("rvtt-error");
    document.body.classList.add("rvtt-ready");
  }

  boot().catch((error) => {
    console.error("RVTT high-fidelity guide failed to start", error);
    document.body.classList.remove("rvtt-ready");
    document.body.classList.add("rvtt-error");
  });
})();
