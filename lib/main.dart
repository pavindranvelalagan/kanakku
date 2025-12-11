import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models.dart';
import 'screens/home.dart';
import 'screens/profile.dart';
import 'screens/subscriptions.dart';
import 'screens/transactions_list.dart';
import 'storage.dart';
import 'theme/app_theme.dart';
import 'theme/colors.dart';
import 'widgets/app_nav_bar.dart';

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
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
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


class SplashGate extends StatefulWidget {
  const SplashGate({super.key, required this.controller});
  final LedgerController controller;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _showMain = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _showMain = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showMain) {
      return MainShell(controller: widget.controller);
    }
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  'K',
                  style: GoogleFonts.outfit(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'Kanakku',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppColors.primary,
              ),
            ),
          ],
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
        return Scaffold(
          extendBody: true, // Allow body to go behind the floating nav
          body: Stack(
            fit: StackFit.expand,
            children: [
              _buildBody(),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: AppNavBar(
                  currentIndex: _index,
                  onTap: (value) => setState(() => _index = value),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    final bottomPadding = EdgeInsets.only(bottom: 100.0); 

    Widget content;
    switch (_index) {
      case 0:
        content = HomeScreen(controller: widget.controller);
        break;
      case 1:
        content = SubscriptionScreen(controller: widget.controller);
        break;
      case 2:
        content = TransactionsListScreen(
          controller: widget.controller,
          filter: TransactionFilter.youOwe,
        );
        break;
      case 3:
        content = TransactionsListScreen(
          controller: widget.controller,
          filter: TransactionFilter.owedToYou,
        );
        break;
      case 4:
        content = ProfileScreen(controller: widget.controller);
        break;
      default:
        content = HomeScreen(controller: widget.controller);
    }
    
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 140),
      child: Container(
        key: ValueKey(_index),
        padding: bottomPadding,
        child: content,
      ),
    );
  }
}
