import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/widgets/gradientgreen.dart'; // Ajuste o caminho conforme seu projeto

void main() {
  group('Testes de Gradiente - GradientGreen', () {
    
    test('O gradiente primário deve ter as 3 cores corretas', () {
      // Verificamos se a lista de cores tem 3 itens
      expect(GradientGreen.primary.colors.length, 3);
      
      // Verificamos se a primeira cor é o verde escuro esperado
      expect(GradientGreen.primary.colors[0], const Color(0xFF15803D));
      
      // Verificamos se o alinhamento está correto
      expect(GradientGreen.primary.begin, Alignment.bottomLeft);
    });

    test('O gradiente accent deve ter as 2 cores corretas', () {
      expect(GradientGreen.accent.colors.length, 2);
      expect(GradientGreen.accent.colors[1], const Color(0xFF049271));
    });

    test('Os stops do gradiente primário devem estar distribuídos corretamente', () {
      expect(GradientGreen.primary.stops, [0.0, 0.5, 1.0]);
    });
  });
}
