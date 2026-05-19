# NutriTracker

Aplicație mobilă de fitness cu algoritm de analiză a activității fizice.
Lucrare de disertație - ASE București, Facultatea CSIE, programul SIMPE.

## Structură

- `frontend/` - aplicația Flutter cross-platform (Android, iOS, Web, Windows)
- `backend/` - serviciul FastAPI pentru calculul predicției

## Rulare

### Backend
\`\`\`bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install fastapi uvicorn pydantic
uvicorn main:app --reload
\`\`\`

### Frontend
\`\`\`bash
cd frontend
flutter pub get
flutter run
\`\`\`

## Autor
Bonțaș Vlad-Andrei
