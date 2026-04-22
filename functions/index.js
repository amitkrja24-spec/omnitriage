"use strict";

const admin = require("firebase-admin");

// Initialize Firebase Admin — connects to real Firestore
// Uses serviceAccountKey.json when running locally via emulator
if (!admin.apps.length) {
  try {
    const serviceAccount = require("./serviceAccountKey.json");
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: "akankchaproject", ////////////////////////////////////////////////////////////////////////////// HARDCODED PROJECT ID
    });
    console.log("Firebase Admin initialized with service account");
  } catch (e) {
    // Fallback for deployed environment (service account auto-detected)
    admin.initializeApp();
    console.log(
      "Firebase Admin initialized with application default credentials",
    );
  }
}

const functions = require("firebase-functions/v1");
const { handleTelegramWebhook } = require("./src/parseInput");
const { dispatchVolunteers } = require("./src/dispatchVolunteers");

// ── HTTP TRIGGER: Telegram Webhook ────────────────────────────────
exports.telegramWebhook = functions.https.onRequest(async (req, res) => {
  res.status(200).json({ ok: true });
  if (req.body && req.body.message) {
    try {
      await handleTelegramWebhook(req.body);
    } catch (err) {
      console.error("Webhook handler error (non-fatal):", err);
    }
  }
});

// ── FIRESTORE TRIGGER: Auto-dispatch when task created ────────────
exports.onTaskCreated = functions.firestore
  .document("tasks/{taskId}")
  .onCreate(async (snap, context) => {
    const task = snap.data();
    const taskId = context.params.taskId;

    if (
      !task.needs_review &&
      task.confidence_score >= 0.8 &&
      task.status === "open"
    ) {
      console.log(`Auto-dispatching task ${taskId}`);
      await dispatchVolunteers(taskId, task);
    } else {
      console.log(
        `Task ${taskId} not auto-dispatched (confidence: ${task.confidence_score})`,
      );
    }
  });

// ── HTTP TRIGGER: Manual dispatch from dashboard ──────────────────
exports.manualDispatch = functions.https.onRequest(async (req, res) => {
  // CORS Headers to allow live dashboard to connect
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, ngrok-skip-browser-warning');
  if (req.method === 'OPTIONS') {
    return res.status(204).send('');
  }
  const { taskId } = req.body;
  if (!taskId) return res.status(400).json({ error: "taskId required" });

  try {
    const taskSnap = await admin
      .firestore()
      .collection("tasks")
      .doc(taskId)
      .get();
    if (!taskSnap.exists)
      return res.status(404).json({ error: "Task not found" });

    const task = taskSnap.data();
    if (task.status === "dispatching" || task.status === "assigned") {
      return res
        .status(200)
        .json({ message: "Already dispatched", status: task.status });
    }

    await dispatchVolunteers(taskId, task);
    res.status(200).json({ success: true, taskId });
  } catch (err) {
    console.error("manualDispatch error:", err);
    res.status(500).json({ error: err.message });
  }
});

// ── HTTP TRIGGER: Check timeouts (run manually or periodically) ───
exports.checkTimeouts = functions.https.onRequest(async (req, res) => {
  const { checkDispatchTimeouts } = require("./src/dispatchVolunteers");
  try {
    const result = await checkDispatchTimeouts();
    res.status(200).json({ success: true, ...result });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
