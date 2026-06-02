import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))

from fastapi import APIRouter
from schemas import RecommendRequest, RecommendResponse
from core.data_fetcher import fetch_items_df, fetch_interactions_df
from core.ml_engine import get_collaborative_recommendations, get_fallback_recommendations
import pandas as pd

router = APIRouter()

@router.post("/recommend", response_model=RecommendResponse)
def get_recommendations(req: RecommendRequest):
    """
    Rekomendasi Halaman Beranda (Home Screen).
    Jika userId ada dan punya riwayat: Collaborative Filtering SVD.
    Jika tidak: Fallback ke Popularity/Rating.
    """
    items_df = fetch_items_df()
    
    if req.userId:
        interactions_df = fetch_interactions_df()
        
        # Cek apakah user punya riwayat
        if not interactions_df.empty and req.userId in interactions_df['userId'].values:
            # Gunakan SVD
            recommended_ids = get_collaborative_recommendations(req.userId, items_df, req.limit)
            
            if recommended_ids:
                return RecommendResponse(items=recommended_ids, method="collaborative_filtering_svd")
                
    # Fallback (Cold Start)
    fallback_ids = get_fallback_recommendations(items_df, req.limit)
    return RecommendResponse(items=fallback_ids, method="popularity_fallback")
