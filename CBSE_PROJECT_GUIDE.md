# Academic Copilot — CBSE Class 12 AI Project Guide

This document is the written report and viva preparation for the **Academic Copilot**
project. It explains the problem, the AI concepts actually implemented, how the
system was built, what was tested, and how to demonstrate it.

---

## 1. Project title

**Academic Copilot — an AI-powered student learning platform for planning studies,
solving doubts, practising tests and revising with spaced repetition.**

Category: *AI-powered productivity / education assistant*.

---

## 2. Problem statement

Students in Classes 9–12 preparing for boards or JEE/NEET commonly face:

1. **Poor planning** — no idea what to study today, so they study what feels easy.
2. **Doubt piles** — no teacher available late at night; doubts are skipped.
3. **Textbook search pain** — finding a specific definition inside a 300-page PDF.
4. **Ineffective practice** — repeating the same easy questions.
5. **Unknown weak areas** — they cannot say which chapter is actually weak.
6. **Forgetting** — one revision before the exam is not enough.

Existing apps solve one of these. Academic Copilot integrates them into one
workspace where **the data from one module improves the others** (test accuracy
changes the plan, weak chapters get revision cards, document questions are cited).

---

## 3. Objectives

| # | Objective | Delivered as |
| --- | --- | --- |
| 1 | Personal dashboard from real data | Dashboard module |
| 2 | AI doubt-solving with adjustable depth | AI Tutor (simple / detailed / exam) |
| 3 | Retrieve answers from the student's own PDFs | RAG pipeline + citations |
| 4 | Automatic scheduling around exams | Intelligent Study Planner |
| 5 | Generate and grade practice tests | Practice & Tests |
| 6 | Identify weak chapters from performance | Performance Analytics |
| 7 | Schedule revision scientifically | Smart Revision (SM-2 inspired) |
| 8 | Keep everything persistent and private | SQLite + local files |
| 9 | Set up AI with no code editing | First-run Gemini key workflow |

---

## 4. How this maps to the CBSE AI curriculum

### 4.1 AI Project Cycle

| Stage | What was done here |
| --- | --- |
| **Problem scoping** | 4W canvas: *Who* — Class 9–12 students; *What* — scattered study tools and no feedback loop; *Where* — at home/self-study; *Why* — wasted time and repeated mistakes. |
| **Data acquisition** | Student-generated data (tasks, sessions, attempts, ratings), curriculum reference data (NCERT chapter lists), uploaded PDFs. No scraping of personal data. |
| **Data exploration** | Analytics module: accuracy per chapter, minutes per day, completion rate, score trend — the same totals students would compute in a spreadsheet. |
| **Modelling** | Gemini generation/embeddings for language tasks; transparent algorithms (priority scoring, spaced repetition) for scheduling; vector similarity + BM25 for retrieval. |
| **Evaluation** | Measured by correctness of grading, citation accuracy, duplicate-question rejection, plan feasibility warnings, and manual review of answers. |
| **Deployment** | FastAPI backend + React frontend running locally; single-port production build; README with setup. |

### 4.2 AI concepts genuinely used

1. **Natural Language Processing (NLP)**
   - Tokenisation and normalisation for BM25 keyword retrieval and for grading
     subjective answers.
   - Text extraction, cleaning and chunking of PDF pages.
   - Prompt engineering with system instructions, role framing and output constraints.

2. **Generative AI / Large Language Models**
   - Gemini generates explanations, summaries, questions, flashcards and feedback.
   - Three modes change the prompt's instruction (beginner / complete / exam).
   - **Structured output**: JSON-mode responses parsed and validated by Pydantic-driven
     logic, with duplicate removal.

3. **Retrieval-Augmented Generation (RAG)**
   - Documents are chunked, embedded and stored.
   - A question is embedded and compared with chunks using cosine similarity,
     blended with BM25 (0.7 / 0.3).
   - Only retrieved passages are sent to the model; answers must cite `[p. N]`;
     if retrieval fails, the answer is labelled **general knowledge**.
   - This is what stops the model from hallucinating about "your textbook".

4. **Machine-learning-adjacent concepts (used correctly, not mislabelled)**
   - **Embeddings** are learned vector representations from a neural model; cosine
     similarity is the distance metric.
   - **Spaced repetition** is an adaptive scheduling algorithm driven by feedback
     (an SM-2 variant), not a trained model.
   - **Rule-based personalisation**: priority scoring, exam deadlines, accuracy
     thresholds. It is described as rule-based in the UI and report, not as ML.
   - No supervised classifier is trained, so the project does not claim one.

5. **Data analysis and visualisation**
   - Descriptive statistics (accuracy = correct / attempted), trends, per-topic
     breakdowns, study-minute aggregation.
   - Charts with Recharts; explicitly separates **observed** data from **AI advice**.

6. **Recommendation systems**
   - Content-based recommendation: chapters with low accuracy and high difficulty
     are recommended for revision; the planner reorders chapters using exam
     proximity and past performance.
   - The AI mentor converts these features into natural-language priorities.

7. **Responsible AI**
   - No fake answers when the model is unavailable.
   - Grounding and citation rules; separate "general knowledge" labelling.
   - Explicit disclaimers: AI can be wrong; no predicted marks.
   - API key encrypted server-side, masked in every response, never in the browser.
   - User can disconnect AI and clear all activity data.

---

## 5. System architecture

```
┌──────────────────────────── Browser ────────────────────────────┐
│ React + TypeScript + Tailwind + Recharts                        │
│ Dashboard · Tutor · Materials · Planner · Practice · Analytics  │
│ Revision · Settings · First-run AI setup                        │
└───────────────────────────┬─────────────────────────────────────┘
                            │ JSON / multipart over /api
┌───────────────────────────▼─────────────────────────────────────┐
│ FastAPI                                                         │
│  routers  → dashboard, tutor, documents, planner, tasks, exams, │
│             tests, analytics, revision, subjects, settings, ai  │
│  services → ai_config (encrypted key), planner, analytics, SR   │
│  ai       → provider (Gemini), prompts, validated tasks         │
│  rag      → extractor (PyMuPDF/OCR), index (chunk/embed/hybrid) │
└───────────┬───────────────────────────────┬─────────────────────┘
            │ SQLAlchemy                    │ Google GenAI SDK
     ┌──────▼──────┐                 ┌──────▼──────┐
     │ SQLite      │                 │ Gemini API  │
     │ 14 tables   │                 │ generate +  │
     │ uploads/    │                 │ embeddings  │
     └─────────────┘                 └─────────────┘
```

**Why this split?** The browser never holds the API key. FastAPI can validate,
retrieve, cache and log safely, and the model can be replaced without touching the UI.

---

## 6. Database design (14 tables)

`students`, `app_settings`, `subjects`, `chapters`, `study_tasks`, `exams`,
`study_sessions`, `documents`, `document_chunks`, `chat_conversations`,
`chat_messages`, `test_attempts`, `questions`, `flashcards`, `revision_history`.

Key relationships:

- Subject **1 — N** Chapter.
- StudyTask → Subject/Chapter (nullable, so custom tasks work), and a completed task
  creates a StudySession (the single source of study minutes).
- Document **1 — N** DocumentChunk (page number + embedding JSON).
- TestAttempt **1 — N** Question (store answer, correctness, marks, explanation, chapter).
- Flashcard **1 — N** RevisionHistory (rating, previous/new interval).

Timestamps and foreign keys with cascade rules keep deletion consistent.

---

## 7. Algorithms explained simply

### 7.1 Priority-based study planner

```
priority = studied_before? 0 : 48
         + (accuracy is None ? 18 : (100 - accuracy) × 0.55)
         + difficulty × 3.5
         + (never studied ? 10 : 0)
         + exam urgency + syllabus match bonus
```

Then chapters are sorted by earliest exam deadline, and each day is filled with
50-minute blocks up to `daily_hours × 60`. A break is inserted every two blocks; one
short revision block goes to a weak chapter; practice is added every second day. If
the syllabus does not fit, the planner says so instead of producing an 11-hour day.

### 7.2 RAG retrieval

```
score = 0.7 × cosine(embed(question), embed(chunk)) + 0.3 × BM25_normalised(question, chunk)
keep chunks with score ≥ 0.28, take top 6 → prompt with [page N]
```

Embeddings are stored in SQLite as JSON and compared with numpy. If embedding calls
fail, the system continues with BM25 only — a real fallback, not a fake answer.

### 7.3 Spaced repetition (SM-2 inspired)

| Rating | Interval | Ease |
| --- | --- | --- |
| hard | 1 day (reset) | −0.20 (min 1.3) |
| medium | previous × 1.8 (first: 2 days) | unchanged |
| easy | previous × 2.6 (first: 4 days) | +0.15 (max 3.2) |

Due date = today + interval, capped at 180 days. Every review is logged.

### 7.4 Grading

- **MCQ** — normalised exact match.
- **Numerical** — numeric comparison with 2% tolerance.
- **Short/long** — coverage of significant key terms from the model answer (≥ 40%).
  The UI states this clearly and always shows the model answer.

---

## 8. Demo script (5–7 minutes)

1. **First launch** — the setup screen appears because no key is stored. Paste a key,
   click **Connect AI**; the backend verifies it live and the dashboard opens.
2. **Dashboard** — point out study time, streak, weekly chart and today's tasks; click
   **Done** on a task and show study time increase immediately.
3. **AI Tutor** — ask "Explain electric potential vs potential difference" in *Simple*,
   then switch to *Exam* and ask again. Show the conversation is saved.
4. **Materials** — upload a chapter PDF, show metadata and page count, run
   **Search inside**, then ask a question and show the page citation; ask an unrelated
   question and show the "general knowledge" label.
5. **Planner** — open **Generate plan** (7 days, 4 h), show the reasoning and the
   warning when chapters do not fit; edit a task; mark another complete.
6. **Practice** — generate 5 MCQs from a weak chapter, answer, submit; review a wrong
   answer's explanation and the topic breakdown.
7. **Analytics** — show accuracy per chapter, the score trend and the AI mentor
   recommendation, pointing out the disclaimer.
8. **Revision** — flip a card, rate it **Hard**, show the due date collapsing to
   tomorrow and the review history updating.
9. **Settings** — show masked key, test connection, change model, disconnect; note the
   app stays usable with local data.

---

## 9. Viva questions and model answers

**Q1. What exactly is AI in your project?**
Three parts: (a) a large language model (Gemini) generating explanations, summaries,
questions and flashcards; (b) an embedding-based retrieval system (RAG) that grounds
answers in the student's documents; (c) adaptive algorithms for scheduling and spaced
repetition. I do not call the rule-based planner "machine learning".

**Q2. What is RAG and why did you need it?**
Retrieval-Augmented Generation: before asking the model to answer, I search the
student's uploaded material and pass only the relevant chunks with page numbers.
Without it the model would answer from general memory and might claim things the
textbook never said.

**Q3. How does your retrieval actually work?**
Text extraction with PyMuPDF → chunking (~1,100 chars, 180 overlap) → Gemini
`embedContent` vectors stored in SQLite → question embedding → cosine similarity
blended 0.7 with BM25 keyword scores → top 6 chunks above 0.28.

**Q4. What is BM25?**
A classical keyword-ranking function (a refinement of TF-IDF) that scores documents by
term frequency, inverse document frequency and document length. It works without any
model, which is why it is my fallback.

**Q5. What is an embedding?**
A dense numeric vector representing meaning, produced by a neural network. Similar
meanings have vectors close together, so cosine similarity between them measures
semantic closeness.

**Q6. Where is machine learning vs rule-based logic?**
Learned: embeddings and the LLM (pre-trained by Google). Rule-based: planner priority
scoring, spaced repetition intervals, grading thresholds. I label them separately in
the app and report.

**Q7. What is the AI Project Cycle?**
Problem scoping → data acquisition → data exploration → modelling → evaluation →
deployment. Each stage is mapped in section 4.1.

**Q8. How do you stop the model from inventing an answer about my PDF?**
The document prompt allows only the supplied passages, requires `[p. N]` citations, and
instructs the model to say "I could not find this in your uploaded material" if the
passages do not answer. If retrieval finds nothing, the app returns a general-knowledge
answer with a visible warning instead of pretending.

**Q9. How do you handle an invalid or missing API key?**
If missing, AI endpoints return 409 with a clear message and the UI shows a connect
state. On connect, the key is validated with a real request before storage; failure
shows the exact category (invalid key, permission, quota, model, network) and leaves
any previously working configuration untouched.

**Q10. Where is the key stored? Is it safe?**
Only on the backend: encrypted with Fernet using a local secret file, stored in SQLite.
It is never returned in full (only a mask), never logged, never in `localStorage`, and
excluded from Git. All Gemini calls are made server-side.

**Q11. Why are your study hours trustworthy?**
They are not entered by hand. Completing a task writes a `study_sessions` row with the
task's duration; reopening the task removes that row. The dashboard sums those rows.

**Q12. How does the planner decide what to study first?**
It scores every chapter using exam deadline and syllabus match, difficulty, whether it
was studied, and past accuracy. Chapters with the closest exam come first, highest
priority within the same deadline. The UI shows this reasoning.

**Q13. What if the plan cannot cover the syllabus?**
It warns: "N chapters do not fit at X hours/day", and lists exam coverage risks instead
of cramming unrealistic hours.

**Q14. Explain your spaced repetition algorithm.**
A simplified SM-2: each card has an interval and ease. Hard → 1 day and lower ease;
medium → ×1.8; easy → ×2.6. Shorter interval means it comes back sooner, which is the
testing effect.

**Q15. How is performance "analysed"?**
Descriptive statistics over stored attempts: per-chapter accuracy = correct/attempted,
subject aggregation, score trend, minutes studied. Then an LLM reads that JSON and
writes priorities — labelled as AI advice, not prediction.

**Q16. Do you predict marks?**
No. The analytics page says observed performance is not a prediction, and the AI
recommendation prompt is explicitly told not to predict marks.

**Q17. How is duplicate question generation avoided?**
Past question texts for the subject are sent to the model as a "do not reuse" list, and
after parsing, duplicates are removed by normalised text comparison. Invalid MCQs
(answer not among options) are discarded.

**Q18. How do you validate AI output?**
JSON mode + defensive parsing (fences, prose, balanced braces) + structural checks:
MCQ needs 4 options and the correct one among them; flashcards need both sides; summary
arrays are length-limited. Invalid output becomes a retryable error.

**Q19. What happens when Gemini is down or quota is exhausted?**
The request fails with a specific message, no fake content is inserted, and the local
features (planner, tests already saved, revision, documents search) keep working.

**Q20. Why FastAPI and not just React?**
The key must never reach the browser, PDF extraction/embedding needs Python, and the
database plus validation belong on the server. FastAPI gives typed endpoints,
automatic validation and docs at `/docs`.

**Q21. How is the frontend structured?**
React + TypeScript with reusable primitives (`components/ui.tsx`), a typed API layer,
context for AI status/student/subjects and toasts, and one page per module. Charts use
Recharts; icons use Lucide; styles use Tailwind tokens.

**Q22. What are the limitations?**
Single local profile; OCR is optional (needs Tesseract); subjective answers use keyword
matching; AI can still be wrong; vector search is local and would need a real vector
database at large scale.

**Q23. What would you improve next?**
A trained weakness-prediction model with enough anonymised data, OCR bundled by
default, timetabled classes, and a teacher dashboard with class-level analytics.

**Q24. What did you learn about responsible AI?**
Never fabricate capability. Label what is generated vs observed, disclose sources, keep
secrets server-side, let the user delete data and disconnect the AI, and be honest about
error states and limitations.

---

## 10. Testing evidence (summary)

| Area | Result |
| --- | --- |
| Fresh database + seed | All 14 tables created; curriculum and demo activity load |
| All list endpoints | 200 with real aggregated data |
| Task lifecycle | Create / edit / complete / reopen / delete verified; study minutes update correctly |
| PDF pipeline | Upload → extract → chunk → search verified; unrelated question not answered from the PDF |
| Planner | 7 days × 3 h respected; breaks present; capacity warning produced |
| Test grading | MCQ exact (case- and spacing-insensitive), numerical ±2 % tolerance, subjective keyword coverage; per-question correctness and topic breakdown stored |
| First-run AI setup | Setup screen shown when no key exists; a fake key is rejected by a live Gemini call with a readable message and nothing saved; "explore without AI" keeps local data usable |
| Persistence | A task created over HTTP survived a backend restart and deleted cleanly afterwards |
| Revision schedule | Easy review moved due date forward; hard resets to 1 day; history rows written |
| Error handling | 422 invalid input, 409 missing key, 400 invalid key, 429 throttled after repeated attempts |
| AI key safety | Masked in status, never logged, encrypted at rest, disconnect removes it |
| Frontend build | `tsc --noEmit` and `vite build` succeed; browser console clean |

---

## 11. Conclusion

Academic Copilot shows the full lifecycle of an applied AI project: identifying a real
problem, collecting the right data, choosing between generative AI, retrieval and
deterministic algorithms, validating model output, protecting credentials, and
communicating uncertainty. It is a working study workspace rather than a mockup — and
every claim in this report can be demonstrated live.
