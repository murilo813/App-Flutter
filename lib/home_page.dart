import 'package:flutter/material.dart';
import 'store_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
            _buildEstoqueButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildEstoqueButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: 250, 
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StorePage(storeName: 'Estoques'), 
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
          child: const Text('Estoque'),
        ),
      ),
    );
  }
}
