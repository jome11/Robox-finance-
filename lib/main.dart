import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/finance/providers/finance_provider.dart';
import 'features/finance/screens/dashboard_screen.dart';

void main() {
  runApp(const RoboxFinanceApp());
}

class RoboxFinanceApp extends StatelessWidget {
  const RoboxFinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FinanceProvider()),
      ],
      child: MaterialApp(
        title: 'Robox Finance',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const DashboardScreen(),
      ),
    );
  }
}
