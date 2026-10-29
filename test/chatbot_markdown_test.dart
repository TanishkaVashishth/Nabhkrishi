import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

void main() {
  testWidgets('Chatbot Markdown rendering parses headings, bold, lists, and tables cleanly',
      (WidgetTester tester) async {
    const sampleMarkdown = '''
### 🌱 Disease / Problem
**Yellow Rust** is an important wheat disease.

🔍 Key Symptoms
• Small yellow-orange pustules
• Arranged in linear stripes

🛠️ Recommended Action
1. Spray recommended fungicide
2. Maintain proper irrigation

| Chemical | Dosage | Water Volume |
| --- | --- | --- |
| Propiconazole 25% EC | 200 ml/acre | 200 L/acre |
''';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MarkdownBody(
              data: sampleMarkdown,
              selectable: true,
            ),
          ),
        ),
      ),
    );

    // Verify rich elements exist
    expect(find.byType(MarkdownBody), findsOneWidget);

    // Verify table widget is built
    expect(find.byType(Table), findsOneWidget);

    // Verify text nodes are rendered properly without raw ### or ** visible
    expect(find.textContaining('###'), findsNothing);
    expect(find.textContaining('**Yellow Rust**'), findsNothing);
    expect(find.textContaining('Yellow Rust'), findsWidgets);
    expect(find.textContaining('Propiconazole 25% EC'), findsWidgets);
  });
}
