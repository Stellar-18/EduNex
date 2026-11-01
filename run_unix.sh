#!/usr/bin/env bash
# Academic Copilot - local development launcher (macOS / Linux)
set -e
cd "$(dirname "$0")"

if [ ! -x backend/.venv/bin/python ]; then
  python3 -m venv backend/.venv
  backend/.venv/bin/python -m pip install --quiet --upgrade pip
  backend/.venv/bin/python -m pip install --quiet -r backend/requirements.txt
fi

if [ ! -d frontend/node_modules ]; then
  (cd frontend && npm install)
fi

(cd backend && .venv/bin/python -m uvicorn app.main:app --host 127.0.0.1 --port 8000) &
API_PID=$!
(cd frontend && npm run dev) &
WEB_PID=$!

echo "API: http://127.0.0.1:8000   App: http://127.0.0.1:5173"
trap "kill $API_PID $WEB_PID 2>/dev/null" EXIT
wait
