from fastapi import FastAPI, File, UploadFile,
from google.cloud import storage
from fastapi.responses import JSONResponse
import logging
app = FastAPI()

BUCKET_NAME = "training-footage"

@app.post("/upload")
async def upload(file: UploadFile = File(...)):
    try:
        client = storage.Client()
        bucket = client.bucket(BUCKET_NAME)
        blob = bucket.blob(file.filename)

        blob.upload_from_file(file.file, content_type=file.content_type)

        return {
            "message": "Upload successful",
            "filename": file.filename,
            "content_type": file.content_type
        }
    except Exception as e:
        logging.exception("Upload failed")
        return JSONResponse(status_code=500, content={"error": str(e)})