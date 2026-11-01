# Academic Copilot

An AI-powered study workspace for Class 9–12 CBSE/ICSE students and JEE/NEET aspirants.
It combines a Gemini tutor, document-grounded Q&A, an intelligent study planner,
AI test generation, performance analytics and spaced-repetition revision in one
persistent local app.

Built as a full-stack project (React + FastAPI + SQLite) and documented for the
CBSE Class 12 Artificial Intelligence curriculum — see
[CBSE_PROJECT_GUIDE.md](CBSE_PROJECT_GUIDE.md) for the viva material.

---

## 1. What it actually does

| Module | Real behaviour |
| --- | --- |
| **Dashboard** | Study time, completed tasks, streak, accuracy, weekly area chart, subject donut, today's schedule with working "Done" buttons, upcoming exams, weakest chapters, recent documents — all computed from SQLite rows. |
| **AI Tutor** | Multi-turn chat with three explanation modes (simple / detailed / exam), subject context, document attachment, saved conversations you can reopen and delete. |
| **Study Materials** | PDF/TXT/Markdown upload, PyMuPDF text extraction, chunking + embeddings, page-level citations, in-document keyword search, AI chapter summary, key points, formulas and definitions. |
| **Study Planner** | Priority-scored weekly scheduling around exam dates, real capacity limits, breaks, revision and practice blocks. Tasks can be completed (which logs study time), edited, deleted, rescheduled, or added manually. |
| **Practice & Tests** | AI-generated MCQs, short/long answers and numericals, chapter-wise or mixed. Server-side grading, model answers, per-question explanations and topic breakdowns saved as attempts. |
| **Performance Analytics** | Real accuracy per subject and chapter, study minutes, task completion, score trend over time, strong/weak chapter detection, plus an explicitly-labelled AI interpretation (never a mark prediction). |
| **Smart Revision** | Flip-card sessions with easy/medium/hard ratings, an SM-2-inspired scheduler that changes the next due date, revision history, AI or custom cards, and weak-chapter recommendations. |
| **Settings** | Profile, AI connection management (masked key, model switch, test, disconnect), curriculum chapters, local storage counts, destructive "clear activity" with confirmation. |

Everything works without an AI key except the AI-dependent actions, which show a
clear "connect AI" state instead of pretending.

---

## 2. Stack

**Frontend** React 18 · TypeScript · Vite · Tailwind CSS v4 · Lucide icons · Recharts · React Router
**Backend** Python 3.12 · FastAPI · SQLAlchemy 2 · Pydantic v2 · SQLite
**AI** Google GenAI SDK (Gemini) — `gemini-2.5-flash` family, configurable
**Documents** PyMuPDF, OCR (optional Tesseract), Gemini embeddings with a BM25 fallback

No API key exists anywhere in the frontend, and all AI calls go through FastAPI.

---

## 3. Quick start

### Option A — one launcher

- **Windows:** double-click `run_windows.bat`
- **macOS / Linux:** `./run_unix.sh`

The script creates the virtualenv, installs dependencies and starts both servers.

### Option B — two terminals

```bash
# Terminal 1 — backend
cd backend
python -m venv .venv
.venv/Scripts/python -m pip install -r requirements.txt     # Windows
# source .venv/bin/activate && pip install -r requirements.txt   # macOS/Linux
python -m uvicorn app.main:app --reload --port 8000
```

```bash
# Terminal 2 — frontend
cd frontend
npm install
npm run dev
```

Open **http://127.0.0.1:5173**.

Requirements: Python 3.10+ and Node 18+ (Node 20/24 recommended). First run
creates `backend/data/academic_copilot.db` and seeds NCERT-style subjects plus a
small demo activity log (disable with `SEED_DEMO_DATA=false`).

### Production-style single port

```bash
cd frontend && npm run build      # outputs frontend/dist
cd ../backend && python -m uvicorn app.main:app --port 8000
```

FastAPI then serves the built SPA at http://127.0.0.1:8000 alongside `/api`.

---

## 4. Connecting Gemini (first launch)

1. Start the app. If no key is configured you get the **Welcome to Academic Copilot** screen.
2. Click **Get a free API key** → https://aistudio.google.com/apikey → create/copy a key.
3. Paste it, press **Connect AI**.

What happens server-side:

1. Input is validated (non-empty, plausible key length, no whitespace).
2. The backend tries a real `generateContent` request against a list of current
   models until one answers, so a missing/outdated model name is handled.
3. Only after a successful response is the key encrypted with Fernet (key file in
   `backend/data/`, SQLite stores the ciphertext) and the model recorded.
4. The frontend receives a **masked** key and status only, then opens the dashboard.

The key is never returned in full, never logged, never placed in `localStorage`,
and is encrypted at rest. Change / test / disconnect it later in **Settings → AI configuration**.
A key changed there is verified before it replaces the working one.

If Gemini is unavailable the dashboard, planner, tests already taken, documents and
revision cards keep working; AI buttons show connection errors instead of fake answers.

---

## 5. Configuration

Copy `backend/.env.example` to `backend/.env` **only if** you want file-based config.
You do not need it for normal use.

| Variable | Default | Purpose |
| --- | --- | --- |
| `GEMINI_MODEL` | `gemini-2.5-flash` | Preferred model; the setup flow falls back if unavailable |
| `GEMINI_EMBEDDING_MODEL` | `gemini-embedding-001` | Document embeddings |
| `GEMINI_API_KEY` | — | Optional alternative to in-app setup |
| `AI_TIMEOUT_MS` | `60000` | Gemini request timeout |
| `DATABASE_URL` | `sqlite:///<abs path>/backend/data/academic_copilot.db` | Database location |
| `SEED_CURRICULUM` | `true` | Load subject/chapter reference data |
| `SEED_DEMO_DATA` | `true` | Load the demo activity log once |
| `MIN_RETRIEVAL_SCORE` | `0.28` | Minimum similarity to use a passage |
| `CORS_ORIGINS` | localhost:5173 | Allowed dev origins |

---

## 6. Project structure

```
academic-copilot/
├── backend/
│   ├── app/
│   │   ├── ai/            provider.py (Gemini + error mapping), prompts.py, tasks.py
│   │   ├── api/
│   │   │   ├── deps.py
│   │   │   └── routes/    dashboard, tutor, documents, planner, tasks, exams,
│   │   │                  tests, analytics, revision, subjects, settings, ai
│   │   ├── database/      db.py, seed.py
│   │   ├── models/        models.py (14 tables)
│   │   ├── rag/           extractor.py, index.py (chunking + hybrid retrieval)
│   │   ├── schemas/       schemas.py (validation)
│   │   ├── services/      ai_config.py, analytics.py, planner.py, spaced_repetition.py
│   │   ├── config.py
│   │   └── main.py
│   ├── requirements.txt
│   └── .env.example
├── frontend/
│   ├── src/
│   │   ├── components/    ui.tsx, Sidebar.tsx, Markdown.tsx
│   │   ├── context/       AppContext, ToastContext
│   │   ├── hooks/         useAsync.ts
│   │   ├── layouts/       AppLayout.tsx
│   │   ├── lib/           api.ts, types.ts, format.ts
│   │   └── pages/         Dashboard, Tutor, Materials, Planner, Practice,
│   │                      Analytics, Revision, Settings, Setup
│   └── package.json
├── uploads/               stored study PDFs
├── run_windows.bat / run_unix.sh
├── CBSE_PROJECT_GUIDE.md
└── README.md
```

---

## 7. Database schema

| Table | Purpose |
| --- | --- |
| `students` | Local profile (name, class, target exam, daily hours) |
| `app_settings` | Encrypted Gemini key, model, verification timestamp |
| `subjects`, `chapters` | Curriculum with difficulty 1–5 |
| `study_tasks` | Planned study / revision / practice / break blocks |
| `exams` | Exam dates + syllabus used by the planner |
| `study_sessions` | Logged minutes (created when a task is completed) |
| `documents`, `document_chunks` | Uploaded material, extracted text, embeddings |
| `chat_conversations`, `chat_messages` | Tutor history, mode, grounding, citations |
| `test_attempts`, `questions` | Generated tests, answers, marks, per-question correctness |
| `flashcards`, `revision_history` | Spaced repetition state and review log |

All tables use primary keys, foreign keys with cascade rules and timestamps.

---

## 8. How the AI layer works

- **Modular provider** — `app/ai/provider.py` is the only place that talks to Gemini,
  so another provider could be added behind the same interface.
- **Prompted tasks** — tutor, document answers, summaries, question generation,
  flashcards and analytics advice each have a dedicated prompt in `prompts.py`.
- **Validated output** — JSON responses are parsed defensively and checked
  (MCQ options must contain the correct answer, flashcards need both sides,
  duplicates are dropped). Bad output becomes a retryable error, never garbage UI.
- **Grounded document answers** — retrieval happens before generation:
  1. PyMuPDF extracts text page by page (empty pages are flagged as scanned; OCR
     runs only if Tesseract is installed).
  2. Text is chunked (~1,100 characters with overlap).
  3. Chunks are embedded with Gemini `embedContent` and stored as JSON vectors.
  4. A question is scored with **0.7 × cosine similarity + 0.3 × BM25**, and only
     passages above the threshold are sent to the model with page numbers.
  5. If nothing relevant is found, the response is explicitly labelled as general
     knowledge — the app never implies the PDF said something it did not.
- **Embedding fallback** — if embedding calls fail, retrieval still works with BM25
  alone, so uploaded documents remain searchable.
- **Error mapping** — invalid key, permission, model-not-found, quota/rate limit,
  timeout, network and safety blocks each produce a specific, readable message.

---

## 9. Planner and revision algorithms (not "machine learning")

These are deliberately transparent, explainable heuristics:

- **Planner** scores each chapter with exam proximity, syllabus match, difficulty,
  whether it has been studied and past accuracy. It then fills each day up to the
  student's available hours in 50-minute blocks, inserts breaks, reserves one
  revision block for weak chapters and a practice block every other day. Anything
  that does not fit is reported as a warning instead of being silently crammed in.
- **Revision** is an SM-2-inspired scheduler: `hard` resets the interval to one day
  and lowers ease, `medium` grows it moderately, `easy` grows it fastest (capped at
  180 days). Every rating is stored in `revision_history`.
- **Analytics** uses descriptive statistics over stored rows. The only generative part
  is the clearly-labelled mentor commentary, which is fed the real numbers and is
  told not to invent anything.

---

## 10. API surface (main routes)

```
GET    /api/dashboard
GET    /api/ai/status            POST /api/ai/connect
POST   /api/ai/test              POST /api/ai/model        POST /api/ai/disconnect

GET    /api/tutor/conversations  POST /api/tutor/conversations
GET    /api/tutor/conversations/{id}   DELETE ...
POST   /api/tutor/chat

GET    /api/documents            POST /api/documents  (multipart)
GET    /api/documents/{id}       PATCH/DELETE /api/documents/{id}
GET    /api/documents/{id}/file  GET /api/documents/{id}/search
POST   /api/documents/{id}/summary     POST /api/documents/ask

GET    /api/planner/overview     POST /api/planner/generate
POST   /api/planner/reschedule   GET/POST /api/tasks, /api/tasks/{id}/complete
GET    /api/tasks/week           GET/POST /api/exams

GET    /api/tests                POST /api/tests/generate
GET    /api/tests/{id}           POST /api/tests/{id}/submit

GET    /api/analytics/overview   POST /api/analytics/recommendations
GET    /api/revision/overview    GET/POST /api/revision/cards
POST   /api/revision/cards/generate     POST /api/revision/cards/{id}/review

GET/PATCH /api/settings/profile  POST /api/settings/clear-activity
GET    /api/subjects             POST /api/subjects/{id}/chapters
```

Interactive docs are at http://127.0.0.1:8000/docs while the backend runs.

---

## 11. Verification performed

Run by the author on Windows 11, Python 3.12, Node 24:

- Backend import, table creation and demo seeding tested from a clean database.
- Every GET endpoint returns 200 with real data; dashboard numbers recompute after
  a task is completed and after it is reopened.
- PDF upload → extraction → chunking → in-document search verified with a generated
  PDF; a corrupt upload is rejected with a readable 400 and leaves no record behind.
- Task create / edit / complete / reopen / delete, exam CRUD (including partial PATCH),
  chapter CRUD, flashcard create / review / delete and profile update verified over HTTP.
- Test submission graded end-to-end: a 3-question mixed attempt scored 5/5 with per-question
  correctness and a chapter topic breakdown; a second attempt with one blank question scored
  1/2 and reported one unanswered.
- Spaced repetition verified by rating the same card easy then hard: the next due date
  moved from +4 days to +1 day.
- A task created through the API survived a full backend restart, then deleted cleanly.
- Planner generation tested with 7 days × 3 h: it respects the hour cap, inserts
  breaks, and reports the chapters that do not fit rather than overfilling days.
- First-run setup exercised in the browser: with no key the setup screen appears; a fake
  key is rejected by the live Gemini call with a human-readable message and nothing saved;
  "Explore without AI" opens the dashboard with an offline banner and working local data.
- Invalid input returns 422, missing chapter returns 404, missing key returns 409
  with a readable message; a rejected fake key leaves configuration untouched.
- `npm run build` and `tsc --noEmit` pass; all nine routes were walked in a browser
  with no console errors.

**Not verified here:** a successful live Gemini response — that requires your own
API key. Paste it into the app's setup screen; the backend reports the exact Gemini
error if something is wrong with the key or quota.

---

## 12. Known limitations (stated honestly)

1. **One local student profile.** No multi-user accounts; the database and uploads
   live on this machine. That is intentional for a school project.
2. **OCR is optional.** Scanned PDFs are detected and clearly flagged; automatic OCR
   only happens if Tesseract is installed and on `PATH`.
3. **Subjective grading is approximate.** MCQs and numericals are exact; short/long
   answers are checked against key terms in the model answer and always show the model
   answer for self-review.
4. **AI answers can be wrong.** The UI says so, document answers are grounded and
   cited, and nothing claims predicted marks.
5. **Embedding storage is SQLite JSON + numpy cosine.** Great for one student's
   library; a production deployment with thousands of documents would move to a
   dedicated vector store.
6. **Demo data.** A fresh install includes seeded activity so every chart is populated.
   Turn it off with `SEED_DEMO_DATA=false` or clear it in Settings.

---

## 13. Troubleshooting

| Symptom | Fix |
| --- | --- |
| "Backend not reachable" | Start uvicorn on port 8000; check the terminal for import errors |
| "Gemini rejected this API key" | Re-copy the key from AI Studio; remove spaces; ensure the Gemini API is enabled |
| "Rate limit or quota reached" | Wait a minute or check your Google AI Studio quota |
| Model errors | Pick another model in Settings → AI configuration |
| Upload says "scanned" | The PDF has no text layer; use a text-based PDF or install Tesseract |
| Port already in use | `--port 8001` for the backend and update the Vite proxy in `frontend/vite.config.ts` |

---

## 14. Credits

Design language inspired by the supplied dark dashboard references (sidebar
navigation, violet active state, card-based grids, muted charts). Stack: React,
Tailwind, Recharts, Lucide, FastAPI, SQLAlchemy, Google Gemini.
