import express from "express";
import session from "express-session";
import axios from "axios";
import { readFileSync } from "fs";
import { join, dirname } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const PORT = process.env.PORT || 3001;
const PIN = process.env.DASHBOARD_PIN || "2006";
const EVOLUTION_API = process.env.EVOLUTION_API_URL || "http://api:8080";
const EVOLUTION_KEY = process.env.EVOLUTION_API_KEY || "";

const app = express();

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(
  session({
    secret: process.env.SESSION_SECRET || "evolution-secret-change-me",
    resave: false,
    saveUninitialized: false,
    cookie: { maxAge: 24 * 60 * 60 * 1000 },
  })
);

function requireAuth(req, res, next) {
  if (!req.session.authenticated) {
    return res.redirect("/login");
  }
  next();
}

const api = axios.create({
  baseURL: EVOLUTION_API,
  headers: { apikey: EVOLUTION_KEY },
});

// --- Auth routes ---
app.get("/login", (req, res) => {
  res.sendFile(join(__dirname, "public", "login.html"));
});

app.post("/api/login", (req, res) => {
  if (req.body.pin === PIN) {
    req.session.authenticated = true;
    return res.json({ success: true });
  }
  res.status(401).json({ success: false, error: "Invalid PIN" });
});

app.post("/api/logout", (req, res) => {
  req.session.destroy();
  res.json({ success: true });
});

// --- API proxy routes ---
app.get("/api/status", requireAuth, async (req, res) => {
  try {
    const { data } = await api.get("/");
    res.json({ status: "ok", version: data.version, manager: data.manager });
  } catch {
    res.status(502).json({ status: "error", message: "Evolution API unreachable" });
  }
});

app.get("/api/instances", requireAuth, async (req, res) => {
  try {
    const { data } = await api.get("/instance/fetchInstances");
    res.json(data);
  } catch {
    res.json([]);
  }
});

app.post("/api/instance/create", requireAuth, async (req, res) => {
  try {
    const { instanceName } = req.body;
    await api.post("/instance/create", {
      instanceName,
      integration: "WHATSAPP-BAILEYS",
      qrcode: false,
    });
    res.json({ success: true, instanceName });
  } catch (err) {
    const msg = err.response?.data?.response?.message || err.message;
    res.status(400).json({ success: false, error: msg });
  }
});

app.get("/api/instance/connect", requireAuth, async (req, res) => {
  try {
    const { instanceName, number } = req.query;
    const { data } = await api.get(`/instance/connect/${instanceName}`, {
      params: { number },
    });
    res.json(data);
  } catch (err) {
    console.error("Connect error:", err.response?.status, err.response?.data || err.message);
    const msg = err.response?.data?.response?.message || err.message;
    res.status(400).json({ success: false, error: msg });
  }
});

app.get("/api/instance/state/:instanceName", requireAuth, async (req, res) => {
  try {
    const { data } = await api.get(`/instance/connectionState/${req.params.instanceName}`);
    res.json(data);
  } catch {
    res.json({ state: "unknown" });
  }
});

app.get("/api/instance/info/:instanceName", requireAuth, async (req, res) => {
  try {
    const { data } = await api.get(`/instance/findInstance/${req.params.instanceName}`);
    res.json(data);
  } catch {
    res.json(null);
  }
});

app.delete("/api/instance/delete/:instanceName", requireAuth, async (req, res) => {
  try {
    await api.delete(`/instance/delete/${req.params.instanceName}`);
    res.json({ success: true });
  } catch (err) {
    res.status(400).json({ success: false, error: err.message });
  }
});

app.get("/api/instance/qrcode/:instanceName", requireAuth, async (req, res) => {
  try {
    const { data } = await api.get(`/instance/connect/${req.params.instanceName}`);
    res.json(data);
  } catch {
    res.json(null);
  }
});

app.post("/api/message/send", requireAuth, async (req, res) => {
  try {
    const { instanceName, number, text } = req.body;
    const { data } = await api.post(`/message/sendText/${instanceName}`, {
      number,
      text,
    });
    res.json(data);
  } catch (err) {
    res.status(400).json({ success: false, error: err.message });
  }
});

app.get("/api/settings", requireAuth, (req, res) => {
  res.json({
    apiUrl: EVOLUTION_API,
    apiKey: EVOLUTION_KEY,
    hasKey: !!EVOLUTION_KEY,
  });
});

// Serve frontend
app.use(express.static(join(__dirname, "public")));
app.get("/", requireAuth, (req, res) => {
  res.sendFile(join(__dirname, "public", "dashboard.html"));
});

app.listen(PORT, () => {
  console.log(`Dashboard running on port ${PORT}`);
});
