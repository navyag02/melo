# MELO 🧠

**AI-Based Cognitive Gaming and Memory Assistance Platform for Elderly Dementia Patients in North Eastern Region (NER)**

Built for **Smart India Hackathon (SIH) 2026 — Problem Statement 26003**
Organization: Ministry of Development of North Eastern Region (MDoNER)
Category: Software

---

## 🎯 Problem Statement

The North Eastern Region is seeing a rise in age-related cognitive disorders like dementia among the elderly, with limited access to specialized neurological care due to healthcare infrastructure gaps and geographical barriers. Patients experience memory decline and social isolation, while caregivers struggle with continuous monitoring.

## 💡 Our Solution

Melo is a culturally-rooted cognitive care platform — **designed for NER, not adapted to it**. Instead of generic memory games with translated labels, our games are woven from regional folklore, festivals, and daily life, paired with an explainable AI engine that adapts difficulty in real time and guides caregivers on what to play next.

### ✨ USP

Culturally-rooted cognitive care built specifically for NER — games woven from regional folklore, festivals, and daily life, not generic content with translated labels — powered by an AI engine that adapts difficulty in real time and recommends how sessions should be adjusted based on the patient's performance

---

## 🕹️ Features

### Built (Prototype)
- **Memory Matching Game** — NER-culturally-themed card matching (Bihu, Hornbill, bamboo craft, tea gardens, living root bridges, regional textiles)
- **Adaptive Difficulty Engine** — Rule-based logic that adjusts game difficulty (easy/medium/hard) based on the patient's last 2–3 sessions, with plain-language explanations shown to the patient (e.g., "Next round will be a bit harder")
- **Caregiver Dashboard** — Session history, accuracy trends over time, and a simple AI-generated recommendation (e.g., "Recommend: Easier sessions, more frequent practice")
- **Reminders** — Basic medicine/activity reminder with on-device notifications
- **Elderly-Friendly UI** — Large text, large tap targets, high-contrast, minimal-clutter design

### Roadmap (Planned for SIH Nationals)
- Voice-enabled multilingual interface
- Offline synchronization for low-connectivity areas
- Secure patient data management (encryption, DPDP Act compliance)
- Caregiver alert system (missed session/medicine notifications)
- Additional games covering attention, daily-routine recall, and pattern recognition
- Broader regional language and cultural coverage across NER states

---

## 🎯 Cognitive Domains Targeted

| Domain | Approach |
|---|---|
| Memory improvement | Memory matching game |
| Pattern & object recognition | Pattern-based card matching |
| Attention & concentration | Planned: spot-the-difference game |
| Daily routine recall | Planned: sequence-ordering game |
| Emotional & mental engagement | Achieved through culturally familiar theming across all games |

---

## 🛠️ Tech Stack

- **Frontend:** Flutter
- **Backend:** Firebase (Firestore + Authentication)
- **Notifications:** flutter_local_notifications
- **Charts:** fl_chart (or similar)

---

## 📊 Data Model (Firestore)

**`users`**
```
{ patientId, name, preferredLanguage }
```

**`sessions`**
```
{ patientId, gameType, accuracy, timeTakenSeconds, movesCount, difficultyLevel, timestamp }
```

**`reminders`**
```
{ patientId, title, time, isActive }
```

---

## 👥 Team

| Role | Focus |
|---|---|
| Game UI & Logic | Memory matching game development |
| Firebase Integration | Firestore data flow, session tracking |
| Regional Theming & Dashboard UI | Cultural content, caregiver dashboard |
| PPT & Demo | Pitch narrative, slide deck, demo prep |

---

## 📌 Status

Prototype built for the internal SIH hackathon round. Core game, adaptive difficulty, caregiver dashboard, and reminders are functional. Voice, offline sync, and advanced security are planned for the national round in December.