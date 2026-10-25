import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/finance/providers/finance_provider.dart';
import 'features/tasks/providers/tasks_provider.dart';
import 'shell/app_shell.dart';

void main() {
  runApp(const RoboxFinanceApp());
}

class RoboxFinanceApp extends StatelessWidget {
  const RoboxFinanceApp({super.key});

  Widget _home(AuthProvider auth) {
    switch (auth.status) {
      case AuthStatus.unknown:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.unauthenticated:
        return const LoginScreen();
      case AuthStatus.authenticated:
        return const AppShell();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider()..init(),
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MultiProvider(
            // New key per user: fresh app state on login/logout.
            key: ValueKey(auth.user?.id ?? 'signed-out'),
            providers: [
              ChangeNotifierProvider(create: (_) => FinanceProvider()),
              ChangeNotifierProvider(create: (_) => TasksProvider()),
            ],
            child: MaterialApp(
              title: 'Robox Finance',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              home: _home(auth),
            ),
          );
        },
      ),
    );
  }
}
