### NutriAI - Sistem Inteligent pentru Nutriție și Predicția Greutății

Acest proiect reprezintă lucrarea mea de dizertație, dezvoltată pentru a demonstra integrarea unei aplicații mobile moderne cu algoritmi de Machine Learning și API-uri externe.

Un sistem informatic Full-Stack conceput pentru a monitoriza alimentația, activitatea fizică și hidratarea utilizatorului. Piesa de rezistență este motorul de Inteligență Artificială, care analizează balanța energetică zilnică și aplică regresia liniară pentru a prezice cu exactitate evoluția greutății și data atingerii obiectivului.

# Funcționalități Principale

-Interfață Modernă & Intuitivă: Navigare fluidă, inele de progres pentru calorii și dashboard-uri analitice folosind grafice animate (fl_chart).
-Integrare API Global: Căutare live a alimentelor prin conectarea la baza de date Open Food Facts API, calculând automat macronutrienții (Proteine, Carbohidrați, Grăsimi) per suta de grame.
-Predicție AI : Analizează istoricul greutății și calculează un ritm dinamic de slăbire/îngrășare bazat pe termodinamică și deficitul caloric real.
-Persistența Datelor: Sistem de memorie locală (shared_preferences) care salvează starea aplicației și resetează automat caloriile și apa la miezul nopții.
-Jurnal Complet: Urmărire pentru Mese (Mic dejun, Prânz, Cină, Gustări), Apă și Activități Fizice (cu baza de date proprie pentru calorii arse/oră).

# Arhitectură și Tehnologii 

Sistemul este împărțit în două componente majore care comunică printr-un API RESTful:

1. Frontend (Mobile App)
-Framework: Flutter
-Limbaj: Dart
-Librării cheie: http (comunicare rețea), fl_chart (vizualizare date), shared_preferences (stocare locală).

2. Backend (AI & Logic Server)
-Framework: FastAPI
-Limbaj: Python
-Librării cheie: pydantic (validare date), uvicorn (server ASGI), module matematice standard pentru regresie.


# Cum funcționează Algoritmul AI?

Serverul Python nu folosește o simplă formulă statică. El combină analiza datelor istorice cu fizica balanței energetice:

1. Regresie Liniară pe Istoric: Calculează panta (ritmul de bază) folosind metoda celor mai mici pătrate pe istoricul cântăririlor.
2. Ajustare Termodinamică (Balanța Energetică): Calculează deficitul sau surplusul caloric pe baza caloriilor consumate și a sportului realizat.
   Deficit = (BMR + Sport) - Mancare
3. Predicția Finală: Modifică panta de regresie știind că 7700 kcal reprezintă aproximativ 1 kg de masă corporală, returnând utilizatorului numărul exact de zile rămase sau avertizându-l în caz de surplus caloric.
