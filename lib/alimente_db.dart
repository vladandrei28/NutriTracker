// 1. Definim cum arată un Aliment în aplicația noastră
class Aliment {
  final String nume;
  final double calorii; // per 100g
  final double proteine; // per 100g
  final double carbohidrati; // per 100g
  final double grasimi; // per 100g

  Aliment({
    required this.nume,
    required this.calorii,
    required this.proteine,
    required this.carbohidrati,
    required this.grasimi,
  });
}

// 2. Creăm baza noastră de date "offline" pentru demonstrație
List<Aliment> bazaDeDateAlimente = [
  Aliment(nume: 'Piept de pui la grătar', calorii: 165, proteine: 31, carbohidrati: 0, grasimi: 3.6),
  Aliment(nume: 'Orez alb fiert', calorii: 130, proteine: 2.7, carbohidrati: 28, grasimi: 0.3),
  Aliment(nume: 'Ou fiert', calorii: 155, proteine: 13, carbohidrati: 1.1, grasimi: 11),
  Aliment(nume: 'Măr', calorii: 52, proteine: 0.3, carbohidrati: 14, grasimi: 0.2),
  Aliment(nume: 'Migdale', calorii: 579, proteine: 21, carbohidrati: 22, grasimi: 50),
];

