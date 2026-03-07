import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const ManuscriptHubApp());
}

class ManuscriptHubApp extends StatelessWidget {
  const ManuscriptHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Manuscript Hub',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE86B24)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF3EFE0),
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
