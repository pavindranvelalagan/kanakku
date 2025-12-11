import 'dart:async';

import 'package:flutter/material.dart';

import 'screens/home.dart';
import 'screens/profile.dart';
import 'screens/subscriptions.dart';
import 'screens/transactions_list.dart';
import 'storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await LedgerRepository.bootstrap();
  await repository.ensureMonthlySubscriptionCharges(DateTime.now());
  final controller = LedgerController(repository);
  runApp(KanakkuApp(controller: controller));
}

class KanakkuApp extends StatelessWidget {
  const KanakkuApp({super.key, required this.controller});

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
      home: SplashGate(controller: controller),
    );
  }
}

class SplashGate extends StatefulWidget {
  const SplashGate({super.key, required this.controller});
  final LedgerController controller;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  bool _showMain = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    Timer(const Duration(milliseconds: 1500), () {
      setState(() => _showMain = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showMain) {
      return MainShell(controller: widget.controller);
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.teal.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      'K',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Kanakku',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.teal.shade800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.controller});

  final LedgerController controller;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybePromptName(context);
    });
  }

  Future<void> _maybePromptName(BuildContext context) async {
    final name = widget.controller.settings.userName.trim();
    if (name.isNotEmpty) return;
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Your name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Enter your name',
            hintText: 'Pavindran',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () async {
              await widget.controller.setUserName(controller.text);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final title = widget.controller.effectiveAppTitle();
        return Scaffold(
          appBar: AppBar(
            title: Text(title),
          ),
          body: _buildBody(),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) {
              setState(() => _index = value);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.group_outlined),
                selectedIcon: Icon(Icons.group),
                label: 'Friends',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: 'Subscriptions',
              ),
              NavigationDestination(
                icon: Icon(Icons.arrow_downward_outlined),
                selectedIcon: Icon(Icons.arrow_downward),
                label: 'You Owe',
              ),
              NavigationDestination(
                icon: Icon(Icons.arrow_upward_outlined),
                selectedIcon: Icon(Icons.arrow_upward),
                label: 'Owed To You',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    switch (_index) {
      case 0:
        return HomeScreen(controller: widget.controller);
      case 1:
        return SubscriptionScreen(controller: widget.controller);
      case 2:
        return TransactionsListScreen(
          controller: widget.controller,
          filter: TransactionFilter.youOwe,
        );
      case 3:
        return TransactionsListScreen(
          controller: widget.controller,
          filter: TransactionFilter.owedToYou,
        );
      case 4:
        return ProfileScreen(controller: widget.controller);
      default:
        return HomeScreen(controller: widget.controller);
    }
  }
}
