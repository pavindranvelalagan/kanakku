import 'dart:async';

import 'package:flutter/material.dart';

import 'models.dart';
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
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return MaterialApp(
          title: 'Kanakku',
          theme: _lightTheme,
          darkTheme: _darkTheme,
          themeMode: _themeModeFrom(settings: controller.settings),
          home: SplashGate(controller: controller),
        );
      },
    );
  }
}

ThemeMode _themeModeFrom({required AppSettings settings}) {
  switch (settings.themeMode) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

final _accentBlue = const Color(0xFF0097B2);

final _lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    primary: _accentBlue,
    secondary: _accentBlue,
    surface: Colors.white,
    background: Colors.white,
  ),
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    elevation: 0.5,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Colors.black,
    foregroundColor: Colors.white,
  ),
);

final _darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    primary: _accentBlue,
    secondary: _accentBlue,
    surface: Colors.black,
    background: Colors.black,
  ),
  scaffoldBackgroundColor: Colors.black,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.black,
    foregroundColor: Colors.white,
    elevation: 0.5,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
  ),
);

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
            centerTitle: false,
          ),
          body: _buildBody(),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _index,
            onTap: (value) => setState(() => _index = value),
            showSelectedLabels: false,
            showUnselectedLabels: false,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.group_outlined),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.arrow_downward_outlined),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.arrow_upward_outlined),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                label: '',
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
