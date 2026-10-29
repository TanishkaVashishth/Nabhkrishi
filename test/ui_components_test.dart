import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nabhkrishi/core/theme/app_colors.dart';
import 'package:nabhkrishi/features/crop_disease/services/crop_disease_service.dart';
import 'package:nabhkrishi/shared/widgets/bento_stat_card.dart';
import 'package:nabhkrishi/shared/widgets/circular_health_gauge.dart';
import 'package:nabhkrishi/shared/widgets/floating_bottom_nav_bar.dart';
import 'package:nabhkrishi/shared/widgets/ppo_decision_card.dart';
import 'package:nabhkrishi/shared/widgets/tractor_icon.dart';

void main() {
  group('NabhKrishi Redesigned UI Component Tests', () {
    testWidgets('TractorIcon renders without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TractorIcon(size: 40, color: AppColors.primary),
          ),
        ),
      );

      expect(find.byType(TractorIcon), findsOneWidget);
    });

    testWidgets('CircularHealthGauge renders score and optimal badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CircularHealthGauge(
              score: 88,
              isHindi: false,
              size: 150,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('88'), findsOneWidget);
      expect(find.text('/100'), findsOneWidget);
      expect(find.text('Optimal'), findsOneWidget);
    });

    testWidgets('BentoStatCard displays label, value, and subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BentoStatCard(
              icon: Icons.water_drop_rounded,
              iconBg: AppColors.mintBg,
              iconColor: AppColors.primary,
              label: 'Water Deficit',
              value: '4.2 mm',
              valueColor: AppColors.primary,
              subtitle: 'Optimal Moisture',
            ),
          ),
        ),
      );

      expect(find.text('Water Deficit'), findsOneWidget);
      expect(find.text('4.2 mm'), findsOneWidget);
      expect(find.text('Optimal Moisture'), findsOneWidget);
    });

    testWidgets('PPODecisionCard displays action number and localized advisory', (tester) async {
      const decision = PpoDecision(
        actionId: 2,
        actionName: 'Apply 15mm Irrigation',
        descriptionEn: 'Soil water potential indicates mild stress. Apply 15mm water.',
        descriptionHi: 'मिट्टी में नमी की कमी है। 15 मिमी सिंचाई करें।',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PPODecisionCard(
              decision: decision,
              isHindi: false,
            ),
          ),
        ),
      );

      expect(find.textContaining('Action 2'), findsOneWidget);
      expect(find.textContaining('Soil water potential'), findsOneWidget);
    });

    testWidgets('FloatingBottomNavBar displays all 5 tabs and responds to selection', (tester) async {
      int tappedIndex = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingBottomNavBar(
              selectedIndex: 0,
              onTabSelected: (idx) => tappedIndex = idx,
              isHindi: false,
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Insights'), findsOneWidget);
      expect(find.text('Scan'), findsOneWidget);
      expect(find.text('Farm'), findsOneWidget);
      expect(find.text('Ask Nabh'), findsOneWidget);

      // Tap on Scan tab (index 2)
      await tester.tap(find.text('Scan'));
      expect(tappedIndex, equals(2));
    });
  });
}
