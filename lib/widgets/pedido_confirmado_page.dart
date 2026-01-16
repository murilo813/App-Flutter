import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class PedidoConfirmadoPage extends StatefulWidget {
  const PedidoConfirmadoPage({super.key});

  @override
  State<PedidoConfirmadoPage> createState() => _PedidoConfirmadoPageState();
}

class _PedidoConfirmadoPageState extends State<PedidoConfirmadoPage> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/Success.json',
              width: 200,
              repeat: false,
            ),
            const SizedBox(height: 20),
            const Text(
              "Pedido Confirmado!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
