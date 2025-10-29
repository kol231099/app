# backend/server.py
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, Dict, Any, List
import os
import re
import pandas as pd

app = FastAPI(title="Restaurant Search API (CSV direct filter)", version="1.0.0")

# CORS（開發期放寬；上線請改白名單）
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------- 路徑與載入 CSV ----------
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(BASE_DIR,  "data")
CSV_PATH = os.path.join(DATA_DIR, "cleaned_restaurants.csv")  # 檔名要跟你實際檔案一致

if not os.path.exists(CSV_PATH):
    raise RuntimeError(f"找不到 CSV：{CSV_PATH}")

DF_RAW = pd.read_csv(CSV_PATH)

def normalize_zh(s: str) -> str:
    # 只做「臺→台」、轉小寫與去頭尾空白；不添加任何新關鍵字
    return str(s or "").replace("臺", "台").strip().lower()

# 嘗試對齊常見欄位名（不改值、不加權）
def standardize_columns(df: pd.DataFrame) -> pd.DataFrame:
    cols = {c.lower(): c for c in df.columns}
    def pick(*names):
        for n in names:
            if n.lower() in cols:
                return cols[n.lower()]
        return None

    name_col = pick("Name")
    addr_col = pick("Address", "Addr", "地址")
    tel_col  = pick("Tel", "電話", "Phone")
    tag_col  = pick("tag", "Tag", "類別", "Category")
    lat_col  = pick("lat", "Lat", "latitude", "Latitude", "y", "Y")
    lon_col  = pick("lon", "Lon", "lng", "Lng", "longitude", "Longitude", "x", "X")
    name_en_col = pick("Name_en")
    addr_en_col = pick("Address_en")
    tag_en_col = pick("Tag_en")
    name_id_col = pick("Name_id")
    addr_id_col = pick("Address_id")
    tag_id_col = pick("Tag_id")

    out = pd.DataFrame()
    out["Name"] = df[name_col] if name_col else ""
    out["Address"] = df[addr_col] if addr_col else ""
    out["Tel"] = df[tel_col] if tel_col else ""
    out["tag"] = df[tag_col] if tag_col else ""
    out["lat"] = pd.to_numeric(df[lat_col], errors="coerce") if lat_col else None
    out["lon"] = pd.to_numeric(df[lon_col], errors="coerce") if lon_col else None
    out["Name_en"] = df[name_en_col] if name_en_col else ""
    out["Address_en"] = df[addr_en_col] if addr_en_col else ""
    out["Tag_en"] = df[tag_en_col] if tag_en_col else ""
    out["Name_id"] = df[name_id_col] if name_id_col else ""
    out["Address_id"] = df[addr_id_col] if addr_id_col else ""
    out["Tag_id"] = df[tag_id_col] if tag_id_col else ""

    # 建一個可檢索欄（只做「臺→台」）
    norm_parts = [
        out["Name"].astype(str).map(normalize_zh),
        out["Address"].astype(str).map(normalize_zh),
        out["tag"].astype(str).map(normalize_zh),
        out["Name_en"].astype(str).map(normalize_zh),
        out["Address_en"].astype(str).map(normalize_zh),
        out["Tag_en"].astype(str).map(normalize_zh),
        out["Name_id"].astype(str).map(normalize_zh),
        out["Address_id"].astype(str).map(normalize_zh),
        out["Tag_id"].astype(str).map(normalize_zh),
    ]
    norm_text = norm_parts[0]
    for series in norm_parts[1:]:
        norm_text = norm_text + " " + series
    out["_norm_text"] = norm_text
    return out

DF = standardize_columns(DF_RAW)

# ---------- 型別 ----------
class QueryBody(BaseModel):
    query: str
    top_k: Optional[int] = 20  # 只控制回傳筆數；不影響過濾邏輯

@app.get("/health")
def health():
    return {"ok": True, "rows": len(DF)}

# ---------- 只用 CSV 的「直接包含」過濾 ----------
@app.post("/search")
def search(body: QueryBody):
    q_raw = (body.query or "").strip()
    if not q_raw:
        raise HTTPException(status_code=400, detail="query 不可為空")

    # 不加任何關鍵字；只做字形正規化（臺→台），然後做 substring 包含
    q_norm = normalize_zh(q_raw)
    pattern = re.escape(q_norm)

    # 任何一欄（Name/Address/tag 的合併欄）有包含就保留
    mask = DF["_norm_text"].str.contains(pattern, na=False)
    hits = DF[mask]

    # 組回傳（不動欄位內容；lat/lon 若不存在就回 null）
    items: List[Dict[str, Any]] = []
    for _, r in hits.head(max(1, body.top_k or 20)).iterrows():
        items.append({
            "Name": str(r.get("Name", "")),
            "Address": str(r.get("Address", "")),
            "Tel": str(r.get("Tel", "")),
            "tag": str(r.get("tag", "")),
            "lat": (float(r["lat"]) if pd.notna(r.get("lat")) else None),
            "lon": (float(r["lon"]) if pd.notna(r.get("lon")) else None),
            "Name_en": str(r.get("Name_en", "")),
            "Address_en": str(r.get("Address_en", "")),
            "Tag_en": str(r.get("Tag_en", "")),
            "Name_id": str(r.get("Name_id", "")),
            "Address_id": str(r.get("Address_id", "")),
            "Tag_id": str(r.get("Tag_id", "")),
        })

    return {
        "natural": f"於本地 CSV 以『{q_raw}』直接過濾，共 {len(hits)} 筆，顯示前 {len(items)} 筆。",
        "items": items
    }

# ========（維持）語意相似度搜尋：/search_cos ========
# 嘗試就近匯入 LLM3（與本檔同在 backend/ 目錄）
try:
    import LLM3  # 以 backend 目錄為工作目錄時
except ImportError:
    try:
        from backend import LLM3  # 以專案根目錄執行時
    except ImportError:
        LLM3 = None  # 匯入失敗時在路由內回報

@app.post("/search_cos")
def search_cos(body: QueryBody):
    if LLM3 is None:
        raise HTTPException(status_code=500, detail="LLM3 模組未找到，請確認 backend/LLM3.py 與 PYTHONPATH 設定")

    q_raw = (body.query or "").strip()
    if not q_raw:
        raise HTTPException(status_code=400, detail="query 不可為空")

    top_k = int(body.top_k or 20)

    # 直接呼叫你在 LLM3.py 內的 search(user_input, df, n=top_k)
    # 注意：使用 LLM3.DF，確保與 LLM3.E 的列數一致
    try:
        res_df = LLM3.search(q_raw, LLM3.DF, n=top_k)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"LLM3.search 執行錯誤: {e}")

    # 組回傳（與 /search 保持欄位一致，另加 score）
    keep = [
        "Name",
        "Address",
        "Tel",
        "tag",
        "lat",
        "lon",
        "score",
        "Name_en",
        "Address_en",
        "Tag_en",
        "Name_id",
        "Address_id",
        "Tag_id",
    ]
    for c in keep:
        if c not in res_df.columns:
            res_df[c] = None if c in ("lat", "lon", "score") else ""

    items: List[Dict[str, Any]] = []
    for _, r in res_df.iterrows():
        items.append({
            "Name": str(r.get("Name", "")),
            "Address": str(r.get("Address", "")),
            "Tel": str(r.get("Tel", "")),
            "tag": str(r.get("tag", "")),
            "lat": (float(r["lat"]) if pd.notna(r.get("lat")) else None),
            "lon": (float(r["lon"]) if pd.notna(r.get("lon")) else None),
            "score": (float(r["score"]) if pd.notna(r.get("score")) else None),
            "Name_en": str(r.get("Name_en", "")),
            "Address_en": str(r.get("Address_en", "")),
            "Tag_en": str(r.get("Tag_en", "")),
            "Name_id": str(r.get("Name_id", "")),
            "Address_id": str(r.get("Address_id", "")),
            "Tag_id": str(r.get("Tag_id", "")),
        })

    return {
        "natural": f"於本地 CSV 以語意相似度搜尋『{q_raw}』，顯示前 {len(items)} 筆。",
        "items": items
    }

# ======== 把 LLM3 的 Router 掛進來（提供 /chat_route）========
# 這段要放在 app 與上面路由定義之後
try:
    # 嘗試兩種 import 方式（依你啟動的位置而定）
    try:
        from . import LLM3 as _LLM3_pkg   # 當 backend 是套件時
        _router = getattr(_LLM3_pkg, "router", None)
    except Exception:
        _router = getattr(LLM3, "router", None)   # 直接從上面的 LLM3 變數取

    if _router is not None:
        app.include_router(_router)  # 不加 prefix，維持 /chat_route
    else:
        print("⚠️ LLM3.router 未找到（請確認 LLM3.py 已改為 APIRouter 並命名為 router）")
except Exception as e:
    print(f"⚠️ 掛載 LLM3.router 失敗：{e!r}")







