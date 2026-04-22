# OmniTriage 🚨

> From chaos to action. In seconds.

An AI-powered field-to-action orchestration engine for grassroots NGOs.

## 📖 What it does

OmniTriage converts unstructured field reports (handwritten photos, voice notes, mixed text) into structured JSON via Gemini 1.5 Flash, then autonomously dispatches the nearest skill-matched volunteers via Telegram.

## 🌐 Live Demo

- **Dashboard**: `https://akankchaproject.web.app`
- **Telegram Bot**: `@OmniTriageBot`
- **Demo Video**: `[Insert YouTube Link Here]`

## 🏗️ Architecture

[Field Worker] → Telegram → Cloud Function → Gemini 1.5 Flash
↓
Firestore Tasks
↓
[Dispatch Function] → Volunteer Telegram
↓
Flutter Web Dashboard (real-time)

## 🛠️ Tech Stack

| Component                | Technology                                |
| ------------------------ | ----------------------------------------- |
| **AI Extraction Engine** | Gemini 1.5 Flash (Google AI Studio)       |
| **Real-time Database**   | Firebase Firestore                        |
| **Serverless Backend**   | Firebase Cloud Functions (local emulator) |
| **Dashboard Hosting**    | Firebase Hosting                          |
| **Field Interface**      | Telegram Bot API                          |
| **Coordinator UI**       | Flutter Web                               |
| **Tunnel (dev)**         | ngrok                                     |

## 🚀 Local Setup & Flawless Execution Guide

_Architectural Note: To guarantee absolute reliability during high-stakes live demos and bypass local emulator environment variable loading issues, this MVP utilizes direct key injection. API keys are strictly quarantined before any Git commits._

### 1. Clone & Install

```bash
git clone [https://github.com/YOURUSERNAME/omnitriage.git](https://github.com/YOURUSERNAME/omnitriage.git)
cd omnitriage
cd functions && npm install
cd ../dashboard && flutter pub get
```
