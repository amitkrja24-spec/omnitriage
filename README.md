# 🚑 OmniTriage: Autonomous AI Crisis Coordination

OmniTriage is a fully serverless, AI-powered emergency response and volunteer dispatch platform. Designed for NGOs and field workers, it eliminates manual data entry by using multimodal AI (Google Gemini 2.5 Flash) to instantly read handwritten field reports, voice notes, and text messages, automatically routing the right volunteers to the right locations in seconds.

## 🚀 Live Demonstration

- **Coordinator Dashboard (Web):** [https://omnitriage-prod.web.app](https://omnitriage-prod.web.app)
- **Field Worker Interface (Telegram):** [@OmniTriageBot](https://t.me/OmniTriageBot)
- **DEMO VIDEO(YT LINK ):** https://youtu.be/bW7oHO53UD4

_(Note: To test the system, message the bot `/register` to become a volunteer, or simply type an emergency scenario like "3 people need medical help in Ward 4" to see it instantly appear on the dashboard.)_

---

## 🏗️ System Architecture

OmniTriage is built on a 100% cloud-native, serverless architecture to ensure zero downtime during high-traffic crisis events.

- **The Brain (AI & Logic):** Google Cloud Functions (Node.js) + Google Gemini 2.5 Flash.
- **The Memory (Database):** Firebase Cloud Firestore for real-time state synchronization.
- **The Face (Dashboard):** Flutter Web, deployed globally via Firebase Hosting.
- **The Mouth (Field Comms):** Telegram API via Cloud Webhooks (Zero-polling architecture).

---

## ✨ Key Features

### 1. Multimodal AI Ingestion

Field workers don't have time to fill out complex web forms. They simply send a message to the Telegram bot using whatever medium is easiest:

- **Text & Hinglish:** Type directly in regional languages or Hinglish.
- **Voice Notes:** Send audio recordings from the field.
- **Photos of Registers:** Take a picture of a handwritten notebook or survey form.
- _The system instantly extracts: Location, Urgency (1-5), Need Type, and Required Skills._

### 2. Autonomous Volunteer Onboarding

Volunteers can self-register instantly by sending `/register` to the bot. The system captures their details and adds them to the live dispatch grid without any manual approval bottlenecks.

### 3. Smart Dispatch System

Once an emergency is verified by the AI:

- **Auto-Dispatch:** High-confidence tasks automatically ping the nearest available volunteers via Telegram.
- **Manual Dispatch:** Coordinators can oversee low-confidence tasks and manually trigger dispatch from the live web dashboard.

### 4. Real-Time Coordinator Dashboard

A Flutter-based command center that tracks active tasks, volunteer availability, and field metrics in real-time using Firestore snapshot listeners.

---

## 🛠️ Tech Stack

- **Frontend:** Flutter (Dart)
- **Backend:** Node.js, Express, Firebase Admin SDK
- **Cloud Infrastructure:** Google Cloud Platform (GCP), Firebase Blaze Plan
- **Artificial Intelligence:** Google Gemini API (`gemini-2.5-flash`)
- **Integrations:** Telegram Bot API (Webhook mode)

---

## ⚙️ How It Works (The Lifecycle)

1. **Signal:** A field worker sends a voice note, photo, or text to the Telegram bot.
2. **Intercept:** Google Cloud Functions catches the webhook instantly. To prevent serverless timeouts, the bot immediately replies: _"🚨 Emergency received. AI is analyzing..."_
3. **Analyze:** The payload is sent to Gemini 2.5 Flash, which structures the unstructured data into a standardized JSON schema.
4. **Store & Sync:** The JSON is written to Firestore, instantly updating the live Coordinator Dashboard.
5. **Dispatch:** The system queries the `volunteers` collection and fires off Telegram alerts to active workers with matching skills.

---

_Built for the Google Solution Challenge 2026 India._
