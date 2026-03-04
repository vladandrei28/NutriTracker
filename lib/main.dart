import 'package:flutter/material.dart';
import 'alimente_db.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'date_utilizator.dart';
import 'activitati_db.dart';
import 'package:fl_chart/fl_chart.dart';

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
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.grey[100],
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


// NOU: Funcția de afișare care folosește API-ul global pentru mâncare
  void _arataListaAlimente(String masa, List<Map<String, dynamic>> listaMasa) {
    TextEditingController cautareController = TextEditingController();
    
    // Lista care va stoca rezultatele venite de pe internet (la început arată baza noastră mică)
    List<Aliment> rezultateCautare = bazaDeDateAlimente; 
    bool cautaAcum = false; // Ne arată dacă aplicația descarcă date în momentul ăsta

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        // StatefulBuilder ne permite să modificăm ecranul mic fără să dăm refresh la toată aplicația
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return FractionallySizedBox(
              heightFactor: 0.85, // Fereastra ocupă 85% din ecran
              child: Column(
                children: [
                  // BARA DE CĂUTARE
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: cautareController,
                      decoration: InputDecoration(
                        labelText: 'Caută pe internet (ex: banana, pizza, pui)',
                        prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: () => cautareController.text.isNotEmpty ? null : null, // Apelul se face la OnSubmitted
                        )
                      ),
                      onSubmitted: (text) async {
                        if (text.isNotEmpty) {
                          setModalState(() => cautaAcum = true); // Pornește rotița de încărcare
                          
                          // --- APELUL CĂTRE API-UL OPEN FOOD FACTS ---
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
                                
                                // Verificăm dacă produsul are date nutriționale valide
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
                              // Actualizăm lista vizuală cu noile date găsite
                              setModalState(() {
                                rezultateCautare = listaNoua;
                                cautaAcum = false;
                              });
                            }
                          } catch (e) {
                            // În caz de eroare la internet
                            setModalState(() => cautaAcum = false);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Eroare la căutarea pe internet.')));
                          }
                        }
                      },
                    ),
                  ),
                  
                  // Butonul vechi pentru adăugare manuală (în caz că nu găsești pe internet)
                  ListTile(
                    leading: const Icon(Icons.add_box, color: Colors.deepPurple, size: 30),
                    title: const Text('Adaugă aliment personalizat', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                    onTap: () {
                      Navigator.pop(context);
                      _arataDialogAlimentPersonalizat(masa, listaMasa);
                    },
                  ),
                  const Divider(thickness: 2),
                  
                  // LISTA DE REZULTATE (Găsite pe internet sau cele de bază)
                  Expanded(
                    child: cautaAcum 
                      ? const Center(child: CircularProgressIndicator()) // Rotiță de încărcare când caută
                      : ListView.builder(
                          itemCount: rezultateCautare.length,
                          itemBuilder: (context, index) {
                            final aliment = rezultateCautare[index];
                            return ListTile(
                              leading: const Icon(Icons.fastfood, color: Colors.orange),
                              title: Text(aliment.nume, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${aliment.calorii} kcal / 100g\nProteine: ${aliment.proteine}g | Carbohidrati: ${aliment.carbohidrati}g | Grăsimi: ${aliment.grasimi}g'),
                              isThreeLine: true, // Face rândul mai lat ca să încapă textul
                              trailing: const Icon(Icons.add_circle_outline, color: Colors.green),
                              onTap: () {
                                Navigator.pop(context); 
                                // Când apeși, te duce direct la fereastra unde bagi gramele!
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
                });
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

 Widget _construiesteSectiuneMasa(String titlu, List<Map<String, dynamic>> listaMasa) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
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
            ...listaMasa.map((item) {
              // REGULA NOUĂ: Verificăm dacă 'grame' este un număr. Dacă da, punem 'g'. Dacă nu, lăsăm gol.
              String sufix = (item["grame"] is num) ? "g" : ""; 
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${item["grame"]}$sufix ${item["nume"]}'), // Acum se va afișa corect!
                    Text('${item["calorii"].round()} kcal', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
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
          backgroundColor: Colors.deepPurple,
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
                    padding: const EdgeInsets.all(20.0),
                    color: Colors.white,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text('${totalCalorii.round()}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                const Text('Consumate', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                            // Cercul de progres
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 100,
                                  height: 100,
                                  child: CircularProgressIndicator(
                                    value: progress > 1 ? 1 : progress,
                                    strokeWidth: 8,
                                    backgroundColor: Colors.grey[300],
                                    valueColor: AlwaysStoppedAnimation<Color>(caloriiRamase == 0 ? Colors.red : Colors.green),
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('${caloriiRamase.round()}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: caloriiRamase == 0 ? Colors.red : Colors.green)),
                                    const Text('kcal rămase', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text('${DateUtilizator.obiectivCalorii.round()}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                const Text('Obiectiv', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Barele pentru macronutrienți
                       Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text('Proteine: ${totalProteine.round()}g', style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                            Text('Carbohidrați: ${totalCarbo.round()}g', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                            Text('Grăsimi: ${totalGrasimi.round()}g', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
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
                  padding: const EdgeInsets.all(16.0), color: Colors.blue[50], width: double.infinity,
                  child: Column(
                    children: [
                      const Text('Total Ars prin Sport Azi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                      const SizedBox(height: 10),
                      Text('- ${DateUtilizator.caloriiArseSportAzi.round()} kcal', style: const TextStyle(fontSize: 32, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                    ],
                  ),
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

