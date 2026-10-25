import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/dashboard/screens/dashboard_page.dart';
import '../features/finance/providers/finance_provider.dart';
import '../features/finance/screens/add_edit_transaction_screen.dart';
import '../features/finance/screens/add_shipment_transaction_screen.dart';
import '../features/finance/screens/transactions_page.dart';
import '../features/tasks/providers/tasks_provider.dart';
import '../features/tasks/screens/task_form_screen.dart';
import '../features/tasks/screens/tasks_page.dart';
import '../core/theme/app_theme.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<FinanceProvider>().loadTransactions();
      context.read<TasksProvider>().load();
    });
  }

  void _push(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _openQuickAdd() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _QuickAction(
                icon: Icons.swap_vert,
                title: 'Add transaction',
                subtitle: 'Record an income or an expense',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _push(const AddEditTransactionScreen());
                },
              ),
              _QuickAction(
                icon: Icons.local_shipping_outlined,
                title: 'Add shipment transaction',
                subtitle: 'Track money against a shipment',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _push(const AddShipmentTransactionScreen());
                },
              ),
              _QuickAction(
                icon: Icons.checklist,
                title: 'New task',
                subtitle: 'Assign work to your team',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _push(const TaskFormScreen());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fab() {
    switch (_index) {
      case 0:
        return FloatingActionButton.extended(
          onPressed: _openQuickAdd,
          icon: const Icon(Icons.add),
          label: const Text('Quick add'),
        );
      case 1:
        return FloatingActionButton.extended(
          onPressed: () => _push(const AddEditTransactionScreen()),
          icon: const Icon(Icons.add),
          label: const Text('Add transaction'),
        );
      default:
        return FloatingActionButton.extended(
          onPressed: () => _push(const TaskFormScreen()),
          icon: const Icon(Icons.add_task),
          label: const Text('New task'),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          DashboardPage(onNavigate: (i) => setState(() => _index = i)),
          const TransactionsPage(),
          const TasksPage(),
        ],
      ),
      floatingActionButton: _fab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Tasks',
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppTheme.primaryBlue),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
    );
  }
}
