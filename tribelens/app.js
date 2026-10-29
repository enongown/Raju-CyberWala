// TribeLens
// Two ways to use it:
//  1. Upload a photo with the picker.
//  2. Put a base64 image in the URL and the page shows only the tribe name:
//       https://your-site.vercel.app/#img=<base64>    (recommended, no size limit from the server)
//       https://your-site.vercel.app/?img=<base64>    (works for small images; servers cap URL length)
//     The value can be plain base64, URL-safe base64, or a full data:image/...;base64, URL.

let model, labels;
const statusEl = document.getElementById("status");
const resultEl = document.getElementById("result");
const preview = document.getElementById("preview");

function getUrlImage() {
  const hash = new URLSearchParams(location.hash.replace(/^#/, ""));
  const query = new URLSearchParams(location.search);
  let raw = hash.get("img") || query.get("img") || hash.get("image") || query.get("image");
  if (!raw) return null;
  raw = raw.trim().replace(/ /g, "+");            // '+' turns into a space in query strings
  if (raw.startsWith("data:")) return raw;
  raw = raw.replace(/-/g, "+").replace(/_/g, "/"); // URL-safe base64
  while (raw.length % 4) raw += "=";
  // Guess the type from the first bytes; browsers decode anyway.
  const type = raw.startsWith("iVBOR") ? "png" : raw.startsWith("R0lG") ? "gif" : raw.startsWith("UklG") ? "webp" : "jpeg";
  return `data:image/${type};base64,${raw}`;
}

function loadImage(src) {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => resolve(img);
    img.onerror = () => reject(new Error("invalid image data"));
    img.src = src;
  });
}

// Center-crop to a square and resize to 224x224 (same as the Python script).
function toTensor(img) {
  const size = 224;
  const canvas = document.createElement("canvas");
  canvas.width = size; canvas.height = size;
  const ctx = canvas.getContext("2d");
  const s = Math.min(img.naturalWidth, img.naturalHeight);
  const sx = (img.naturalWidth - s) / 2, sy = (img.naturalHeight - s) / 2;
  ctx.drawImage(img, sx, sy, s, s, 0, 0, size, size);
  return tf.tidy(() => tf.browser.fromPixels(canvas).toFloat().div(127.5).sub(1).expandDims(0));
}

async function classify(img) {
  const input = toTensor(img);
  const probs = await model.predict(input).data();
  input.dispose();
  let best = 0;
  for (let i = 1; i < probs.length; i++) if (probs[i] > probs[best]) best = i;
  return { tribe: labels[best], confidence: probs[best] };
}

// URL mode: replace the page with just the tribe name.
function showPlain(text) {
  document.body.innerHTML = "";
  const pre = document.createElement("pre");
  pre.id = "tribe";
  pre.textContent = text;
  pre.style.cssText = "margin:0;padding:16px;font:20px system-ui,sans-serif;color:inherit;";
  document.body.style.cssText = "display:block;padding:0;";
  document.body.appendChild(pre);
  document.title = text;
}

async function runFromUrl() {
  const src = getUrlImage();
  if (!src) return false;
  document.body.innerHTML = "";
  try {
    const img = await loadImage(src);
    const { tribe } = await classify(img);
    showPlain(tribe);
  } catch (e) {
    showPlain("Error: " + e.message);
  }
  return true;
}

async function init() {
  try {
    [model, labels] = await Promise.all([
      tf.loadLayersModel("model/model.json"),
      fetch("model/labels.json").then(r => r.json()),
    ]);
  } catch (e) {
    if (getUrlImage()) showPlain("Error: could not load the model");
    else statusEl.textContent = "Could not load the model: " + e.message;
    return;
  }
  if (await runFromUrl()) return;
  statusEl.textContent = "Ready. Choose an image.";
}

document.getElementById("file").addEventListener("change", async e => {
  const file = e.target.files[0];
  if (!file || !model) return;
  resultEl.textContent = "";
  statusEl.textContent = "Analysing...";
  preview.src = URL.createObjectURL(file);
  preview.style.display = "block";
  const img = await loadImage(preview.src);
  const { tribe, confidence } = await classify(img);
  resultEl.textContent = tribe;
  statusEl.textContent = `Confidence: ${(confidence * 100).toFixed(1)}%`;
});

window.addEventListener("hashchange", () => model && runFromUrl());

init();
