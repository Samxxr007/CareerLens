import dotenv from "dotenv";
dotenv.config();

export const config = {
  port: parseInt(process.env.PORT || "3001", 10),
  rPlumberUrl: process.env.R_PLUMBER_URL || "http://127.0.0.1:8001",
  env: process.env.NODE_ENV || "development",
  groqApiKey: process.env.GROQ_API_KEY || ""
};
