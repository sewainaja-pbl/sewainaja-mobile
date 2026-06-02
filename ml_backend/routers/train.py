import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))

from fastapi import APIRouter
from core.data_fetcher import fetch_interactions_df, fetch_items_df
from core.ml_engine import train_svd, precompute_tfidf
from pydantic import BaseModel

router = APIRouter()

class TrainResponse(BaseModel):
    status: str
    message: str
    best_rmse: float = None
    best_params: dict = None

@router.post("/train", response_model=TrainResponse)
def run_training():
    """
    Endpoint khusus untuk melakukan Hypertuning (Random Search) dan melatih ulang model SVD.
    Menarik data transaksi terbaru dari Firestore.
    Idealnya dijalankan oleh Admin atau via Cron Job (bukan oleh end-user).
    """
    interactions_df = fetch_interactions_df()
    items_df = fetch_items_df()
    
    # 1. Prekomputasi TF-IDF (Content-Based)
    tfidf_result = precompute_tfidf(items_df)
    
    # 2. Training SVD (Collaborative)
    result = train_svd(interactions_df)
    
    if result.get("status") == "error":
        return TrainResponse(
            status="error",
            message=result.get("message", "Gagal melakukan training SVD.")
        )
        
    final_message = f"Prekomputasi: {tfidf_result.get('message', '')} | SVD: {result.get('best_params', {}).get('message', '')}"
    
    return TrainResponse(
        status="success",
        message=final_message,
        best_rmse=result.get("best_rmse"),
        best_params=result.get("best_params")
    )
