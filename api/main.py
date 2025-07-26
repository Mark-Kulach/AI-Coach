from fastapi import FastAPI, File, UploadFile
from google.cloud import storage

app = FastAPI()

BUCKET_NAME = "training-footage"

@app.post("/upload")
async def upload(file: UploadFile = File(...)):
    client = storage.Client()
    bucket = client.bucket(BUCKET_NAME)
    blob = bucket.blob(file.filename)

    blob.upload_from_file(file.file, content_type=file.content_type)

    return {
        "message": "Upload successful",
        "filename": file.filename,
        "content_type": file.content_type
    }
