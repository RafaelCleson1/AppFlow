import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meu_app/Models/receita.dart';
import 'package:meu_app/Pages/home_page.dart';

void main() {
  testWidgets('Mostra mensagem quando não há receitas', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(buscar: () async => <Receita>[]),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Minhas Receitas'), findsOneWidget);
    expect(find.text('Nenhuma receita cadastrada'), findsOneWidget);
  });

  testWidgets('Exibe as receitas carregadas', (WidgetTester tester) async {
    const receitas = [
      Receita(
        titulo: 'Bolo de cenoura',
        ingredientes: 'Cenoura, ovos, trigo',
        preparo: 'Misture tudo e asse.',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(buscar: () async => receitas),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Bolo de cenoura'), findsOneWidget);
    expect(find.text('Cenoura, ovos, trigo'), findsOneWidget);
  });

  testWidgets('Filtra as receitas pela busca', (WidgetTester tester) async {
    const receitas = [
      Receita(
        titulo: 'Bolo de cenoura',
        ingredientes: 'Cenoura, ovos, trigo',
        preparo: 'Misture tudo e asse.',
      ),
      Receita(
        titulo: 'Pão de queijo',
        ingredientes: 'Polvilho, queijo',
        preparo: 'Asse em forno médio.',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(buscar: () async => receitas),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'bolo');
    await tester.pumpAndSettle();

    expect(find.text('Bolo de cenoura'), findsOneWidget);
    expect(find.text('Pão de queijo'), findsNothing);
  });
}