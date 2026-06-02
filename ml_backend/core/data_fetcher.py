import pandas as pd
import logging
from firebase_config import db

logger = logging.getLogger(__name__)

def fetch_items_df() -> pd.DataFrame:
    """
    Mengambil data koleksi 'items' dari Firestore.
    Mengembalikan DataFrame Pandas.
    Hanya mengambil item dengan status 'available'.
    """
    if db is None:
        logger.warning("Database Firestore tidak terhubung. Menggunakan DataFrame kosong untuk items.")
        return pd.DataFrame(columns=["id", "name", "description", "categoryName", "ownerRating", "status"])
        
    try:
        items_ref = db.collection('items').where('status', '==', 'available')
        docs = items_ref.stream()
        
        data = []
        for doc in docs:
            d = doc.to_dict()
            d['id'] = doc.id
            data.append(d)
            
        df = pd.DataFrame(data)
        if df.empty:
            return pd.DataFrame(columns=["id", "name", "description", "categoryName", "ownerRating", "status"])
            
        return df
    except Exception as e:
        logger.error(f"Gagal mengambil items dari Firestore: {e}")
        return pd.DataFrame()

def fetch_interactions_df() -> pd.DataFrame:
    """
    Mengambil data interaksi user (misal dari koleksi 'user_interactions' atau 'ratings').
    Jika belum ada koleksi interaksi yang real di Firestore, kita mengembalikan fallback.
    """
    if db is None:
        logger.warning("Database Firestore tidak terhubung. Menggunakan DataFrame kosong untuk interaksi.")
        return pd.DataFrame(columns=["userId", "itemId", "rating"])
        
    try:
        # Asumsi koleksi bernama 'ratings' atau 'interactions'
        # Ubah nama koleksi ini jika tim backend menggunakan nama lain
        interactions_ref = db.collection('interactions')
        docs = interactions_ref.stream()
        
        data = []
        for doc in docs:
            d = doc.to_dict()
            data.append(d)
            
        df = pd.DataFrame(data)
        if df.empty:
            return pd.DataFrame(columns=["userId", "itemId", "rating"])
            
        # PENTING: Pra-pemrosesan rating implisit.
        # Mengelompokkan interaksi berdasarkan userId & itemId, lalu ambil rating terbesar (max)
        # Misal: jika user pernah View (1) dan Rent (5), maka nilai akhir adalah 5.
        if 'userId' in df.columns and 'itemId' in df.columns and 'rating' in df.columns:
            df['rating'] = pd.to_numeric(df['rating'], errors='coerce').fillna(1)
            df = df.groupby(['userId', 'itemId'])['rating'].max().reset_index()
            
        return df
    except Exception as e:
        logger.error(f"Gagal mengambil interactions dari Firestore: {e}")
        return pd.DataFrame()
