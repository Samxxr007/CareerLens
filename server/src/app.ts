import express from "express";
import cors from "cors";
import { apiRouter } from "./routes/api.routes.js";

export const app = express();

app.use(cors());
app.use(express.json({ limit: "5mb" }));

// Mount API routes under /api
app.use("/api", apiRouter);

// Fallback 404
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: {
      code: "NOT_FOUND",
      message: `Endpoint ${req.method} ${req.url} does not exist.`
    }
  });
});
