import express from "express";
import path from "path";
import { fileURLToPath } from "url";
import apiRouter from "./routes/api.js";
import cors from "cors";

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use("/api", apiRouter); //api 라우터 사용

// app.get("/", (req, res) => {
//   const __filename = fileURLToPath(import.meta.url);
//   const __dirname = path.dirname(__filename);
//   res.sendFile(path.join(__dirname + "/assets/week2.html"), (err) => {
//     if (err) {
//       res.status(err.status).end();
//     }
//   });
// });

app.listen(3000, () => {
  console.log("Server is running on port 3000");
});
