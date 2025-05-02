import 'package:flutter/material.dart';
import 'store_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  final Map<String, String> stores = const {
    'aurora': 'Aurora',
    'imbuia': 'Imbuia',
    'vilanova': 'Vila Nova',
    'belavista': 'Bela Vista',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            const Text(
              'AgroZecão',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ...stores.entries.map((entry) {
              final storeKey = entry.key;
              final storeLabel = entry.value;
              return _buildStoreButton(context, storeKey, storeLabel);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreButton(BuildContext context, String storeKey, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: 250, 
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StorePage(storeName: storeKey),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
