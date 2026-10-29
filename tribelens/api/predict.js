// TribeLens API: returns the tribe name as plain text.
//
//   GET  /api/predict?img=<base64>        (small images only; Vercel caps URLs at ~14 KB)
//   POST /api/predict                     body = base64 text, JSON {"img":"<base64>"}, or raw image bytes
//
// Base64 can be plain, URL-safe, or a full data:image/...;base64, URL.
// Add ?format=json to get {"tribe":"...","confidence":0.99} instead of plain text.

const fs = require("fs");
const path = require("path");
const tf = require("@tensorflow/tfjs-core");
require("@tensorflow/tfjs-backend-cpu");
const { loadLayersModel } = require("@tensorflow/tfjs-layers");
const sharp = require("sharp");

const MODEL_DIR = path.join(process.cwd(), "model");
let modelPromise;

function loadModel() {
  if (!modelPromise) {
    modelPromise = (async () => {
      const json = JSON.parse(fs.readFileSync(path.join(MODEL_DIR, "model.json"), "utf8"));
      const labels = JSON.parse(fs.readFileSync(path.join(MODEL_DIR, "labels.json"), "utf8"));
      const weightSpecs = [];
      const buffers = [];
      for (const group of json.weightsManifest) {
        weightSpecs.push(...group.weights);
        for (const p of group.paths) buffers.push(fs.readFileSync(path.join(MODEL_DIR, p)));
      }
      const all = Buffer.concat(buffers);
      const weightData = all.buffer.slice(all.byteOffset, all.byteOffset + all.byteLength);
      const model = await loadLayersModel(tf.io.fromMemory({ modelTopology: json.modelTopology, weightSpecs, weightData }));
      return { model, labels };
    })();
    modelPromise.catch(() => { modelPromise = null; });
  }
  return modelPromise;
}

function decodeBase64(raw) {
  let s = String(raw).trim();
  const comma = s.indexOf(",");
  if (s.startsWith("data:") && comma !== -1) s = s.slice(comma + 1);
  s = s.replace(/ /g, "+").replace(/-/g, "+").replace(/_/g, "/").replace(/\s/g, "");
  while (s.length % 4) s += "=";
  return Buffer.from(s, "base64");
}

async function readBody(req) {
  if (req.body !== undefined && req.body !== null && !(typeof req.body === "object" && !Buffer.isBuffer(req.body) && Object.keys(req.body).length === 0)) {
    return req.body;
  }
  const chunks = [];
  for await (const c of req) chunks.push(c);
  return Buffer.concat(chunks);
}

async function getImageBuffer(req) {
  const q = req.query || {};
  if (q.img || q.image) return decodeBase64(q.img || q.image);
  if (req.method !== "POST") return null;
  let body = await readBody(req);
  if (body && typeof body === "object" && !Buffer.isBuffer(body)) {   // parsed JSON
    const v = body.img || body.image;
    return v ? decodeBase64(v) : null;
  }
  const buf = Buffer.isBuffer(body) ? body : Buffer.from(String(body));
  if (!buf.length) return null;
  const head = buf.subarray(0, 12);
  const isImage = (head[0] === 0xff && head[1] === 0xd8) || head.toString("hex", 0, 4) === "89504e47" ||
                  head.toString("ascii", 0, 3) === "GIF" || head.toString("ascii", 8, 12) === "WEBP";
  if (isImage) return buf;
  const text = buf.toString("utf8").trim();
  if (text.startsWith("{")) {
    try { const j = JSON.parse(text); return decodeBase64(j.img || j.image || ""); } catch (_) {}
  }
  if (text.startsWith("img=") || text.startsWith("image=")) {
    return decodeBase64(new URLSearchParams(text).get("img") || new URLSearchParams(text).get("image"));
  }
  return decodeBase64(text);
}

function send(res, status, text, json, wantJson) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Cache-Control", "no-store");
  if (wantJson) {
    res.setHeader("Content-Type", "application/json; charset=utf-8");
    res.statusCode = status;
    return res.end(JSON.stringify(json));
  }
  res.setHeader("Content-Type", "text/plain; charset=utf-8");
  res.statusCode = status;
  res.end(text);
}

module.exports = async (req, res) => {
  const wantJson = String((req.query || {}).format || "").toLowerCase() === "json";
  if (req.method === "OPTIONS") {
    res.setHeader("Access-Control-Allow-Origin", "*");
    res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    res.setHeader("Access-Control-Allow-Headers", "Content-Type");
    res.statusCode = 204;
    return res.end();
  }
  try {
    const buf = await getImageBuffer(req);
    if (!buf || !buf.length) {
      return send(res, 400, "Error: send an image as base64 in ?img= or in the POST body", { error: "missing image" }, wantJson);
    }
    let pixels;
    try {
      pixels = await sharp(buf).removeAlpha().resize(224, 224, { fit: "cover" }).raw().toBuffer();
    } catch (_) {
      return send(res, 400, "Error: invalid image data", { error: "invalid image data" }, wantJson);
    }
    const { model, labels } = await loadModel();
    const input = tf.tidy(() => tf.expandDims(tf.sub(tf.div(tf.cast(tf.tensor3d(new Uint8Array(pixels), [224, 224, 3], "int32"), "float32"), 127.5), 1), 0));
    const output = model.predict(input);
    const probs = await output.data();
    input.dispose(); output.dispose();
    let best = 0;
    for (let i = 1; i < probs.length; i++) if (probs[i] > probs[best]) best = i;
    return send(res, 200, labels[best], { tribe: labels[best], confidence: Number(probs[best].toFixed(4)) }, wantJson);
  } catch (e) {
    return send(res, 500, "Error: " + e.message, { error: e.message }, wantJson);
  }
};
