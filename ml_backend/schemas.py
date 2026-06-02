from pydantic import BaseModel
from typing import Optional, List

class RecommendRequest(BaseModel):
    userId: Optional[str] = None
    limit: int = 10

class SearchRecommendRequest(BaseModel):
    itemId: str
    limit: int = 10

class RecommendResponse(BaseModel):
    items: List[str]
    method: str
