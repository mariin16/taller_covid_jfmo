import 'package:flutter/material.dart';
import 'covid_api.dart';
import 'covid_data.dart';
import 'notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: HomePage(),
  ));
}

String formatDate(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}

// Ejercicio 5: Widget pequeño reutilizable
class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const countries = [
    'Colombia',
    'Mexico',
    'Argentina',
    'Peru',
    'Chile',
    'Spain',
    'USA',
  ];

  String selected = 'Colombia';
  late Future<CovidData> future = fetchCountry(selected);

  void _reload() {
    setState(() {
      future = fetchCountry(selected);
    });
  }

  Future<void> _notify(CovidData d) async {
    await NotificationService.show(
      title: 'COVID-19: ${d.country}',
      body: 'Casos: ${d.cases} | Muertes: ${d.deaths} | Hoy: ${d.todayCases}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Datos COVID-19')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButton<String>(
              value: selected,
              isExpanded: true,
              items: countries
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                selected = value;
                _reload();
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<CovidData>(
                future: future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('No se pudo consultar: ${snapshot.error}'),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _reload,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    );
                  }
                  final d = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Ejercicio 1: Mostrar la bandera
                      if (d.flag.isNotEmpty)
                        Center(
                          child: Image.network(
                            d.flag,
                            height: 60,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.flag, size: 60),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        d.country,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      
                      // Ejercicio 5: Usando el widget reutilizable InfoRow
                      InfoRow(label: 'Casos acumulados', value: '${d.cases}'),
                      InfoRow(label: 'Casos del día', value: '${d.todayCases}'),
                      InfoRow(label: 'Muertes acumuladas', value: '${d.deaths}'),
                      InfoRow(label: 'Muertes del día', value: '${d.todayDeaths}'),
                      InfoRow(label: 'Recuperados', value: '${d.recovered}'),
                      InfoRow(label: 'Actualizado', value: formatDate(d.updated)),
                      
                      const Spacer(),
                      FilledButton(
                        onPressed: () => _notify(d),
                        child: const Text('Enviar notificación'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}