# ML Backend — SewainAja Recommendation System

Backend Machine Learning untuk sistem rekomendasi aplikasi SewainAja.
Dibangun menggunakan Python + FastAPI.

## Struktur Folder

```
ml_backend/
├── main.py                  # FastAPI app entry point
├── requirements.txt         # Python dependencies
├── models/                  # Trained model files (.pkl)
│   └── .gitkeep
├── data/                    # Dataset CSV files
│   ├── items.csv            # (generate via Colab)
│   └── interactions.csv     # (generate via Colab)
├── scripts/                 # Training & data generation scripts
│   ├── generate_dataset.py  # Synthetic data generator (jalankan di Colab)
│   └── train_model.py       # Model training script (jalankan di Colab)
└── routers/                 # FastAPI route handlers
    ├── recommend.py         # POST /recommend — home screen
    └── search.py            # POST /search-recommend — search page
```

## Cara Pakai (Setelah Model Siap)

1. Jalankan notebook Colab → download `content_model.pkl` → taruh di `models/`
2. Install dependencies: `pip install -r requirements.txt`
3. Jalankan server: `uvicorn main:app --reload --port 8000`
4. Dari emulator Android, akses via `http://10.0.2.2:8000`

## Endpoints

| Method | URL | Deskripsi |
|--------|-----|-----------|
| GET | `/health` | Cek server aktif |
| POST | `/recommend` | Rekomendasi home screen |
| POST | `/search-recommend` | Rekomendasi saat search |
