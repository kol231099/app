import pandas as pd
import numpy as np
from sentence_transformers import SentenceTransformer
import os

# 讀取你的 CSV
csv_path = "data/cleaned_restaurants.csv"
df = pd.read_csv(csv_path)

# 取出要轉成向量的欄位（可以依你的資料修改）
texts = df["Name"].astype(str) + " " + df["Address"].astype(str) + " " + df["tag"].astype(str)

# 載入 embedding 模型（會自動下載）
model = SentenceTransformer('paraphrase-MiniLM-L6-v2')

# 計算 embeddings
embeddings = model.encode(texts.tolist(), show_progress_bar=True)

# 存成 numpy 檔案
os.makedirs("data", exist_ok=True)
np.save("data/embeddings.npy", embeddings)

print("✅ embeddings.npy 已建立，共", embeddings.shape[0], "筆資料。")
