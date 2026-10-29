import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nabhkrishi/features/location/providers/location_provider.dart';
import 'package:nabhkrishi/features/location/models/location_model.dart';
import 'package:nabhkrishi/features/irrigation/providers/irrigation_provider.dart';

void main() {
  test('Verify location updates and prediction fetching for both test locations', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // TEST 1: Latitude 28.4744, Longitude 77.5040
    print('--- Running TEST 1: 28.4744, 77.5040 ---');
    container.read(confirmedLocationProvider.notifier).state = LocationData(
      latitude: 28.4744,
      longitude: 77.5040,
      boundary: [],
    );

    final key1 = '28.4744,77.5040';
    
    // Check initial loading state
    var state1 = container.read(irrigationProvider(key1));
    expect(state1.isLoading, isTrue);
    print('State is loading: ${state1.isLoading}, loadingStage: ${state1.loadingStage}');

    // Wait for the API call to complete
    while (container.read(irrigationProvider(key1)).isLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    state1 = container.read(irrigationProvider(key1));
    expect(state1.errorMessage, isNull);
    expect(state1.data, isNotNull);
    final rec1 = state1.data!.recommendation;
    print('Recommendation 1: irrigation_mm = ${rec1.irrigationMm}, action_label = "${rec1.actionLabel}"');
    expect(rec1.irrigationMm, equals(0.0));
    expect(rec1.actionLabel, contains('No irrigation'));

    // TEST 2: Latitude 29.9038, Longitude 73.8772
    print('\n--- Running TEST 2: 29.9038, 73.8772 ---');
    container.read(confirmedLocationProvider.notifier).state = LocationData(
      latitude: 29.9038,
      longitude: 73.8772,
      boundary: [],
    );

    final key2 = '29.9038,73.8772';
    
    // Check initial loading state
    var state2 = container.read(irrigationProvider(key2));
    expect(state2.isLoading, isTrue);
    print('State is loading: ${state2.isLoading}, loadingStage: ${state2.loadingStage}');

    // Wait for the API call to complete
    while (container.read(irrigationProvider(key2)).isLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    state2 = container.read(irrigationProvider(key2));
    expect(state2.errorMessage, isNull);
    expect(state2.data, isNotNull);
    final rec2 = state2.data!.recommendation;
    print('Recommendation 2: irrigation_mm = ${rec2.irrigationMm}, action_label = "${rec2.actionLabel}"');
    expect(rec2.irrigationMm, equals(5.0));
    expect(rec2.actionLabel, contains('Apply 5 mm'));
  });
}
