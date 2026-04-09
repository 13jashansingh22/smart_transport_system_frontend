const express = require("express");
const cors = require("cors");

function parseAllowedOrigins(originsValue) {
  return originsValue
    .split(",")
    .map((origin) => origin.trim())
    .filter(Boolean);
}

function createApp() {
  const app = express();
  const allowedOrigins = parseAllowedOrigins(process.env.ALLOWED_ORIGINS || "");

  app.use(express.json());
  app.use(
    cors({
      origin: allowedOrigins.length > 0 ? allowedOrigins : true,
    })
  );

  app.get("/health", (_req, res) => {
    res.status(200).json({
      status: "ok",
      service: "smart-transport-backend",
      timestamp: new Date().toISOString(),
    });
  });

  app.get("/", (_req, res) => {
    res.status(200).json({
      message: "Smart Transport backend is running",
      docs: "See backend/README.md",
    });
  });

  return app;
}

module.exports = { createApp };

