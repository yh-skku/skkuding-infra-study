import express from "express";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import os from "os";
import cors from "cors";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const filePath = path.join(__dirname, "../assets/users.json");
const router = express.Router();
router.use(express.json()); //api 헤더가 json일 때
router.use(express.urlencoded({ extended: true })); // api 헤더가 form일 때
router.use(cors()); // CORS 미들웨어 사용

router.post("/signup", (req, res) => {
  const { username, password, email } = req.body;
  console.log(username, password, email);

  try {
    const data = fs.readFileSync(filePath, "utf-8");
    let users = JSON.parse(data);
    users.push({ username, password, email });
    fs.writeFileSync(filePath, JSON.stringify(users, null, 2));
    res.status(201).send("User created");
  } catch (err) {
    res.status(500).send("Error writing file");
  }
});

router.get("/users", (req, res) => {
  const data = fs.readFile(filePath, "utf-8", (err, data) => {
    if (err) {
      console.error(err);
      res.status(500).send("Error reading file");
      return;
    }
    try {
      const users = JSON.parse(data);
      console.log(users);
      res.send(users);
    } catch (parseError) {
      console.error(parseError);
      res.status(500).send("Error parsing JSON");
    }
  });
});

router.post("/login", (req, res) => {
  fs.readFile(filePath, "utf-8", (err, data) => {
    if (err) {
      console.error(err);
      res.status(500).send("Error reading file");
      return;
    }
    try {
      const users = JSON.parse(data);
      const { username, password, email } = req.body;
      // users.forEach((user) => {
      //   console.log(user);
      //   if (user.username === username && user.password === password) {
      //     res.status(200).send("Login successful");
      //     return;
      //   }
      // });
      const user = users.find(
        (user) => user.username === username && user.password === password
      );

      if (user) {
        return res.status(200).send("Login successful");
      }
      res.status(401).send("Login failed");
    } catch (parseError) {
      console.error(parseError);
      res.status(500).send("Error parsing JSON");
    }
  });
});

router.get("/os", (req, res) => {
  try {
    const osInfo = {
      type: os.type(),
      hostname: os.hostname(),
      cpu_num: os.cpus().length,
      total_mem: Math.floor(os.totalmem() / 1024 / 1024) + " MB",
    };
    res.send(osInfo);
  } catch (err) {
    console.error(err);
    res.status(500).send("Error getting OS info");
    return;
  }
});

export default router;
