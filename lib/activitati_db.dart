// lib/activitati_db.dart

class Activitate {
  final String nume;
  final double caloriiPeOra; // Câte calorii arzi într-o oră de efort

  Activitate({
    required this.nume,
    required this.caloriiPeOra,
  });
}

// Baza de date demonstrativă pentru dizertație
List<Activitate> bazaDeDateActivitati = [
  Activitate(nume: 'Alergare (ritm mediu)', caloriiPeOra: 600),
  Activitate(nume: 'Mers alert', caloriiPeOra: 300),
  Activitate(nume: 'Antrenament de forță (Sală)', caloriiPeOra: 400),
  Activitate(nume: 'Ciclism', caloriiPeOra: 500),
  Activitate(nume: 'Înot', caloriiPeOra: 550),
];