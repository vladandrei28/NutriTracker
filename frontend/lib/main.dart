import 'package:flutter/material.dart';
import 'alimente_db.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'date_utilizator.dart';
import 'activitati_db.dart';
import 'package:fl_chart/fl_chart.dart';
//import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // 1. Ne asigurăm că motorul Flutter e pornit înainte să citim din memorie
  WidgetsFlutterBinding.ensureInitialized(); 
  
  // 2. Citim datele din Shared Preferences
  await DateUtilizator.incarcaDate(); 
  
  // 3. Pornim interfața grafică
  runApp(const FitnessApp());
}

class FitnessApp extends StatelessWidget {
  const FitnessApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness Tracker',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA), // Un fundal gri-albicios foarte elegant (nu alb pur care obosește ochii)
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E86AB), // Albastru vibrant principal
          secondary: const Color(0xFF00C853), // Verde proaspăt pentru acțiuni pozitive (adăugare)
        ),
        // Aplicăm fontul Poppins pe absolut tot textul din aplicație!
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
        // Cosmetizăm bara de sus
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF2E86AB),
          elevation: 0, // Scoatem umbra veche și urâtă
          centerTitle: true,
          titleTextStyle: GoogleFonts.poppins(
            color: Colors.white, 
            fontSize: 22, 
            fontWeight: FontWeight.w600
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const JurnalZilnicScreen(),
    const DashboardScreen(),
    const ProfilScreen(), // <--- Am pus ecranul real aici
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Nutriție'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

// --- ECRANUL PENTRU JURNAL ZILNIC (Alimentație + Sport) ---
class JurnalZilnicScreen extends StatefulWidget {
  const JurnalZilnicScreen({Key? key}) : super(key: key);

  @override
  _JurnalZilnicScreenState createState() => _JurnalZilnicScreenState();
}

class _JurnalZilnicScreenState extends State<JurnalZilnicScreen> {
  // Totaluri Mâncare
  double totalCalorii = 0;
  double totalProteine = 0;
  double totalCarbo = 0;
  double totalGrasimi = 0;

  // Listele în care vom stoca ce am mâncat la fiecare masă azi
  List<Map<String, dynamic>> micDejun = [];
  List<Map<String, dynamic>> pranz = [];
  List<Map<String, dynamic>> cina = [];
  List<Map<String, dynamic>> gustari = [];

  bool cautaAcum = false;
  List<Aliment> rezultateCautare = bazaDeDateAlimente;

  @override
  void initState() {
    super.initState();
    _incarcaDateLocal(); // Când se deschide ecranul, încarcă datele
  }

  // Funcție care ne dă data de azi (ex: "2026-3-29")
  String _obtineDataDeAzi() {
    DateTime acum = DateTime.now();
    return "${acum.year}-${acum.month}-${acum.day}";
  }

  // Încărcăm datele (Verificăm dacă a trecut de miezul nopții)
  Future<void> _incarcaDateLocal() async {
    final prefs = await SharedPreferences.getInstance();
    String dataDeAzi = _obtineDataDeAzi();
    String? dataSalvata = prefs.getString('dataSalvarii');

    if (dataSalvata == dataDeAzi) {
      // E ACEEAȘI ZI! Încărcăm datele.
      setState(() {
        totalCalorii = prefs.getDouble('totalCalorii') ?? 0;
        totalProteine = prefs.getDouble('totalProteine') ?? 0;
        totalCarbo = prefs.getDouble('totalCarbo') ?? 0;
        totalGrasimi = prefs.getDouble('totalGrasimi') ?? 0;

        String? mdString = prefs.getString('micDejun');
        if (mdString != null) micDejun = List<Map<String, dynamic>>.from(json.decode(mdString));

        String? pranzString = prefs.getString('pranz');
        if (pranzString != null) pranz = List<Map<String, dynamic>>.from(json.decode(pranzString));

        String? cinaString = prefs.getString('cina');
        if (cinaString != null) cina = List<Map<String, dynamic>>.from(json.decode(cinaString));
        
        String? gustariString = prefs.getString('gustari');
        if (gustariString != null) gustari = List<Map<String, dynamic>>.from(json.decode(gustariString));
      });
    } else {
      // E O ZI NOUĂ! Ștergem memoria pentru a face loc.
      await prefs.clear();
      setState(() {
        totalCalorii = 0; totalProteine = 0; totalCarbo = 0; totalGrasimi = 0;
        micDejun = []; pranz = []; cina = []; gustari = [];
      });
    }
  }

  // Salvăm datele (Punem și "Ștampila" cu ziua de azi)
  Future<void> _salveazaDateLocal() async {
    final prefs = await SharedPreferences.getInstance();
    
    prefs.setString('dataSalvarii', _obtineDataDeAzi()); // Ștampila
    prefs.setDouble('totalCalorii', totalCalorii);
    prefs.setDouble('totalProteine', totalProteine);
    prefs.setDouble('totalCarbo', totalCarbo);
    prefs.setDouble('totalGrasimi', totalGrasimi);

    prefs.setString('micDejun', json.encode(micDejun));
    prefs.setString('pranz', json.encode(pranz));
    prefs.setString('cina', json.encode(cina));
    prefs.setString('gustari', json.encode(gustari));
  }

  // Funcție pentru adăugat un aliment complet personalizat (inclusiv Macronutrienți)
  void _arataDialogAlimentPersonalizat(String masa, List<Map<String, dynamic>> listaMasa) {
    TextEditingController numeController = TextEditingController();
    TextEditingController caloriiController = TextEditingController();
    TextEditingController proteineController = TextEditingController(); // NOU
    TextEditingController carboController = TextEditingController();    // NOU
    TextEditingController grasimiController = TextEditingController();  // NOU
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Crează Aliment Nou ($masa)'),
        // Am pus un SingleChildScrollView ca să putem da scroll dacă tastatura acoperă ecranul
        content: SingleChildScrollView( 
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: numeController, decoration: const InputDecoration(labelText: 'Nume (ex: Pizza)')),
              TextField(controller: caloriiController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Calorii', suffixText: 'kcal')),
              const Divider(height: 30),
              const Text('Macronutrienți (Opțional)', style: TextStyle(color: Colors.grey, fontSize: 12)),
              TextField(controller: proteineController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Proteine', suffixText: 'g')),
              TextField(controller: carboController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Carbohidrați', suffixText: 'g')),
              TextField(controller: grasimiController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Grăsimi', suffixText: 'g')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Anulează')),
          ElevatedButton(
            onPressed: () {
              // Verificăm să avem măcar numele și caloriile trecute
              if (numeController.text.isNotEmpty && caloriiController.text.isNotEmpty) {
                double calorii = double.parse(caloriiController.text);
                
                // Dacă lăsăm goale căsuțele de macro, punem 0 automat ca să nu dea eroare
                double proteine = proteineController.text.isNotEmpty ? double.parse(proteineController.text) : 0.0;
                double carbo = carboController.text.isNotEmpty ? double.parse(carboController.text) : 0.0;
                double grasimi = grasimiController.text.isNotEmpty ? double.parse(grasimiController.text) : 0.0;

                setState(() {
                  // Îl adăugăm vizual în lista mesei
                  listaMasa.add({"nume": numeController.text, "calorii": calorii, "grame": "1 Porție"});
                  
                  // Adunăm la totalurile zilei
                  totalCalorii += calorii;
                  totalProteine += proteine;
                  totalCarbo += carbo;
                  totalGrasimi += grasimi;
                  
                  // Îl trimitem și în "Memorie" pentru serverul Python
                  DateUtilizator.caloriiMancateAzi += calorii;
                });
                
                _salveazaDateLocal();
                DateUtilizator.salveazaDate();
                Navigator.pop(context); // Închidem dialogul
              }
            },
            child: const Text('Adaugă'),
          ),
        ],
      ),
    );
  }


  // NOU: Funcția care deschide camera, scanează și descarcă produsul!
  Future<void> _scaneazaCodDeBare(String masa, List<Map<String, dynamic>> listaMasa, StateSetter setModalState) async {
    // 1. Deschide noul scanner compatibil cu Web-ul
    // Plugin scanner dezactivat temporar - incompatibil cu iOS 26.5
    String? barcodeScanRes;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scaner indisponibil pe simulator')),
      );
    }

    // 2. Dacă utilizatorul a scanat cu succes un cod (și nu a anulat)
    if (barcodeScanRes != null && barcodeScanRes != '-1') {
      setModalState(() => cautaAcum = true); // Pornim rotița de încărcare

      // Cerem de la Open Food Facts exact produsul cu acest cod
      final url = Uri.parse('https://world.openfoodfacts.org/api/v0/product/$barcodeScanRes.json');
      
      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          
          if (data['status'] == 1) { 
            // Am găsit produsul! Extragem datele
            final p = data['product'];
            final nume = p['product_name'] ?? 'Produs Necunoscut';
            final nutriments = p['nutriments'] ?? {};

            Aliment alimentGasit = Aliment(
              nume: nume.toString(),
              calorii: (nutriments['energy-kcal_100g'] ?? 0).toDouble(),
              proteine: (nutriments['proteins_100g'] ?? 0).toDouble(),
              carbohidrati: (nutriments['carbohydrates_100g'] ?? 0).toDouble(),
              grasimi: (nutriments['fat_100g'] ?? 0).toDouble(),
            );

            // Închidem fereastra de căutare și deschidem DIRECT popup-ul de grame!
            Navigator.pop(context); 
            _arataDialogCantitate(alimentGasit, masa, listaMasa);
            
          } else {
             setModalState(() => cautaAcum = false);
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produsul nu a fost găsit în baza de date!')));
          }
        }
      } catch(e) {
         setModalState(() => cautaAcum = false);
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Eroare la internet.')));
      }
    }
  }

  // Funcția de afișare îmbunătățită cu buton de Scanner
  void _arataListaAlimente(String masa, List<Map<String, dynamic>> listaMasa) {
    TextEditingController cautareController = TextEditingController();
    rezultateCautare = bazaDeDateAlimente; 
    cautaAcum = false;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return FractionallySizedBox(
              heightFactor: 0.85,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: cautareController,
                      decoration: InputDecoration(
                        labelText: 'Caută aliment (ex: banana)',
                        prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        // Am adăugat 2 butoane: cel de Căutare Text și cel de SCANNER
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.qr_code_scanner, color: Colors.redAccent, size: 28),
                              onPressed: () => _scaneazaCodDeBare(masa, listaMasa, setModalState), // Apelăm scannerul
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward),
                              onPressed: () => cautareController.text.isNotEmpty ? null : null,
                            ),
                          ],
                        )
                      ),
                      onSubmitted: (text) async {
                        // ... (Logica veche de căutare pe internet rămâne neschimbată)
                        if (text.isNotEmpty) {
                          setModalState(() => cautaAcum = true);
                          final url = Uri.parse('https://world.openfoodfacts.org/cgi/search.pl?search_terms=$text&search_simple=1&action=process&json=1&page_size=15');
                          try {
                            final response = await http.get(url);
                            if (response.statusCode == 200) {
                              final data = json.decode(response.body);
                              final produse = data['products'] as List;
                              List<Aliment> listaNoua = [];
                              for (var p in produse) {
                                final nume = p['product_name'];
                                final nutriments = p['nutriments'];
                                if (nume != null && nutriments != null && nutriments['energy-kcal_100g'] != null) {
                                  listaNoua.add(Aliment(
                                    nume: nume.toString(),
                                    calorii: (nutriments['energy-kcal_100g'] ?? 0).toDouble(),
                                    proteine: (nutriments['proteins_100g'] ?? 0).toDouble(),
                                    carbohidrati: (nutriments['carbohydrates_100g'] ?? 0).toDouble(),
                                    grasimi: (nutriments['fat_100g'] ?? 0).toDouble(),
                                  ));
                                }
                              }
                              setModalState(() {
                                rezultateCautare = listaNoua;
                                cautaAcum = false;
                              });
                            }
                          } catch (e) {
                            setModalState(() => cautaAcum = false);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Eroare la internet.')));
                          }
                        }
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.add_box, color: Colors.deepPurple, size: 30),
                    title: const Text('Adaugă aliment personalizat', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                    onTap: () {
                      Navigator.pop(context);
                      _arataDialogAlimentPersonalizat(masa, listaMasa);
                    },
                  ),
                  const Divider(thickness: 2),
                  Expanded(
                    child: cautaAcum 
                      ? const Center(child: CircularProgressIndicator()) 
                      : ListView.builder(
                          itemCount: rezultateCautare.length,
                          itemBuilder: (context, index) {
                            final aliment = rezultateCautare[index];
                            return ListTile(
                              leading: const Icon(Icons.fastfood, color: Colors.orange),
                              title: Text(aliment.nume, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${aliment.calorii} kcal / 100g\nPro: ${aliment.proteine}g | Carbo: ${aliment.carbohidrati}g | Gră: ${aliment.grasimi}g'),
                              isThreeLine: true,
                              trailing: const Icon(Icons.add_circle_outline, color: Colors.green),
                              onTap: () {
                                Navigator.pop(context); 
                                _arataDialogCantitate(aliment, masa, listaMasa); 
                              },
                            );
                          },
                        ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  // Funcția pentru introdus gramele (modificată să pună alimentul în categoria corectă)
  void _arataDialogCantitate(Aliment aliment, String masa, List<Map<String, dynamic>> listaMasa) {
    TextEditingController grameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adaugă la $masa'),
        content: TextField(
          controller: grameController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Cantitate (${aliment.nume})', suffixText: 'g'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Anulează')),
          ElevatedButton(
            onPressed: () {
              if (grameController.text.isNotEmpty) {
                double grame = double.parse(grameController.text);
                double calCalc = (aliment.calorii * grame) / 100;
                double proCalc = (aliment.proteine * grame) / 100;
                double carCalc = (aliment.carbohidrati * grame) / 100;
                double grasCalc = (aliment.grasimi * grame) / 100;

                setState(() {
                  // Salvăm vizual în lista mesei
                  listaMasa.add({
                    "nume": aliment.nume,
                    "calorii": calCalc,
                    "grame": grame,
                  });

                  // Adunăm la totaluri
                  totalCalorii += calCalc;
                  totalProteine += proCalc;
                  totalCarbo += carCalc;
                  totalGrasimi += grasCalc;
                  
                  // Actualizăm "Memoria" pentru Python
                  DateUtilizator.caloriiMancateAzi += calCalc;
                });
                _salveazaDateLocal();
                DateUtilizator.salveazaDate();
                Navigator.pop(context);
              }
            },
            child: const Text('Adaugă'),
          ),
        ],
      ),
    );
  }

  // Funcție și Pop-up pentru a adăuga Apă
  void _arataDialogApa() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Câtă apă ai băut?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 40)),
              onPressed: () {
                setState(() => DateUtilizator.apaBautaAzi += 250);
                DateUtilizator.salveazaDate();
                _salveazaDateLocal();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.local_drink),
              label: const Text('+ 250 ml (Un pahar)'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 40)),
              onPressed: () {
                setState(() => DateUtilizator.apaBautaAzi += 500);
                DateUtilizator.salveazaDate();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.water_drop),
              label: const Text('+ 500 ml (O sticlă)'),
            ),
          ],
        ),
      ),
    );
  }

  // Funcție pentru zona de sport (rămâne la fel)
  void _arataDialogSport(Activitate activitate) {
    TextEditingController minuteController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ai făcut: ${activitate.nume}'),
        content: TextField(controller: minuteController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Durata', suffixText: 'minute')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Anulează')),
          ElevatedButton(
            onPressed: () {
              if (minuteController.text.isNotEmpty) {
                double minute = double.parse(minuteController.text);
                setState(() {
                  DateUtilizator.caloriiArseSportAzi += (activitate.caloriiPeOra * minute) / 60;
                  DateUtilizator.sporturiAzi.add({
                    'nume': activitate.nume,
                    'minute': minute,
                    'calorii': (activitate.caloriiPeOra * minute) / 60,
                  });
                  
                });
                _salveazaDateLocal();
                DateUtilizator.salveazaDate();
                Navigator.pop(context);
              }
            },
            child: const Text('Adaugă Sport'),
          ),
        ],
      ),
    );
  }

  // Funcție ajutătoare pentru a desena frumos Proteinele, Carbo și Grăsimile
  Widget _construiesteMacro(String nume, String valoare, Color culoare) {
    return Column(
      children: [
        Text(valoare, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: culoare)),
        const SizedBox(height: 4),
        Text(nume, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
      ],
    );
  }

  void _arataDialogActivitatePersonalizata() {
    TextEditingController numeController = TextEditingController();
    TextEditingController caloriiOraController = TextEditingController();
    TextEditingController minuteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Adaugă Activitate Nouă', style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: numeController,
                decoration: const InputDecoration(labelText: 'Nume (ex: Fotbal, Dans)', prefixIcon: Icon(Icons.sports_basketball)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: caloriiOraController,
                decoration: const InputDecoration(labelText: 'Calorii arse / oră (ex: 450)', prefixIcon: Icon(Icons.local_fire_department, color: Colors.orange)),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: minuteController,
                decoration: const InputDecoration(labelText: 'Durată (minute)', prefixIcon: Icon(Icons.timer, color: Colors.blue)),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anulează', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
              onPressed: () {
                if (numeController.text.isNotEmpty && caloriiOraController.text.isNotEmpty && minuteController.text.isNotEmpty) {
                  double caloriiOra = double.tryParse(caloriiOraController.text) ?? 0;
                  double minute = double.tryParse(minuteController.text) ?? 0;
                  
                  // Calculăm câte calorii s-au ars în minutele introduse
                  double caloriiArseAcum = (caloriiOra / 60) * minute;

                  setState(() {
                    // Aici este magia: adăugăm la variabila ta din date_utilizator!
                    DateUtilizator.caloriiArseSportAzi += caloriiArseAcum;
                    DateUtilizator.sporturiAzi.add({
                      'nume': numeController.text,
                      'minute': minute.toInt(),
                      'calorii': caloriiArseAcum,
                    });
                  });
                  
                  _salveazaDateLocal();
                  Navigator.pop(context); // Închidem dialogul
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Activitate adăugată: ${numeController.text}!')));
                }
              },
              child: const Text('Adaugă'),
            ),
          ],
        );
      },
    );
  }

 Widget _construiesteSectiuneMasa(String titlu, List<Map<String, dynamic>> listaMasa) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.15),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(titlu, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.add_circle, color: Colors.deepPurple, size: 28), onPressed: () => _arataListaAlimente(titlu, listaMasa)),
              ],
            ),
            const Divider(),
            if (listaMasa.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Text('Nu ai adăugat nimic încă.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))),
            
            // Aici afișăm alimentele
            ...listaMasa.asMap().entries.map((entry) {
              int index = entry.key;
              var item = entry.value;
              String sufix = (item["grame"] is num) ? "g" : "";
              String gramajText = (item["grame"] is num)
                 ? "${(item["grame"] as num).round()}g "
                 : "";
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('$gramajText${item["nume"]}'),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${item["calorii"].round()} kcal',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                      padding: const EdgeInsets.only(left: 8),
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() {
                          DateUtilizator.caloriiMancateAzi -= (item["calorii"] as num).toDouble();
                          listaMasa.removeAt(index);
                        });
                        DateUtilizator.salveazaDate();
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double caloriiRamase = DateUtilizator.obiectivCalorii - totalCalorii;
    if (caloriiRamase < 0) caloriiRamase = 0;
    double progress = totalCalorii / DateUtilizator.obiectivCalorii;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Jurnalul Meu'),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.deepPurple,
                  Color(0xFF8E44AD),
                ],
              ),
            ),
          ),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.restaurant), text: "Alimentație"),
              Tab(icon: Icon(Icons.fitness_center), text: "Activitate Fizică"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: MÂNCAREA (Noul Design)
            SingleChildScrollView(
              child: Column(
                children: [
                  // ZONA DE REZUMAT CALORII (Stilul din poză)
              Container(
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.symmetric(vertical: 25.0, horizontal: 15.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 5),
                    )
                  ]
                ),
                child: Column(
                  children: [
                    // ETAJUL 1: Caloriile și Cercul
                    Row(
                      children: [
                        // Consumate (Stânga) - Forțat să ocupe spațiu egal
                        Expanded(
                          child: Column(
                            children: [
                              const Text('Consumate', style: TextStyle(color: Colors.grey, fontSize: 13)),
                              const SizedBox(height: 5),
                              Text('${totalCalorii.round()}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                            ],
                          ),
                        ),
                        
                        // Cercul (Centru) - Acum blocat matematic pe mijloc
                        SizedBox(
                          height: 130,
                          width: 130,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CircularProgressIndicator(
                                value: totalCalorii / 2000, 
                                strokeWidth: 10,
                                backgroundColor: Colors.grey[200],
                                color: Colors.greenAccent[400],
                                strokeCap: StrokeCap.round, 
                              ),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('${(2000 - totalCalorii).round()}', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.green[600])),
                                    const Text('rămase', style: TextStyle(fontSize: 13, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Obiectiv (Dreapta) - Forțat să ocupe spațiu egal
                        Expanded(
                          child: Column(
                            children: [
                              const Text('Obiectiv', style: TextStyle(color: Colors.grey, fontSize: 13)),
                              const SizedBox(height: 5),
                              const Text('2000', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 30),
                    const Divider(height: 1, color: Colors.black12), // Linia despărțitoare fină
                    const SizedBox(height: 20),
                    
                    // ETAJUL 2: Macronutrienții ordonați
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _construiesteMacro('Proteine', '${totalProteine.round()}g', Colors.teal),
                        _construiesteMacro('Carbohidrați', '${totalCarbo.round()}g', Colors.orange),
                        _construiesteMacro('Grăsimi', '${totalGrasimi.round()}g', Colors.redAccent),
                      ],
                    ),
                  ],
                ),
              ),
                  const SizedBox(height: 10),

                  // LISTELE CU MESE
                  _construiesteSectiuneMasa("Mic Dejun", micDejun),
                  _construiesteSectiuneMasa("Prânz", pranz),
                  _construiesteSectiuneMasa("Cină", cina),
                  _construiesteSectiuneMasa("Gustare", gustari),
                  Card(
                    margin: const EdgeInsets.all(16),
                    elevation: 3,
                    color: Colors.blue[50],
                    child: ListTile(
                      leading: const Icon(Icons.water_drop, color: Colors.blue, size: 40),
                      title: const Text('Jurnal de Apă', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      subtitle: Text('${DateUtilizator.apaBautaAzi.round()} ml / 2000 ml', style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold)),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, shape: const CircleBorder(), padding: const EdgeInsets.all(12)),
                        onPressed: _arataDialogApa,
                        child: const Icon(Icons.add),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                ],
              ),
            ),

            // TAB 2: SPORTUL
            Column(
              children: [
                Container(
                padding: const EdgeInsets.all(16.0),
                color: Colors.blue[50],
                width: double.infinity,
                child: Column(
                  children: [
                    const Text('Total Ars prin Sport Azi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                    const SizedBox(height: 10),
                    Text('- ${DateUtilizator.caloriiArseSportAzi.round()} kcal', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
              ),

              if (DateUtilizator.sporturiAzi.isNotEmpty) ...[
  const SizedBox(height: 16),
  Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'Activități adăugate azi',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
      ),
    ),
  ),
  const SizedBox(height: 8),
  ...DateUtilizator.sporturiAzi.asMap().entries.map((entry) {
    int index = entry.key;
    var sport = entry.value;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.fitness_center, color: Colors.blue),
        title: Text(sport['nume'], style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${sport['minute'].round()} min • ${sport['calorii'].round()} kcal'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () {
            setState(() {
              DateUtilizator.caloriiArseSportAzi -= sport['calorii'];
              DateUtilizator.sporturiAzi.removeAt(index);
              DateUtilizator.salveazaDate();
            });
          },
        ),
      ),
    );
  }).toList(),
],

              // --- BUTONUL NOU ESTE INTEGRAT DIRECT AICI ---
              const SizedBox(height: 10),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                elevation: 4,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: const Icon(Icons.add_circle, color: Colors.deepPurple, size: 35),
                  title: const Text('Adaugă activitate personalizată', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                  subtitle: const Text('Introdu manual o activitate și durata ei'),
                  onTap: () {
                    _arataDialogActivitatePersonalizata();
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Divider(thickness: 2),
              ),
                Expanded(
                  child: ListView.builder(
                    itemCount: bazaDeDateActivitati.length,
                    itemBuilder: (context, index) {
                      final activitate = bazaDeDateActivitati[index];
                      return ListTile(
                        leading: const Icon(Icons.directions_run, color: Colors.blue),
                        title: Text(activitate.nume, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${activitate.caloriiPeOra} kcal / oră'),
                        trailing: IconButton(icon: const Icon(Icons.add_circle, color: Colors.blue), onPressed: () => _arataDialogSport(activitate)),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- ECRANUL DASHBOARD (Conexiunea cu Python) ---
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isLoading = false;
  String mesajRezultat = "Apasă butonul pentru a rula algoritmul AI";
  int? zileRamase;
  double? ritmSlabire;

  Future<void> cerePredictieDeLaServer() async {
    setState(() {
      isLoading = true;
    });

    try {
      final url = Uri.parse('http://127.0.0.1:8000/predictie_avansata');

     final dateDeTrimis = {
        "obiectiv_greutate": DateUtilizator.obiectivGreutate,
        "istoric": DateUtilizator.istoric,
        "calorii_arse_sport": DateUtilizator.caloriiArseSportAzi,
        "calorii_mancate": DateUtilizator.caloriiMancateAzi // <--- Piesa finală de puzzle!
      };

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(dateDeTrimis),
      );

     if (response.statusCode == 200) {
        final datePrimite = json.decode(response.body);
        setState(() {
          if (datePrimite['status'] == 'avertisment') {
            zileRamase = 0;
            ritmSlabire = datePrimite['ritm_kg_pe_zi'];
            mesajRezultat = "⚠️ ${datePrimite['mesaj']}"; // Mesajul de îngrășare de la Python
          } else {
            zileRamase = datePrimite['zile_ramase'];
            ritmSlabire = datePrimite['ritm_kg_pe_zi'];
            mesajRezultat = "Predicție actualizată cu succes!";
          }
        });
      }
    } catch (e) {
      setState(() {
        mesajRezultat = "Eroare de conexiune. Asigură-te că serverul Python e pornit!";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // NOU: Funcție care transformă istoricul nostru în puncte (X = ziua, Y = greutatea) pentru grafic
  List<FlSpot> _genereazaPuncteGrafic() {
    return DateUtilizator.istoric.map((date) {
      return FlSpot(date["ziua"].toDouble(), date["greutate"].toDouble());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard & Analytics'), centerTitle: true),
      // Folosim SingleChildScrollView ca să putem da scroll dacă ecranul e mic
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.analytics, size: 60, color: Colors.blueAccent),
                const SizedBox(height: 10),
                
                if (zileRamase != null) ...[
                  const Text('Zile rămase până la obiectiv:', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  Text('$zileRamase', style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: Colors.green)),
                  Text('Ritm estimat: $ritmSlabire kg/zi', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 30),

                  // NOU: Graficul nostru vizual
                  const Text('Evoluția Greutății', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Container(
                    height: 250, // Înălțimea graficului
                    padding: const EdgeInsets.only(right: 20, left: 10),
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true, drawVerticalLine: true),
                        titlesData: FlTitlesData(
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: true, reservedSize: 22, getTitlesWidget: (value, meta) => Text('Z${value.toInt()}')),
                          ),
                        ),
                        borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300)),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _genereazaPuncteGrafic(),
                            isCurved: true, // Face linia șerpuită frumos, nu dreaptă
                            color: Colors.blue,
                            barWidth: 4,
                            isStrokeCapRound: true,
                            dotData: FlDotData(show: true), // Arată punctele pe grafic
                            belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.2)), // Umple zona de sub linie
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],

                Text(mesajRezultat, textAlign: TextAlign.center, style: const TextStyle(fontStyle: FontStyle.italic)),
                const SizedBox(height: 20),

                isLoading 
                  ? const CircularProgressIndicator() 
                  : ElevatedButton.icon(
                      onPressed: cerePredictieDeLaServer,
                      icon: const Icon(Icons.sync),
                      label: const Text('Calculează Predicția AI', style: TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- ECRANUL PROFIL & OBIECTIVE ---
class ProfilScreen extends StatefulWidget {
  const ProfilScreen({Key? key}) : super(key: key);

  @override
  _ProfilScreenState createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final TextEditingController obiectivController = TextEditingController(text: DateUtilizator.obiectivGreutate.toString());
  
  // NOU: Am adăugat un controller pentru a citi caloriile din memorie
  final TextEditingController obiectivCaloriiController = TextEditingController(text: DateUtilizator.obiectivCalorii.round().toString());
  
  final TextEditingController greutateNouaController = TextEditingController();

  void _salveazaObiectiv() {
    setState(() => DateUtilizator.obiectivGreutate = double.parse(obiectivController.text));
    DateUtilizator.salveazaDate();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Obiectiv greutate actualizat!')));
  }

  // NOU: Funcția care salvează noul obiectiv de calorii pe telefon
  void _salveazaObiectivCalorii() {
    if (obiectivCaloriiController.text.isNotEmpty) {
      setState(() => DateUtilizator.obiectivCalorii = double.parse(obiectivCaloriiController.text));
      DateUtilizator.salveazaDate();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Obiectiv calorii actualizat!')));
    }
  }

  void _adaugaCantarire() {
    if (greutateNouaController.text.isNotEmpty) {
      setState(() {
        DateUtilizator.istoric.add({
          "ziua": DateUtilizator.ziuaCurenta,
          "greutate": double.parse(greutateNouaController.text)
        });
        DateUtilizator.ziuaCurenta++; 
        greutateNouaController.clear();
      });
      DateUtilizator.salveazaDate();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cântărire adăugată cu succes!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profilul Meu'), centerTitle: true, backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. CARD OBIECTIV GREUTATE
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('Setează Obiectivul (kg)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: obiectivController, keyboardType: TextInputType.number, textAlign: TextAlign.center,
                      decoration: const InputDecoration(border: OutlineInputBorder(), suffixText: 'kg'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(onPressed: _salveazaObiectiv, child: const Text('Salvează Obiectiv')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. NOU: CARD OBIECTIV CALORII
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('Setează Obiectiv Calorii (Zilnic)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: obiectivCaloriiController, keyboardType: TextInputType.number, textAlign: TextAlign.center,
                      decoration: const InputDecoration(border: OutlineInputBorder(), suffixText: 'kcal'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
                      onPressed: _salveazaObiectivCalorii, 
                      child: const Text('Salvează Calorii')
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 3. CARD ADAUGĂ CÂNTĂRIRE
            Card(
              elevation: 3,
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('Adaugă cântărire (Ziua ${DateUtilizator.ziuaCurenta})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: greutateNouaController, keyboardType: TextInputType.number, textAlign: TextAlign.center,
                      decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Ex: 84.0', suffixText: 'kg'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      onPressed: _adaugaCantarire, 
                      child: const Text('Adaugă în Jurnal'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // ISTORIC CÂNTĂRIRI
            const Text('Istoric Cântăriri:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ...DateUtilizator.istoric.map((cantarire) => ListTile(
              leading: const Icon(Icons.monitor_weight),
              title: Text('Ziua ${cantarire["ziua"]}'),
              trailing: Text('${cantarire["greutate"]} kg', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            )).toList(),
          ],
        ),
      ),
    );
  }
}

