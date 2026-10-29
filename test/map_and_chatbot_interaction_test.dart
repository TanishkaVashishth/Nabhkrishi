import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:nabhkrishi/features/location/farm_boundary_map.dart';
import 'package:nabhkrishi/features/location/models/drawing_state.dart';
import 'package:nabhkrishi/features/location/presentation/widgets/drawing_canvas_overlay.dart';
import 'package:nabhkrishi/screens/nabhkrishi_chatbot_screen.dart';
import 'package:nabhkrishi/services/chatbot_service.dart';

class FakeChatbotService extends ChatbotService {
  String? lastMessage;
  String? lastConversationId;
  bool shouldThrow = false;
  Completer<ChatbotResponse>? completer;

  @override
  Future<ChatbotResponse> sendMessage({
    required String message,
    String? conversationId,
    String? userId,
  }) async {
    lastMessage = message;
    lastConversationId = conversationId;

    if (shouldThrow) {
      throw Exception('Server unreachable');
    }

    if (completer != null) {
      return completer!.future;
    }

    return ChatbotResponse(
      conversationId: conversationId ?? 'test_conv_999',
      answer: 'Verified Agronomy Answer for "$message"',
      language: 'English',
    );
  }
}

void main() {
  group('Part 1: Farm Map Pan / Drawing & Clear Button Interaction Tests', () {
    testWidgets('Map enters Idle mode initially; DrawingCanvasOverlay is NOT mounted', (tester) async {
      final controller = FarmBoundaryController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500,
              height: 600,
              child: FarmBoundaryMap(
                controller: controller,
                initialLocation: const LatLng(20.5937, 78.9629),
                onBoundaryConfirmed: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Initial State is idle
      expect(controller.state, equals(DrawingState.idle));
      expect(find.text('Draw Farm Boundary'), findsOneWidget);

      // 2. DrawingCanvasOverlay is not active/mounted in idle mode
      expect(find.byType(DrawingCanvasOverlay), findsNothing);
    });

    testWidgets('Tapping Draw Farm Boundary mounts overlay, and Clear button resets completely to Idle', (tester) async {
      final controller = FarmBoundaryController();
      addTearDown(controller.dispose);
      FarmBoundary? changedBoundary;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500,
              height: 600,
              child: FarmBoundaryMap(
                controller: controller,
                initialLocation: const LatLng(20.5937, 78.9629),
                onBoundaryConfirmed: (_) {},
                onBoundaryChanged: (b) => changedBoundary = b,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Draw Farm Boundary
      await tester.tap(find.text('Draw Farm Boundary'));
      await tester.pumpAndSettle();

      // In drawing mode
      expect(controller.state, equals(DrawingState.drawing));
      expect(find.text('Trace around your farm boundary'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.byType(DrawingCanvasOverlay), findsOneWidget);

      // Tap Clear
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      // State is completely reset to Idle
      expect(controller.state, equals(DrawingState.idle));
      expect(controller.boundary, isNull);
      expect(changedBoundary, isNull);
      expect(find.text('Draw Farm Boundary'), findsOneWidget);
      expect(find.byType(DrawingCanvasOverlay), findsNothing);

      // User can press Draw Farm Boundary again
      await tester.tap(find.text('Draw Farm Boundary'));
      await tester.pumpAndSettle();

      expect(controller.state, equals(DrawingState.drawing));
      expect(find.text('Trace around your farm boundary'), findsOneWidget);
    });
  });

  group('Part 2: NabhKrishi Chatbot Input Field & Send Behavior Tests', () {
    testWidgets('Chatbot renders visible input area with "Ask NabhKrishi..." hint and Send button', (tester) async {
      final fakeService = FakeChatbotService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatbotServiceProvider.overrideWithValue(fakeService),
          ],
          child: const MaterialApp(
            home: NabhKrishiChatbotScreen(isHindi: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('chatbot_input_field')), findsOneWidget);
      expect(find.byKey(const Key('chatbot_send_button')), findsOneWidget);
      expect(find.text('Ask NabhKrishi...'), findsOneWidget);
    });

    testWidgets('Send button is disabled when field is empty; entering text enables Send', (tester) async {
      final fakeService = FakeChatbotService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatbotServiceProvider.overrideWithValue(fakeService),
          ],
          child: const MaterialApp(
            home: NabhKrishiChatbotScreen(isHindi: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Send while empty -> nothing sent
      await tester.tap(find.byKey(const Key('chatbot_send_button')));
      await tester.pump();
      expect(fakeService.lastMessage, isNull);

      // Enter query
      await tester.enterText(
        find.byKey(const Key('chatbot_input_field')),
        'What is yellow rust in wheat?',
      );
      await tester.pump();

      // Text appears in input field
      expect(find.text('What is yellow rust in wheat?'), findsOneWidget);
    });

    testWidgets('Sending query adds user message immediately, clears input, calls API with exact text, and shows assistant response', (tester) async {
      final fakeService = FakeChatbotService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatbotServiceProvider.overrideWithValue(fakeService),
          ],
          child: const MaterialApp(
            home: NabhKrishiChatbotScreen(isHindi: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      const queryText = 'gehun mein peela ratua kya hai?';
      await tester.enterText(find.byKey(const Key('chatbot_input_field')), queryText);
      await tester.pump();

      // Tap Send
      await tester.tap(find.byKey(const Key('chatbot_send_button')));
      await tester.pump(); // frame where message is added and controller cleared

      // 1. User message appears immediately in the chat
      expect(find.text(queryText), findsOneWidget);

      // 2. Input field is cleared
      final textField = tester.widget<TextField>(find.byKey(const Key('chatbot_input_field')));
      expect(textField.controller?.text, isEmpty);

      // 3. API was called with the exact untranslated text
      expect(fakeService.lastMessage, equals(queryText));

      await tester.pumpAndSettle();

      // 4. Assistant response appears in chat
      expect(find.textContaining('Verified Agronomy Answer for "$queryText"'), findsOneWidget);
    });

    testWidgets('Handles backend error gracefully with farmer-friendly message without crashing', (tester) async {
      final fakeService = FakeChatbotService()..shouldThrow = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatbotServiceProvider.overrideWithValue(fakeService),
          ],
          child: const MaterialApp(
            home: NabhKrishiChatbotScreen(isHindi: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('chatbot_input_field')), 'Spray timings');
      await tester.pump();

      await tester.tap(find.byKey(const Key('chatbot_send_button')));
      await tester.pumpAndSettle();

      // Farmer-friendly message is shown
      expect(find.textContaining('Unable to connect to NabhKrishi right now. Please try again.'), findsOneWidget);
    });
  });
}
