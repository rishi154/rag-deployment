# Add this to your backend application for health check endpoint

from fastapi import FastAPI
from fastapi.responses import JSONResponse

app = FastAPI()

@app.get("/api/health")
async def health_check():
    """Health check endpoint for load balancer"""
    return JSONResponse(
        status_code=200,
        content={"status": "healthy", "service": "rag-backend"}
    )

@app.get("/")
async def root():
    """Root endpoint"""
    return {"message": "RAG Backend API"}