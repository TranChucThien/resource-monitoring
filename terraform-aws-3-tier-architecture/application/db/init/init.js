db = db.getSiblingDB("crud_demo");   // tạo db crud_demo
db.createCollection("users");        // tạo collection users
db.users.insertMany([
  { "name": "David", "email": "david@example.com" },
  { "name": "Emma", "email": "emma@example.com" },
  { "name": "Frank", "email": "frank@example.com" }
]);
