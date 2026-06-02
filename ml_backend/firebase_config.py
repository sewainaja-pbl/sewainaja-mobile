import os
import json
import logging
import firebase_admin
from firebase_admin import credentials, firestore

logger = logging.getLogger(__name__)

# Path ke file kredensial lokal
CREDENTIALS_PATH = os.path.join(os.path.dirname(__file__), "firebase-credentials.json")

def init_firebase():
    """
    Inisialisasi koneksi Firebase menggunakan kredensial lokal.
    Jika file kredensial tidak ditemukan, akan mencetak warning.
    """
    if not firebase_admin._apps:
        if os.path.exists(CREDENTIALS_PATH):
            try:
                cred = credentials.Certificate(CREDENTIALS_PATH)
                firebase_admin.initialize_app(cred)
                logger.info("Firebase Admin SDK berhasil diinisialisasi dari file kredensial.")
            except Exception as e:
                logger.error(f"Gagal menginisialisasi Firebase: {str(e)}")
        else:
            logger.warning(
                f"\n{'='*60}\n"
                f"WARNING: File {CREDENTIALS_PATH} tidak ditemukan!\n"
                f"Sistem ML akan berjalan dalam Mode Fallback (Dummy Data) "
                f"jika Anda belum memiliki kredensial Firebase.\n"
                f"{'='*60}"
            )
            # Untuk keperluan PBL, kita tidak membatalkan proses aplikasi,
            # router akan menangkap ValueError jika db tidak tersedia.
            return None
            
    return firestore.client() if firebase_admin._apps else None

# Instance database global
db = init_firebase()
