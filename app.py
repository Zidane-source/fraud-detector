import streamlit as st
import google.generativeai as genai
import json
import time
from PIL import Image
import io

# ─── PAGE CONFIG ──────────────────────────────────────
st.set_page_config(
    page_title="Singapore Fraud Detector",
    page_icon="🛡️",
    layout="centered",
    initial_sidebar_state="collapsed"
)

# ─── CONFIGURE GEMINI ─────────────────────────────────
genai.configure(api_key=st.secrets["GEMINI_API_KEY"])
model = genai.GenerativeModel("gemini-3.6-flash")

# ─── STYLING ──────────────────────────────────────────
st.markdown("""
<style>
    .stApp { background-color: #F0F7F1; }
    #MainMenu {visibility: hidden;}
    footer {visibility: hidden;}
    header {visibility: hidden;}

    .stButton > button {
        background-color: #2E7D32;
        color: white;
        border: none;
        border-radius: 10px;
        padding: 12px;
        font-size: 14px;
        font-weight: 600;
        width: 100%;
    }
    .stButton > button:hover {
        background-color: #1B5E20;
        color: white;
    }
    .stTextArea > div > div > textarea {
        border: 1px solid #C8E6C9;
        border-radius: 10px;
        background-color: #FAFFF9;
        color: #1a1a1a;
    }
    .fraud-card {
        background: white;
        border: 1px solid #C8E6C9;
        border-radius: 16px;
        padding: 20px;
        margin-bottom: 16px;
    }

    /* Fix expander text visibility */
    .streamlit-expanderHeader {
        background-color: #1a1a1a !important;
        border-radius: 8px !important;
        color: white !important;
        font-weight: 500 !important;
    }
    .streamlit-expanderHeader p {
        color: white !important;
    }
    .streamlit-expanderContent {
        background-color: #f9f9f9;
        border-radius: 0 0 8px 8px;
    }

    /* Magnifying glass animation */
    @keyframes hover-float {
        0%   { transform: translateY(0px) rotate(-10deg); }
        50%  { transform: translateY(-6px) rotate(10deg); }
        100% { transform: translateY(0px) rotate(-10deg); }
    }
    .magnify-anim {
        display: inline-block;
        animation: hover-float 1.5s ease-in-out infinite;
        font-size: 36px;
    }
</style>
""", unsafe_allow_html=True)

# ─── SESSION STATE ────────────────────────────────────
if 'screen' not in st.session_state:
    st.session_state.screen = 1
if 'analysis_result' not in st.session_state:
    st.session_state.analysis_result = None
if 'input_text' not in st.session_state:
    st.session_state.input_text = ""
if 'uploaded_image' not in st.session_state:
    st.session_state.uploaded_image = None

# ─── HEADER — Fix 1 ───────────────────────────────────
st.markdown("""
<div class="fraud-card" style="text-align:center">
    <div style="font-size:28px;font-weight:800;color:#1B5E20;line-height:1.2">
        🛡️ Singapore Fraud Detector
    </div>
    <div style="font-size:13px;font-weight:500;color:#2E7D32;margin-top:4px">
        Powered by AI · Protect yourself from scams
    </div>
</div>
""", unsafe_allow_html=True)

# ─── PROGRESS BAR — Fix 2 & 3 ────────────────────────
steps = ["📤 Upload", "🔍 Analysing", "📊 Results", "✅ Next Steps"]
cols = st.columns(4)
for i, (col, step) in enumerate(zip(cols, steps)):
    with col:
        is_active = (i + 1 == st.session_state.screen)
        is_done = (i + 1 < st.session_state.screen)
        if is_active:
            # Active — popped out, brighter box
            st.markdown(f"""
            <div style='text-align:center;font-size:13px;font-weight:700;
            color:#ffffff;background:#1B5E20;border-radius:8px;
            padding:8px 4px;
            box-shadow:0 4px 12px rgba(27,94,32,0.4);
            transform:scale(1.08);
            transition:all 0.3s ease'>
                {step}
            </div>
            """, unsafe_allow_html=True)
        elif is_done:
            # Done — normal dark box, slightly faded
            st.markdown(f"""
            <div style='text-align:center;font-size:12px;font-weight:600;
            color:#A5D6A7;background:#1a1a1a;border-radius:8px;
            padding:6px 4px;transition:all 0.3s ease'>
                {step}
            </div>
            """, unsafe_allow_html=True)
        else:
            # Pending — dark box, greyed out
            st.markdown(f"""
            <div style='text-align:center;font-size:12px;font-weight:600;
            color:#555;background:#1a1a1a;border-radius:8px;
            padding:6px 4px;transition:all 0.3s ease'>
                {step}
            </div>
            """, unsafe_allow_html=True)

st.markdown("<hr style='border:1px solid #C8E6C9;margin:14px 0'>", unsafe_allow_html=True)

# ─── SCREEN 1 — UPLOAD ────────────────────────────────
if st.session_state.screen == 1:
    # Fix 4 — dark black centered title, Fix 5 — removed subtitle
    st.markdown("""
    <div class='fraud-card'>
        <h3 style='color:#1a1a1a;font-weight:700;text-align:center;margin-bottom:16px'>
            Upload or paste suspicious content
        </h3>
    """, unsafe_allow_html=True)

    uploaded_file = st.file_uploader(
        "Upload screenshot",
        type=["png", "jpg", "jpeg"],
        label_visibility="collapsed"
    )

    st.markdown("<div style='text-align:center;color:#888;font-size:13px;margin:8px 0'>— or paste message / link —</div>", unsafe_allow_html=True)

    text_input = st.text_area(
        "Paste suspicious message or link",
        placeholder="e.g. 'Your DBS account has been suspended. Click: dbs-secure-login.com/verify'",
        height=100,
        label_visibility="collapsed"
    )

    if st.button("Analyse for fraud →"):
        if uploaded_file is None and not text_input.strip():
            st.error("Please upload a screenshot or paste a message first.")
        else:
            st.session_state.uploaded_image = uploaded_file
            st.session_state.input_text = text_input
            st.session_state.screen = 2
            st.rerun()

    st.markdown("</div>", unsafe_allow_html=True)

# ─── SCREEN 2 — ANALYSING ─────────────────────────────
elif st.session_state.screen == 2:
    # Fix 6 — animated magnifier, dark black text
    st.markdown("""
    <div class='fraud-card' style='text-align:center'>
        <div class='magnify-anim'>🔍</div>
        <h3 style='color:#1a1a1a;font-weight:700;margin:8px 0 4px'>Analysing for fraud...</h3>
        <p style='color:#444;font-size:13px'>Our AI is scanning your content</p>
    </div>
    """, unsafe_allow_html=True)

    progress = st.progress(0)
    status = st.empty()

    checks = [
        "Checking URL structure...",
        "Scanning for urgency language...",
        "Detecting impersonation patterns...",
        "Calculating risk score...",
        "Generating recommendations..."
    ]

    for i, check in enumerate(checks):
        status.markdown(f"<p style='color:#2E7D32;font-size:13px;text-align:center'>⟳ {check}</p>",
                       unsafe_allow_html=True)
        progress.progress((i + 1) * 20)
        time.sleep(0.6)

    prompt = """You are a fraud detection expert specialising in Singapore scams.
Analyse the content and respond ONLY in this exact JSON format with no extra text outside the JSON:

{
  "risk_score": <number 1-10>,
  "verdict": "<LOW RISK|MEDIUM RISK|HIGH RISK|CRITICAL RISK>",
  "summary": "<one sentence summary of why this is or is not fraud>",
  "flags": [
    {"severity": "<red|orange|green>", "title": "<flag title>", "reason": "<explanation>"}
  ],
  "highlighted_phrases": [
    {"phrase": "<exact phrase from message>", "severity": "<red|orange>", "explanation": "<why suspicious in simple English>"}
  ],
  "url_parts": [
    {"part": "<url part e.g. https://>", "status": "<safe|danger|warn>", "explanation": "<explanation>"}
  ],
  "next_steps": [
    {"title": "<action title>", "description": "<what to do in simple English>"}
  ]
}

Important rules:
- highlighted_phrases must use EXACT phrases found in the message
- url_parts should only be included if a URL is present
- next_steps should be specific to Singapore e.g. mention ScamShield, SPF, MAS
- Write all explanations in simple English that anyone can understand
- Risk score 1-3 is low, 4-6 is medium, 7-8 is high, 9-10 is critical"""

    try:
        if st.session_state.uploaded_image is not None:
            image_bytes = st.session_state.uploaded_image.read()
            image = Image.open(io.BytesIO(image_bytes))
            response = model.generate_content([
                prompt + "\n\nAnalyse this screenshot for fraud:",
                image
            ])
        else:
            response = model.generate_content(
                prompt + f"\n\nContent to analyse:\n{st.session_state.input_text}"
            )

        raw = response.text.strip()
        clean = raw.replace("```json", "").replace("```", "").strip()
        result = json.loads(clean)
        st.session_state.analysis_result = result
        st.session_state.screen = 3
        st.rerun()

    except Exception as e:
        st.error(f"Analysis failed. Please try again. Error: {str(e)}")
        if st.button("← Go back"):
            st.session_state.screen = 1
            st.rerun()

# ─── SCREEN 3 — RESULTS ───────────────────────────────
elif st.session_state.screen == 3:
    result = st.session_state.analysis_result

    score = result.get("risk_score", 5)
    verdict = result.get("verdict", "MEDIUM RISK")
    color = "#4CAF50" if score <= 3 else "#FF9800" if score <= 6 else "#ef5350"

    # Risk score card
    st.markdown(f"""
    <div class='fraud-card' style='text-align:center'>
        <h3 style='color:#1a1a1a;margin-bottom:12px;font-weight:700'>Risk Assessment</h3>
        <div style='width:90px;height:90px;border-radius:50%;border:5px solid {color};
        display:flex;flex-direction:column;align-items:center;
        justify-content:center;margin:0 auto 12px'>
            <div style='font-size:30px;font-weight:700;color:{color};line-height:1'>{score}</div>
            <div style='font-size:11px;color:{color}'>/10</div>
        </div>
        <div style='background:#FFEBEE;color:#C62828;padding:6px 16px;
        border-radius:20px;display:inline-block;
        font-weight:600;font-size:13px'>⚠️ {verdict}</div>
        <p style='color:#444;font-size:12px;margin-top:10px'>
        {result.get("summary","")}</p>
    </div>
    """, unsafe_allow_html=True)

    # Fix 7 & 8 — dark black fonts for flags
    st.markdown("<div class='fraud-card'>", unsafe_allow_html=True)
    st.markdown("<p style='color:#1a1a1a;font-weight:700;font-size:16px;margin-bottom:8px'>Why it's suspicious</p>", unsafe_allow_html=True)
    for flag in result.get("flags", []):
        dot_color = "#ef5350" if flag["severity"] == "red" else \
                    "#FF9800" if flag["severity"] == "orange" else "#4CAF50"
        st.markdown(f"""
        <div style='display:flex;gap:8px;padding:8px 0;border-bottom:1px solid #F1F8E9'>
            <div style='width:10px;height:10px;border-radius:50%;background:{dot_color};
            flex-shrink:0;margin-top:5px'></div>
            <div>
                <div style='font-size:14px;font-weight:600;color:#1a1a1a'>{flag["title"]}</div>
                <div style='font-size:13px;color:#333;margin-top:2px'>{flag["reason"]}</div>
            </div>
        </div>
        """, unsafe_allow_html=True)
    st.markdown("</div>", unsafe_allow_html=True)

    # Fix 9, 10, 11 — message breakdown
    phrases = result.get("highlighted_phrases", [])
    if phrases and st.session_state.input_text:
        st.markdown("<div class='fraud-card'>", unsafe_allow_html=True)

        # Fix 9 — dark black title
        st.markdown("<p style='color:#1a1a1a;font-weight:700;font-size:16px;margin-bottom:8px'>Suspicious message breakdown</p>", unsafe_allow_html=True)

        # Fix 10 — full text with highlights
        highlighted_text = st.session_state.input_text
        for phrase in phrases:
            p = phrase["phrase"]
            sev = phrase["severity"]
            bg = "#FFCDD2" if sev == "red" else "#FFE0B2"
            tc = "#C62828" if sev == "red" else "#E65100"
            highlighted_text = highlighted_text.replace(
                p,
                f'<span style="background:{bg};color:{tc};padding:2px 5px;'
                f'border-radius:4px;font-weight:600">{p}</span>'
            )

        st.markdown(f"""
        <div style='background:#FFF8F8;border:1px solid #FFCDD2;
        border-radius:10px;padding:14px;font-size:14px;line-height:2;
        color:#1a1a1a;margin-bottom:12px'>
        {highlighted_text}</div>
        """, unsafe_allow_html=True)

        # Fix 11 — instruction BELOW with finger pointing down
        st.markdown("""
        <div style='background:#E8F5E9;border:1px solid #C8E6C9;border-radius:8px;
        padding:7px 10px;font-size:12px;color:#2E7D32;margin-bottom:10px;text-align:center'>
        👇 Tap highlighted words to learn why they are suspicious</div>
        """, unsafe_allow_html=True)

        # Fix 12 — dark black box expanders
        for phrase in phrases:
            icon = "🔴" if phrase["severity"] == "red" else "🟠"
            with st.expander(f"{icon}  {phrase['phrase']}"):
                st.markdown(f"<p style='font-size:13px;color:#1a1a1a'>{phrase['explanation']}</p>",
                           unsafe_allow_html=True)

        st.markdown("</div>", unsafe_allow_html=True)

    # Fix 13, 14, 15 — URL breakdown
    url_parts = result.get("url_parts", [])
    if url_parts:
        st.markdown("<div class='fraud-card'>", unsafe_allow_html=True)

        # Fix 13 — dark black title
        st.markdown("<p style='color:#1a1a1a;font-weight:700;font-size:16px;margin-bottom:8px'>Suspicious link breakdown</p>", unsafe_allow_html=True)

        # Fix 14 — finger pointing down
        st.markdown("""
        <div style='background:#E8F5E9;border:1px solid #C8E6C9;border-radius:8px;
        padding:7px 10px;font-size:12px;color:#2E7D32;margin-bottom:10px;text-align:center'>
        👇 Tap each part of the link to understand why it is suspicious</div>
        """, unsafe_allow_html=True)

        # Fix 15 — dark black box expanders
        for part in url_parts:
            status = part["status"]
            icon = "✅" if status == "safe" else \
                   "🔴" if status == "danger" else "⚠️"
            with st.expander(f"{icon}  {part['part']}"):
                st.markdown(f"<p style='font-size:13px;color:#1a1a1a'>{part['explanation']}</p>",
                           unsafe_allow_html=True)

        st.markdown("</div>", unsafe_allow_html=True)

    if st.button("View next steps →"):
        st.session_state.screen = 4
        st.rerun()

# ─── SCREEN 4 — NEXT STEPS ────────────────────────────
elif st.session_state.screen == 4:
    result = st.session_state.analysis_result

    st.markdown("<div class='fraud-card'>", unsafe_allow_html=True)

    # Fix 16 — dark black title
    st.markdown("<p style='color:#1a1a1a;font-weight:700;font-size:16px;margin-bottom:8px'>⚠️ Immediate actions to take</p>", unsafe_allow_html=True)

    for i, step in enumerate(result.get("next_steps", []), 1):
        st.markdown(f"""
        <div style='display:flex;gap:10px;padding:9px 0;border-bottom:1px solid #F1F8E9'>
            <div style='width:24px;height:24px;border-radius:50%;background:#E8F5E9;
            color:#2E7D32;display:flex;align-items:center;justify-content:center;
            font-size:12px;font-weight:700;flex-shrink:0'>{i}</div>
            <div>
                <div style='font-size:14px;font-weight:700;color:#1a1a1a'>{step["title"]}</div>
                <div style='font-size:12px;color:#333;margin-top:3px'>{step["description"]}</div>
            </div>
        </div>
        """, unsafe_allow_html=True)

    st.markdown("</div>", unsafe_allow_html=True)

    st.markdown("<div class='fraud-card'>", unsafe_allow_html=True)

    # Fix 17 — dark black title
    st.markdown("<p style='color:#1a1a1a;font-weight:700;font-size:16px;margin-bottom:10px'>Report to Singapore authorities</p>", unsafe_allow_html=True)

    st.markdown("""
    <a href='https://www.scamshield.org.sg' target='_blank'
    style='display:flex;align-items:center;gap:8px;background:#E8F5E9;
    border:1px solid #A5D6A7;border-radius:8px;padding:10px;font-size:13px;
    color:#1B5E20;font-weight:600;text-decoration:none;margin-bottom:8px'>
    🛡️ ScamShield — Report scam message</a>

    <a href='https://eservices.police.gov.sg' target='_blank'
    style='display:flex;align-items:center;gap:8px;background:#E8F5E9;
    border:1px solid #A5D6A7;border-radius:8px;padding:10px;font-size:13px;
    color:#1B5E20;font-weight:600;text-decoration:none;margin-bottom:8px'>
    👮 Singapore Police Force — Lodge a report</a>

    <a href='https://www.mas.gov.sg/consumer-alert' target='_blank'
    style='display:flex;align-items:center;gap:8px;background:#E8F5E9;
    border:1px solid #A5D6A7;border-radius:8px;padding:10px;font-size:13px;
    color:#1B5E20;font-weight:600;text-decoration:none'>
    🏦 MAS — Report financial scam</a>
    """, unsafe_allow_html=True)

    st.markdown("</div>", unsafe_allow_html=True)

    if st.button("← Check another message"):
        st.session_state.screen = 1
        st.session_state.analysis_result = None
        st.session_state.input_text = ""
        st.session_state.uploaded_image = None
        st.rerun()