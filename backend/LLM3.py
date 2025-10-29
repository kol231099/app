# backend/LLM3.py
import os
import re
import json
import numpy as np
import pandas as pd
import requests
from numpy.linalg import norm
from sentence_transformers import SentenceTransformer
from typing import List, Dict, Optional

# ===== FastAPI Router / Schema =====
from fastapi import APIRouter
from pydantic import BaseModel

# ========= 路徑設定：以「這個檔案所在位置」為基準 =========
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(BASE_DIR, "data")

CSV_PATH = os.path.join(DATA_DIR, "cleaned_restaurants.csv")
EMB_PATH = os.path.join(DATA_DIR, "embeddings.npy")

print(f"📂 CSV 路徑: {CSV_PATH}")
print(f"📂 EMB 路徑: {EMB_PATH}")

# ========= 金鑰改用環境變數 =========
OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY", "")
GOOGLE_MAPS_API_KEY = os.getenv("GOOGLE_MAPS_API_KEY", "")

if not OPENROUTER_API_KEY:
    print("⚠️  未設定 OPENROUTER_API_KEY 環境變數")
if not GOOGLE_MAPS_API_KEY:
    print("⚠️  未設定 GOOGLE_MAPS_API_KEY 環境變數")

OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"
LLM_MODEL = "openai/gpt-5-mini"

# ========= 載入資料 / 模型 =========
DF = pd.read_csv(CSV_PATH)

def _compose_text(row: pd.Series) -> str:
    parts = []
    for col in [
        "Name",
        "Address",
        "tag",
        "Name_en",
        "Address_en",
        "Tag_en",
        "Name_id",
        "Address_id",
        "Tag_id",
    ]:
        value = row.get(col, "")
        if pd.isna(value):
            continue
        text = str(value).strip()
        if text:
            parts.append(text)
    return " ".join(parts)

DF["text"] = DF.apply(_compose_text, axis=1)

MODEL = SentenceTransformer("BAAI/bge-small-zh")

LANG_CONFIG = {
    "zh": {
        "display": "繁體中文",
        "hint": "請以繁體中文回覆。",
        "google_language": "zh-TW",
    },
    "en": {
        "display": "English",
        "hint": "Please reply in English.",
        "google_language": "en",
    },
    "id": {
        "display": "Bahasa Indonesia",
        "hint": "Silakan jawab dalam Bahasa Indonesia.",
        "google_language": "id",
    },
}


def _lang_conf(lang: Optional[str]) -> Dict[str, str]:
    return LANG_CONFIG.get((lang or "zh").lower(), LANG_CONFIG["zh"])

# ========= embeddings 自動重建（防止維度錯誤） =========
def _build_embeddings_if_missing(df: pd.DataFrame, path: str) -> np.ndarray:
    """
    讀取 embeddings.npy；若不存在、維度不符或筆數不符，就自動重建並覆蓋。
    """
    os.makedirs(os.path.dirname(path), exist_ok=True)
    expected_dim = MODEL.get_sentence_embedding_dimension()
    expected_rows = len(df)

    def _rebuild() -> np.ndarray:
        texts = df["text"].fillna("").astype(str).tolist()
        batch = 128
        embs = []
        for i in range(0, len(texts), batch):
            emb = MODEL.encode(
                texts[i:i+batch],
                normalize_embeddings=True,
                convert_to_numpy=True,
            )
            embs.append(emb)
        E_new = np.vstack(embs).astype(np.float32)
        np.save(path, E_new)
        print(f"✅ 已建立並保存嵌入：{path}  形狀={E_new.shape}")
        return E_new

    if os.path.exists(path):
        try:
            E_loaded = np.load(path)
            ok_shape = (
                E_loaded.ndim == 2
                and E_loaded.shape[1] == expected_dim
                and E_loaded.shape[0] == expected_rows
            )
            if ok_shape:
                return E_loaded
            else:
                print("⚠️  既有 embeddings 維度或筆數不符，將重新建立…")
                return _rebuild()
        except Exception as _:
            print("⚠️  既有 embeddings 讀取失敗，將重新建立…")
            return _rebuild()
    else:
        print("ℹ️  尚未找到 embeddings 檔，開始建立…")
        return _rebuild()

E = _build_embeddings_if_missing(DF, EMB_PATH)

# ========= 呼叫 OpenRouter =========
def _openrouter_headers() -> Dict[str, str]:
    return {
        "Authorization": f"Bearer {OPENROUTER_API_KEY}",
        "Content-Type": "application/json",
    }

def _openrouter_chat(prompt: str) -> str:
    data = {"model": LLM_MODEL, "messages": [{"role": "system", "content": prompt}]}
    r = requests.post(OPENROUTER_URL, headers=_openrouter_headers(), json=data, timeout=60)
    r.raise_for_status()
    j = r.json()
    return j["choices"][0]["message"]["content"]

# ========= Google Maps =========
def google_maps_search(query: str, location: Optional[str] = None, radius: int = 5000,
                       max_results: int = 5, language: str = "zh-TW") -> List[Dict]:
    url = "https://maps.googleapis.com/maps/api/place/textsearch/json"
    params = {
        "query": query,
        "key": GOOGLE_MAPS_API_KEY,
        "language": language,
    }
    if location:
        params["location"] = location
        params["radius"] = radius

    r = requests.get(url, params=params, timeout=30)
    data = r.json()
    if data.get("status") != "OK":
        print("⚠️ Google Maps API 錯誤:", data.get("status"), data.get("error_message"))
        return []

    results = data.get("results", [])[:max_results]
    out = []
    for it in results:
        loc = it.get("geometry", {}).get("location", {})
        out.append({
            "Name": it.get("name", ""),
            "Address": it.get("formatted_address", ""),
            "Rating": it.get("rating", "無"),
            "lat": loc.get("lat"),
            "lon": loc.get("lng"),
            "Place_ID": it.get("place_id", ""),
        })
    return out

def explain_results(chat_history: str, last: str, query: str, lang: str = "zh"):
    cfg = _lang_conf(lang)
    results = google_maps_search(query, language=cfg["google_language"])
    prompt = f"""
以下是 Google Maps 查詢的結果，請用{cfg['display']}自然語言解釋給使用者，
並同時輸出 JSON 格式的餐廳清單。

結果: {results}

歷史紀錄: "{chat_history}"
最後一條訊息: "{last}"

請輸出:
[NATURAL] 人類可讀的描述
[JSON] 餐廳清單（陣列，每個元素至少含 Name/Address/lat/lon，可含 Tel/tag）
{cfg['hint']}
"""
    raw_text = _openrouter_chat(prompt)
    natural, json_block = "", "[]"
    if "[NATURAL]" in raw_text and "[JSON]" in raw_text:
        parts = raw_text.split("[JSON]")
        natural = parts[0].replace("[NATURAL]", "").strip()
        json_block = parts[1].strip()
    return natural, json_block

# ========= 語意檢索 =========
def search(user_input, df, n=25):
    """
    - user_input: 使用者輸入字串
    - df: 要計分與回傳的 DataFrame（請傳 LLM3.DF 或你自己過濾後的 df）
    - n: 取前 n 筆
    注意：df 的列數需與全域嵌入矩陣 E 的列數對齊（若你傳的是 LLM3.DF 就沒問題）
    """
    q = MODEL.encode([user_input], normalize_embeddings=True)[0]
    scores = E @ q / (norm(E, axis=1) * norm(q))   # 向量化計算
    out = df.copy()
    out["score"] = scores
    return out.sort_values("score", ascending=False).head(n)

def rerank_with_llm(chat_history: str, last: str, candidates: pd.DataFrame, lang: str = "zh"):
    cfg = _lang_conf(lang)
    prompt = f"""
以下是候選餐廳，請依對話紀錄「最後一條」從中挑選最符合使用者需求的幾家餐廳，
數量由你決定，約3~10個。
- 只能從候選清單中選，確保 JSON 資料正確性，不可編造
- 請輸出兩個區塊：
  [NATURAL] 中文自然語言描述（給人類看）
  [JSON] JSON 陣列（給程式用），元素至少包含 Name/Address/lat/lon，可含 Tel/tag

候選清單：
{candidates.to_dict(orient='records')}

歷史紀錄: "{chat_history}"
最後一條訊息: "{last}"
{cfg['hint']}
"""
    raw_text = _openrouter_chat(prompt)
    natural, json_block = "", "[]"
    if "[NATURAL]" in raw_text and "[JSON]" in raw_text:
        parts = raw_text.split("[JSON]")
        natural = parts[0].replace("[NATURAL]", "").strip()
        json_block = parts[1].strip()
    return natural, json_block

def LLM_start_search(chat_history: str, last: str, sentence: str, lang: str = "zh"):
    candidates = search_local(sentence)  # 需要 search_local
    natural_language, json_block = rerank_with_llm(chat_history, last, candidates, lang=lang)
    return natural_language, json_block

def Chat(chat_history: str, last: str, lang: str = "zh"):
    cfg = _lang_conf(lang)
    prompt = f"""
你是一個餐廳搜尋助理。除非使用者明確要求「Google 評價／最新評論／營業時間／上網查」，
否則一律先使用【本地資料庫】（CSV + 向量檢索）。
請只輸出下列其中一種工具指令，勿輸出多餘文字：

1) 預設（本地優先）→ 請輸出：
[START_SEARCH] {{"query": "<根據最後一條訊息整理、並強調地區與需求的查詢字串>"}}

2) 僅當使用者明確要求即時資訊（含：google、Google、評價、評論、營業時間、上網、最新），
   或本地資料明顯不足時 → 才輸出：
[CALL_GOOGLE_MAPS] {{"query": "<地區 + 關鍵字>"}}

歷史紀錄: "{chat_history}"
最後一條訊息: "{last}"
{cfg['hint']}
"""
    raw = _openrouter_chat(prompt)

    if "[START_SEARCH]" in raw:
        m = re.search(r'"query"\s*:\s*"([^"]+)"', raw)
        query = m.group(1) if m else last
        return LLM_start_search(chat_history, last, query, lang=lang)

    if "[CALL_GOOGLE_MAPS]" in raw:
        m = re.search(r'"query"\s*:\s*"([^"]+)"', raw)
        query = m.group(1) if m else last
        return explain_results(chat_history, last, query, lang=lang)

    return raw, None

def search_local(text: str, n: int = 50) -> pd.DataFrame:
    """用全域 DF + 向量 E 做語意檢索，回傳前 n 筆 DataFrame。"""
    return search(text, DF, n=n)

def explain_results_with_loc(chat_history: str, last: str, query: str,
                             lat: Optional[float] = None, lon: Optional[float] = None,
                             radius: int = 5000, lang: str = "zh"):
    cfg = _lang_conf(lang)
    location = f"{lat},{lon}" if (lat is not None and lon is not None) else None
    results = google_maps_search(
        query,
        location=location,
        radius=radius,
        max_results=25,
        language=cfg["google_language"],
    )
    prompt = f"""
以下是 Google Maps 查詢的結果，請用{cfg['display']}自然語言解釋給使用者，
並同時輸出 JSON 格式的餐廳清單。

結果: {results}

歷史紀錄: "{chat_history}"
最後一條訊息: "{last}"

請輸出:
[NATURAL] 人類可讀的描述
[JSON] 餐廳清單（陣列，每個元素至少含 Name/Address/lat/lon，可含 Tel/tag）
{cfg['hint']}
"""
    raw_text = _openrouter_chat(prompt)
    natural, json_block = "", "[]"
    if "[NATURAL]" in raw_text and "[JSON]" in raw_text:
        parts = raw_text.split("[JSON]")
        natural = parts[0].replace("[NATURAL]", "").strip()
        json_block = parts[1].strip()
    return natural, json_block

def Chat_with_loc(chat_history: str, last: str,
                  lat: Optional[float] = None, lon: Optional[float] = None,
                  radius: int = 5000, lang: str = "zh"):
    cfg = _lang_conf(lang)
    prompt = f"""
你是一個餐廳搜尋助理。除非使用者明確要求「Google 評價／最新評論／營業時間／上網查」，
否則一律先使用【本地資料庫】（CSV + 向量檢索）。
請只輸出下列其中一種工具指令，勿輸出多餘文字：

1) 預設（本地優先）→ 請輸出：
[START_SEARCH] {{"query": "<根據最後一條訊息整理、並強調地區與需求的查詢字串>"}}

2) 僅當使用者明確要求即時資訊（含：google、Google、評價、評論、營業時間、上網、最新），
   或本地資料明顯不足時 → 才輸出：
[CALL_GOOGLE_MAPS] {{"query": "<地區 + 關鍵字>"}}

歷史紀錄: "{chat_history}"
最後一條訊息: "{last}"
{cfg['hint']}
"""
    raw = _openrouter_chat(prompt)

    def _extract_or(fallback: str) -> str:
        m = re.search(r'"query"\s*:\s*"([^"]+)"', raw)
        return m.group(1) if m else fallback

    if "[START_SEARCH]" in raw:
        query = _extract_or(last)
        candidates = search_local(query, n=80)
        natural, json_block = rerank_with_llm(chat_history, last, candidates, lang=lang)
        return {"action": "START_SEARCH", "query": query, "natural": natural, "items_json": json_block}

    if "[CALL_GOOGLE_MAPS]" in raw:
        query = _extract_or(last)
        natural, json_block = explain_results_with_loc(
            chat_history, last, query, lat=lat, lon=lon, radius=radius, lang=lang
        )
        return {"action": "CALL_GOOGLE_MAPS", "query": query, "natural": natural, "items_json": json_block}

    # 無法判斷就退而求其次：當本地搜
    query = last
    candidates = search_local(query, n=50)
    natural, json_block = rerank_with_llm(chat_history, last, candidates, lang=lang)
    return {"action": "START_SEARCH", "query": query, "natural": natural, "items_json": json_block}

# =========（這裡改為 Router，而不是整支 FastAPI App）=========
router = APIRouter()

class ChatRouteReq(BaseModel):
    chat_history: str
    last: str
    lat: Optional[float] = None
    lon: Optional[float] = None
    radius: int = 5000
    lang: Optional[str] = "zh"

class ChatRouteResp(BaseModel):
    action: str
    query: str
    natural: Optional[str] = None
    items: list = []

@router.post("/chat_route", response_model=ChatRouteResp)
def chat_route(req: ChatRouteReq):
    """
    前端只要打這支：
    1) 後端決策 START_SEARCH / CALL_GOOGLE_MAPS
    2) 回傳 natural + items（items 為已解析正規化的清單）
    """
    out = Chat_with_loc(
        req.chat_history,
        req.last,
        lat=req.lat,
        lon=req.lon,
        radius=req.radius,
        lang=req.lang or "zh",
    )

    natural = out.get("natural") or ""
    items_json = out.get("items_json") or "[]"
    try:
        items = json.loads(items_json)
    except Exception:
        items = []

    # 正規化欄位名稱
    normed = []
    if isinstance(items, list):
        for e in items:
            if not isinstance(e, dict):
                continue
            normed.append({
                "Name":   str(e.get("Name") or e.get("name") or ""),
                "Address":str(e.get("Address") or e.get("address") or ""),
                "Tel":    str(e.get("Tel") or e.get("tel") or ""),
                "tag":    str(e.get("tag") or e.get("Tag") or ""),
                "lat":    float(e.get("lat")) if e.get("lat") is not None else None,
                "lon":    float(e.get("lon")) if e.get("lon") is not None else None,
                "score":  float(e.get("score")) if e.get("score") is not None else None,
                "Name_en": str(e.get("Name_en") or e.get("name_en") or ""),
                "Address_en": str(e.get("Address_en") or e.get("address_en") or ""),
                "Tag_en": str(e.get("Tag_en") or e.get("tag_en") or ""),
                "Name_id": str(e.get("Name_id") or e.get("name_id") or ""),
                "Address_id": str(e.get("Address_id") or e.get("address_id") or ""),
                "Tag_id": str(e.get("Tag_id") or e.get("tag_id") or ""),
            })

    return {
        "action": out.get("action", "START_SEARCH"),
        "query":  out.get("query", req.last),
        "natural": natural,
        "items": normed,
    }

# ========= CLI 測試入口（可保留）=========
if __name__ == "__main__":
    greeting = "您需要尋找什麼樣的餐廳？"
    print(greeting)
    while True:
        u = input("> ").strip()
        if not u:
            continue
        text, js = Chat(f"小助手：{greeting}\n使用者：{u}\n", u)
        print(text)
        if js:
            print(js)

