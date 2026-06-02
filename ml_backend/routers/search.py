import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))

from fastapi import APIRouter
from schemas import SearchRecommendRequest, RecommendResponse
from core.data_fetcher import fetch_items_df
from core.ml_engine import get_content_based_recommendations

router = APIRouter()

@router.post("/search-recommend", response_model=RecommendResponse)
def get_search_recommendations(req: SearchRecommendRequest):
    """
    Rekomendasi Detail Barang & Pencarian.
    Menggunakan Content-Based Filtering (TF-IDF & Cosine Similarity)
    berdasarkan name, description, dan categoryName.
    """
    items_df = fetch_items_df()
    
    recommended_ids = get_content_based_recommendations(req.itemId, items_df, req.limit)
    
    if recommended_ids:
        return RecommendResponse(items=recommended_ids, method="content_based_filtering")
    else:
        # Jika item tidak ditemukan, kembalikan list kosong
        return RecommendResponse(items=[], method="content_based_filtering")
