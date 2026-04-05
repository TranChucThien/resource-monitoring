import os
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from pymongo import MongoClient
from bson import ObjectId
from fastapi.middleware.cors import CORSMiddleware
app = FastAPI()

# Cấu hình CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Cho phép tất cả frontend gọi
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Lấy config từ environment variable
MONGO_USER = os.getenv("MONGO_USER", "root")
MONGO_PASS = os.getenv("MONGO_PASS", "example")
MONGO_HOST = os.getenv("MONGO_HOST", "mongo_db")   # mặc định dùng service name
MONGO_PORT = int(os.getenv("MONGO_PORT", 27017))
MONGO_DB   = os.getenv("MONGO_DB", "crud_demo")

# Kết nối MongoDB
MONGO_URI = f"mongodb://{MONGO_USER}:{MONGO_PASS}@{MONGO_HOST}:{MONGO_PORT}/{MONGO_DB}?authSource=admin"
client = MongoClient(MONGO_URI)
db = client[MONGO_DB]
users_collection = db["users"]

# Model request
class User(BaseModel):
    name: str
    email: str

# Helper convert ObjectId
def user_serializer(user) -> dict:
    return {
        "id": str(user["_id"]),
        "name": user["name"],
        "email": user["email"]
    }

@app.post("/users")
def create_user(user: User):
    new_user = users_collection.insert_one(user.dict())
    created_user = users_collection.find_one({"_id": new_user.inserted_id})
    return user_serializer(created_user)

@app.get("/users")
def list_users():
    users = users_collection.find()
    return [user_serializer(u) for u in users]

@app.get("/users/{user_id}")
def get_user(user_id: str):
    user = users_collection.find_one({"_id": ObjectId(user_id)})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user_serializer(user)

@app.put("/users/{user_id}")
def update_user(user_id: str, user: User):
    result = users_collection.update_one(
        {"_id": ObjectId(user_id)}, {"$set": user.dict()}
    )
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="User not found")
    updated_user = users_collection.find_one({"_id": ObjectId(user_id)})
    return user_serializer(updated_user)

@app.delete("/users/{user_id}")
def delete_user(user_id: str):
    result = users_collection.delete_one({"_id": ObjectId(user_id)})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="User not found")
    return {"message": "User deleted successfully"}
