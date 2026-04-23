import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_view_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MyTravel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthViewModel>().logout(),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Home — in costruzione 🚧',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
