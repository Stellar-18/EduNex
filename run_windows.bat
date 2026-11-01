@echo off
REM Academic Copilot - local development launcher (Windows)
setlocal
cd /d "%~dp0"

if not exist "backend\.venv\Scripts\python.exe" (
  echo Creating Python virtual environment...
  python -m venv backend\.venv
  backend\.venv\Scripts\python.exe -m pip install --quiet --upgrade pip
  backend\.venv\Scripts\python.exe -m pip install --quiet -r backend\requirements.txt
)

if not exist "frontend\node_modules" (
  echo Installing frontend dependencies...
  pushd frontend
  call npm install
  popd
)

echo Starting FastAPI on http://127.0.0.1:8000
start "Academic Copilot API" cmd /k "cd /d %CD%\backend && .venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000"

echo Starting Vite on http://127.0.0.1:5173
start "Academic Copilot Web" cmd /k "cd /d %CD%\frontend && npm run dev"

start "" http://127.0.0.1:5173
endlocal
