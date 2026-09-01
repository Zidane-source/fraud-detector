from fastapi import FastAPI, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from google import genai
import json
from PIL import Image
import io
import os

app = FastAPI()

# Allow Flutter to talk to this backend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load Gemini
client = genai.Client(api_key=os.environ.get("GEMINI_API_KEY"))

PROMPT = """You are a fraud detection expert specialising in Singapore scams.
You MUST always return ALL fields populated with real data.
Analyse the content and respond ONLY in this exact JSON format with no extra text:

{
  "risk_score": <number 1-10>,
  "verdict": "<LOW RISK|MEDIUM RISK|HIGH RISK|CRITICAL RISK>",
  "summary": "<one sentence summary>",
  "flags": [
    {"severity": "<red|orange|green>", "title": "<title>", "reason": "<explanation>"}
  ],
  "highlighted_phrases": [
    {"phrase": "<exact phrase from message>", "severity": "<red|orange>", "explanation": "<why suspicious>"}
  ],
  "url_parts": [
    {"part": "<url part>", "status": "<safe|danger|warn>", "explanation": "<explanation>"}
  ],
  "next_steps": [
    {"title": "<action title>", "description": "<what to do>"}
  ]
}

IMPORTANT RULES:
- flags must have AT LEAST 3 items always
- highlighted_phrases must have AT LEAST 3 items using EXACT phrases from message
- url_parts only if URL present — split into protocol, domain, path
- next_steps must have AT LEAST 4 Singapore specific steps
- Risk score for messages with SUSPENDED, verify, click link = minimum 8
- Write simple English everyone understands"""
@app.post("/analyse/text")
async def analyse_text(message: str = Form(...)):
    try:
        response = client.models.generate_content(
            model="gemini-3.6-flash",
            contents=PROMPT + f"\n\nContent to analyse:\n{message}"
        )
        raw = response.text.strip()
        clean = raw.replace("```json", "").replace("```", "").strip()
        result = json.loads(clean)
        return result
    except Exception as e:
        return {"error": str(e)}

@app.post("/analyse/image")
async def analyse_image(file: UploadFile = File(...)):
    try:
        image_bytes = await file.read()
        image = Image.open(io.BytesIO(image_bytes))
        response = client.models.generate_content(
            model="gemini-3.6-flash",
            contents=[PROMPT + "\n\nAnalyse this screenshot for fraud:", image]
        )
        raw = response.text.strip()
        clean = raw.replace("```json", "").replace("```", "").strip()
        result = json.loads(clean)
        return result
    except Exception as e:
        return {"error": str(e)}

@app.get("/health")
async def health():
    return {"status": "running"}