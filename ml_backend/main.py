# main.py — FastAPI App Entry Point

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import firebase_config  # Ini akan menginisialisasi Firebase saat startup

from routers import recommend, search, train

app = FastAPI(
    title="SewainAja ML Recommendation API",
    description="Sistem rekomendasi barang sewa berbasis Machine Learning",
    version="1.0.0",
)

# Konfigurasi CORS agar bisa diakses dari aplikasi / klien lain
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mendaftarkan router
app.include_router(recommend.router, tags=["Recommendations"])
app.include_router(search.router, tags=["Recommendations"])
app.include_router(train.router, tags=["Admin/Training"])

@app.get("/health", tags=["Health"])
def health_check():
    # Cek apakah Firebase terhubung
    firebase_connected = firebase_config.db is not None
    return {
        "status": "ok", 
        "firebase_connected": firebase_connected,
        "message": "Sistem ML berjalan normal."
    }
