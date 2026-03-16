// ===============================
// REQUIRED MODULES
// ===============================
const express = require("express");
const cors = require("cors");
const { SerialPort } = require("serialport");
const { ReadlineParser } = require("@serialport/parser-readline");
const WebSocket = require("ws");

// ===============================
// SERVER SETUP
// ===============================
const app = express();
app.use(cors());

const PORT = 5000;

// ===============================
// CHANGE TO YOUR ARDUINO PORT
// ===============================
const ARDUINO_PORT = "COM4";

// ===============================
// SERIAL CONNECTION
// ===============================
const serial = new SerialPort({
  path: ARDUINO_PORT,
  baudRate: 9600,
});

const parser = serial.pipe(new ReadlineParser({ delimiter: "\n" }));

console.log("📡 Listening to Arduino on", ARDUINO_PORT);

// ===============================
// STORE LATEST VALUE
// ===============================
let latestValue = 0;

// ===============================
// WEBSOCKET SERVER
// ===============================
const server = app.listen(PORT, () => {
  console.log("🚀 Server running on http://localhost:" + PORT);
});

const wss = new WebSocket.Server({ server });

let clients = [];

wss.on("connection", (ws) => {
  console.log("📱 Flutter connected");

  clients.push(ws);

  ws.on("close", () => {
    clients = clients.filter((c) => c !== ws);
    console.log("❌ Flutter disconnected");
  });
});

// ===============================
// RECEIVE DATA FROM ARDUINO
// ===============================
parser.on("data", (data) => {
  try {
    const line = data.trim();

    const match = line.match(/\d+/);
    if (!match) return;

    const value = parseFloat(match[0]);
    if (isNaN(value)) return;

    latestValue = value;

    console.log("GSR:", latestValue);

    // 🔴 SEND TO ALL WEBSOCKET CLIENTS
    const message = JSON.stringify({ value: latestValue });

    clients.forEach((client) => {
      if (client.readyState === WebSocket.OPEN) {
        client.send(message);
      }
    });

  } catch (err) {
    console.error("Serial parse error:", err);
  }
});

// ===============================
// OPTIONAL HTTP ENDPOINT
// ===============================
app.get("/gsr", (req, res) => {
  res.json({ value: latestValue });
});

// ===============================
// SERIAL ERROR HANDLING
// ===============================
serial.on("error", (err) => {
  console.error("Serial Port Error:", err.message);
});