import 'package:flutter/material.dart';
import 'package:my_app2/screens/inventory/inventory_page.dart';
import 'package:my_app2/screens/jobs/jobs_page.dart';
import 'package:my_app2/screens/payment/payment_page.dart';
import 'package:my_app2/services/auth_service.dart';
import '../../auth/login_page.dart';

class Dashboard extends StatefulWidget {
  final String loggedInCode;

  const Dashboard({super.key, required this.loggedInCode});

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _currentIndex = 0;
  String? _branchName;
  String? _installerName;

  final tabs = [InventoryPage(), JobsPage(), PaymentPage()];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_buildTitle()),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Logout"),
                    content: const Text("Are you sure you want to logout?"),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await AuthService.clearAuthData();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                          );
                        },
                        child: const Text("Logout"),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey, // <-- Add this line
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: "Inventory",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: "Jobs"),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: "Payments"),
        ],
      ),
    );
  }

  String _buildTitle() {
    final branch = _branchName?.trim();
    final name = _installerName?.trim();
    if ((branch == null || branch.isEmpty) && (name == null || name.isEmpty)) {
      return 'Dashboard';
    }
    if (branch != null &&
        branch.isNotEmpty &&
        name != null &&
        name.isNotEmpty) {
      return 'Dashboard — Branch: $branch — $name';
    }
    if (branch != null && branch.isNotEmpty) {
      return 'Dashboard — Branch: $branch';
    }
    return 'Dashboard — $name';
  }
}
