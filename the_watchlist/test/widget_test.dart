import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:the_watchlist/widgets/estrellas.dart';

void main() {
  testWidgets('renders the publication rating', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Estrellas(promedio: 3.5))),
    );

    expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
    expect(find.byIcon(Icons.star_half_rounded), findsOneWidget);
    expect(find.byIcon(Icons.star_outline_rounded), findsOneWidget);

  });
}
