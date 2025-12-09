import 'package:flutter/material.dart';

import 'screens/home.dart';
import 'storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await LedgerRepository.bootstrap();
  await repository.ensureMonthlySubscriptionCharges(DateTime.now());
  final controller = LedgerController(repository);
  runApp(UniShareApp(controller: controller));
}

class UniShareApp extends StatelessWidget {
  const UniShareApp({super.key, required this.controller});

  final LedgerController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kanakku',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey.shade50,
      ),
      home: HomeScreen(controller: controller),
    );
  }
}
