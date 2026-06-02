import os
import logging
import pickle
import pandas as pd
# from surprise import Dataset, Reader, SVD
# from surprise.model_selection import RandomizedSearchCV
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

logger = logging.getLogger(__name__)
MODEL_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "models")
MODEL_PATH = os.path.join(MODEL_DIR, "svd_model.pkl")
TFIDF_MODEL_PATH = os.path.join(MODEL_DIR, "tfidf_matrix.pkl")

os.makedirs(MODEL_DIR, exist_ok=True)

def train_svd(interactions_df: pd.DataFrame) -> dict:
    """
    SVD DINONAKTIFKAN SEMENTARA KARENA scikit-surprise TIDAK DIINSTAL
    """
    logger.warning("Fungsi train_svd dilewati karena scikit-surprise dinonaktifkan.")
    
    # [LOGIKA ANTI-OVERFIT UNTUK REFERENSI MASA DEPAN]
    # param_grid = { 'n_factors': [10, 50, 100], 'lr_all': [0.002, 0.005, 0.01], 'reg_all': [0.02, 0.05, 0.1, 0.2] }
    # gs = RandomizedSearchCV(SVD, param_grid, measures=['rmse', 'mae'], cv=5, ...)
    # best_rmse = gs.best_score['rmse']
    # 
    # cv_results = pd.DataFrame.from_dict(gs.cv_results)
    # best_idx = gs.best_index
    # train_rmse = cv_results['mean_train_rmse'][best_idx] if 'mean_train_rmse' in cv_results else best_rmse
    #
    # if abs(best_rmse - train_rmse) > 0.15:
    #     return {"status": "error", "message": "Model Overfitting (Gap RMSE Latih vs Uji > 0.15). Model ditolak."}
    
    return {
        "status": "success",
        "best_rmse": 0.0,
        "best_params": {"message": "SVD disabled"}
    }

def precompute_tfidf(items_df: pd.DataFrame) -> dict:
    """
    Menghitung Matrix TF-IDF dan Cosine Similarity dari seluruh barang, lalu menyimpannya.
    """
    if items_df.empty:
        return {"status": "error", "message": "Dataset item kosong, tidak bisa prekomputasi TF-IDF."}
        
    items_df['combined_features'] = items_df['name'].fillna('') + " " + \
                                    items_df['description'].fillna('') + " " + \
                                    items_df['categoryName'].fillna('')
                                    
    tfidf = TfidfVectorizer(stop_words='english')
    tfidf_matrix = tfidf.fit_transform(items_df['combined_features'])
    
    cosine_sim = cosine_similarity(tfidf_matrix, tfidf_matrix)
    
    with open(TFIDF_MODEL_PATH, 'wb') as f:
        pickle.dump(cosine_sim, f)
        
    logger.info("TF-IDF Matrix berhasil dihitung dan dicache.")
    return {"status": "success", "message": "TF-IDF matrix cached successfully"}

def get_collaborative_recommendations(user_id: str, items_df: pd.DataFrame, limit: int = 10) -> list:
    """
    SVD DINONAKTIFKAN SEMENTARA KARENA scikit-surprise TIDAK DIINSTAL.
    Selalu fallback mengembalikan list kosong.
    """
    logger.warning("Fungsi get_collaborative_recommendations dilewati karena SVD dinonaktifkan.")
    return []

def get_content_based_recommendations(target_item_id: str, items_df: pd.DataFrame, limit: int = 10) -> list:
    """
    Rekomendasi barang serupa berdasarkan kemiripan teks (Membaca Cache TF-IDF Matrix).
    Sangat cepat (milidetik).
    """
    if items_df.empty or target_item_id not in items_df['id'].values:
        return []

    # Jika file cache tidak ada, hitung on-the-fly untuk menghindari error
    if not os.path.exists(TFIDF_MODEL_PATH):
        logger.warning("Cache TF-IDF tidak ditemukan! Menjalankan pre-komputasi darurat...")
        precompute_tfidf(items_df)

    with open(TFIDF_MODEL_PATH, 'rb') as f:
        cosine_sim = pickle.load(f)
        
    try:
        # Ambil index dari target item
        idx = items_df.index[items_df['id'] == target_item_id].tolist()[0]
        
        sim_scores = list(enumerate(cosine_sim[idx]))
        sim_scores = sorted(sim_scores, key=lambda x: x[1], reverse=True)
        
        # Ambil index item mirip (abaikan item itu sendiri pada index 0)
        sim_scores = sim_scores[1:limit+1]
        
        item_indices = [i[0] for i in sim_scores]
        recommended_ids = items_df.iloc[item_indices]['id'].tolist()
        
        return recommended_ids
    except Exception as e:
        logger.error(f"Gagal mengambil rekomendasi Content-Based: {e}")
        return []

def get_fallback_recommendations(items_df: pd.DataFrame, limit: int = 10) -> list:
    """
    Rekomendasi untuk Cold Start (User Baru).
    Berdasarkan ownerRating tertinggi atau data terbaru.
    """
    if items_df.empty:
        return []
        
    # Sort by ownerRating jika ada
    if 'ownerRating' in items_df.columns:
        sorted_df = items_df.sort_values(by='ownerRating', ascending=False)
        return sorted_df['id'].head(limit).tolist()
        
    # Default fallback: ambil data secara urutan
    return items_df['id'].head(limit).tolist()
