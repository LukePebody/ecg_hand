import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'screens/connection_screen.dart';
import 'services/connection_service.dart';

void main() {
  // Configure logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
    if (record.error != null) {
      print('Error: ${record.error}');
    }
    if (record.stackTrace != null) {
      print('Stack trace: ${record.stackTrace}');
    }
  });

  runApp(const ECGHandApp());
}

class ECGHandApp extends StatelessWidget {
  const ECGHandApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ConnectionService())],
      child: MaterialApp(
        title: 'ECG Hand',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Roboto',
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true,
        ),
        home: const ConnectionScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
