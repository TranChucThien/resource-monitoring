
# FastAPI + MongoDB CRUD Backend

## 1. Run Backend (Docker Compose)

```bash
docker-compose up --build -d
````

The backend will run at: [http://localhost:8000](http://localhost:8000)
API docs: [http://localhost:8000/docs](http://localhost:8000/docs)

---

## 2. Test API with curl

### ➤ Create a new user

```bash
curl -X POST http://localhost:8000/users \
  -H "Content-Type: application/json" \
  -d '{"name": "Alice", "email": "alice@example.com"}'
```

---

### ➤ Get all users

```bash
curl http://localhost:8000/users
```

---

### ➤ Get user by ID

For example, with the sample user id `68da56f311ec75959ace5f49`:

```bash
curl http://localhost:8000/users/68da56f311ec75959ace5f49
```

---

### ➤ Update user

```bash
curl -X PUT http://localhost:8000/users/68da56f311ec75959ace5f49 \
  -H "Content-Type: application/json" \
  -d '{"name": "Alice Updated", "email": "alice.new@example.com"}'
```

---

### ➤ Delete user

```bash
curl -X DELETE http://localhost:8000/users/68da56f311ec75959ace5f49
```

---

## 3. Notes

* If the backend is not running on the same server as MongoDB, remember to update `MONGO_HOST` in `docker-compose.yml`.
* If testing from another machine, replace `localhost` with the backend server’s IP or hostname.


