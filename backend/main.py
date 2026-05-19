from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List

app = FastAPI(title="Fitness API Dizertație")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class Cantarire(BaseModel):
    ziua: int
    greutate: float

# NOU: Am adăugat caloriile mâncate în modelul de date
class DatePredictie(BaseModel):
    obiectiv_greutate: float
    istoric: List[Cantarire]
    calorii_arse_sport: float = 0.0 
    calorii_mancate: float = 0.0 # <--- NOU

@app.post("/predictie_avansata")
def calculeaza_predictie_reala(date: DatePredictie):
    istoric = date.istoric
    
    if len(istoric) < 2:
        return {"eroare": "Avem nevoie de cel puțin 2 cântăriri pentru a face o predicție."}

    # -- MATEMATICĂ: Regresia Liniară a istoricului --
    suma_x = sum([c.ziua for c in istoric])
    suma_y = sum([c.greutate for c in istoric])
    n = len(istoric)
    
    media_x = suma_x / n
    media_y = suma_y / n

    numarator = sum([(c.ziua - media_x) * (c.greutate - media_y) for c in istoric])
    numitor = sum([(c.ziua - media_x) ** 2 for c in istoric])

    if numitor == 0:
        return {"eroare": "Date invalide pentru axa X (zilele trebuie să fie diferite)."}

    beta1 = numarator / numitor # Ritmul istoric de slăbire
    beta0 = media_y - (beta1 * media_x)

    # -- NOU: INTEGRAREA BALANȚEI ENERGETICE (Nutriție + Sport) --
    # Presupunem un metabolism de bază (BMR) standard de 2000 kcal/zi
    metabolism_baza = 2000.0
    
    # Formula: Cât am ars în total MINUS cât am mâncat
    deficit_caloric = (metabolism_baza + date.calorii_arse_sport) - date.calorii_mancate
    
    # Transformăm deficitul în kilograme (7700 kcal = 1 kg grăsime)
    impact_zilnic_kg = deficit_caloric / 7700.0
    
    # Ajustăm panta. Scădem impactul zilnic pentru ca ritmul să devină și mai "negativ" (slăbire mai rapidă)
    beta1_ajustat = beta1 - impact_zilnic_kg

    # Dacă panta a devenit pozitivă, înseamnă că utilizatorul se îngrașă
    if beta1_ajustat >= 0:
        return {
            "status": "avertisment",
            "mesaj": "Atenție! Surplus caloric detectat. Ritmul actual duce la îngrășare.",
            "ritm_kg_pe_zi": round(beta1_ajustat, 3),
            "zile_ramase": 0
        }

    # Recalculăm ziua estimată folosind noul ritm dinamic
    ziua_estimata = (date.obiectiv_greutate - beta0) / beta1_ajustat
    ziua_curenta = istoric[-1].ziua
    zile_ramase = int(ziua_estimata - ziua_curenta)

    return {
        "status": "succes",
        "ritm_kg_pe_zi": round(beta1_ajustat, 3), 
        "zile_ramase": zile_ramase if zile_ramase > 0 else 0,
        "ziua_atingerii_obiectivului": int(ziua_estimata),
        "mesaj": "Balanța energetică a fost aplicată cu succes!"
    }