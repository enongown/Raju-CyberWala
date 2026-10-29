# TribeLens

Identifies the tribe (Adi, Singpho or Khamti) from a photo of women's traditional attire, using a Google Teachable Machine image model.

## Web app (Vercel)

The page (`index.html`, `app.js`, `model/`) runs the model in the visitor's browser with TensorFlow.js. Opening `/#img=<base64>` shows only the tribe name.

Deploy: import this repo in Vercel, keep the Framework Preset as **Other**, leave the build command empty, and click Deploy.

Run locally: `python -m http.server 8000` in this folder, then open http://localhost:8000.

## API

`/api/predict` returns just the tribe name as plain text (for example `Singpho`).

- **POST (recommended, any image size):** send the base64 string as the request body, or JSON `{"img": "<base64>"}`, or the raw image file.
- **GET (small images only):** `/api/predict?img=<base64>`. Vercel rejects URLs over about 14 KB, so use POST for normal photos.
- Base64 can be plain, URL-safe, or a full `data:image/...;base64,` string.
- Add `?format=json` to get `{"tribe": "Singpho", "confidence": 1}`.

Examples (PowerShell):

```
$b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes("image.png"))
Invoke-RestMethod -Method Post -Uri https://your-site.vercel.app/api/predict -Body $b64
```

```
curl -X POST --data-binary @image.png https://your-site.vercel.app/api/predict
```
## Python script

Uses the original `keras_model.h5` (needs Python 3.10 and TensorFlow 2.12):

```
py -3.10 -m venv .venv
.venv\Scripts\python -m pip install -r requirements.txt
.venv\Scripts\python predict.py image.png
```

Pass a folder instead of an image to classify every picture in it.

