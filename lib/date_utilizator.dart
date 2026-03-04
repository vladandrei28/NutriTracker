import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DateUtilizator {
  static double obiectivGreutate = 78.0;
  static double obiectivCalorii = 2000.0; 
  
  static List<Map<String, dynamic>> istoric = [
    {"ziua": 1, "greutate": 85.0},
    {"ziua": 3, "greutate": 84.5},
  ];

  static int ziuaCurenta = 4; 
  static double caloriiArseSportAzi = 0; 
  static double caloriiMancateAzi = 0; 
  
  // NOU: Memoria pentru APĂ
  static double apaBautaAzi = 0; 

  static String ultimaDataAccesata = ""; 

  static Future<void> salveazaDate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('obiectiv', obiectivGreutate);
    await prefs.setDouble('obiectivCalorii', obiectivCalorii);
    await prefs.setInt('ziuaCurenta', ziuaCurenta);
    await prefs.setDouble('sport', caloriiArseSportAzi);
    await prefs.setDouble('mancare', caloriiMancateAzi);
    await prefs.setDouble('apa', apaBautaAzi); // <-- Salvăm apa
    await prefs.setString('ultimaData', ultimaDataAccesata); 
    
    String istoricText = json.encode(istoric);
    await prefs.setString('istoric', istoricText);
  }

  static Future<void> incarcaDate() async {
    final prefs = await SharedPreferences.getInstance();
    String dataDeAzi = DateTime.now().toIso8601String().split('T')[0];

    if (prefs.containsKey('obiectiv')) obiectivGreutate = prefs.getDouble('obiectiv')!;
    if (prefs.containsKey('obiectivCalorii')) obiectivCalorii = prefs.getDouble('obiectivCalorii')!;
    if (prefs.containsKey('ziuaCurenta')) ziuaCurenta = prefs.getInt('ziuaCurenta')!;
    if (prefs.containsKey('istoric')) {
      String istoricText = prefs.getString('istoric')!;
      List<dynamic> listaDecodata = json.decode(istoricText);
      istoric = listaDecodata.map((item) => item as Map<String, dynamic>).toList();
    }

    if (prefs.containsKey('ultimaData')) {
      ultimaDataAccesata = prefs.getString('ultimaData')!;
      if (ultimaDataAccesata != dataDeAzi) {
        caloriiArseSportAzi = 0;
        caloriiMancateAzi = 0;
        apaBautaAzi = 0; // <-- Resetăm apa la 0 la miezul nopții
        ultimaDataAccesata = dataDeAzi;
        await salveazaDate(); 
      } else {
        if (prefs.containsKey('sport')) caloriiArseSportAzi = prefs.getDouble('sport')!;
        if (prefs.containsKey('mancare')) caloriiMancateAzi = prefs.getDouble('mancare')!;
        if (prefs.containsKey('apa')) apaBautaAzi = prefs.getDouble('apa')!; // <-- Încărcăm apa
      }
    } else {
      ultimaDataAccesata = dataDeAzi;
      if (prefs.containsKey('apa')) apaBautaAzi = prefs.getDouble('apa')!;
      await salveazaDate();
    }
  }
}