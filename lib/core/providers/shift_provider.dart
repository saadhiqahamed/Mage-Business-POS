import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final shiftProvider = StateNotifierProvider<ShiftNotifier, ShiftState>((ref) {
  return ShiftNotifier();
});

class ShiftState {
  final bool isLoading;
  final bool isShiftActive;
  final DateTime? shiftStartTime;
  final int startingCashCents;

  ShiftState({
    this.isLoading = true,
    this.isShiftActive = false,
    this.shiftStartTime,
    this.startingCashCents = 0,
  });

  ShiftState copyWith({
    bool? isLoading,
    bool? isShiftActive,
    DateTime? shiftStartTime,
    int? startingCashCents,
  }) {
    return ShiftState(
      isLoading: isLoading ?? this.isLoading,
      isShiftActive: isShiftActive ?? this.isShiftActive,
      shiftStartTime: shiftStartTime ?? this.shiftStartTime,
      startingCashCents: startingCashCents ?? this.startingCashCents,
    );
  }
}

class ShiftNotifier extends StateNotifier<ShiftState> {
  ShiftNotifier() : super(ShiftState()) {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final isActive = prefs.getBool('shift_active') ?? false;
    final startStr = prefs.getString('shift_start');
    final startCash = prefs.getInt('shift_cash') ?? 0;

    DateTime? startTime;
    if (isActive && startStr != null) {
      startTime = DateTime.tryParse(startStr);
    }

    state = ShiftState(
      isLoading: false,
      isShiftActive: isActive,
      shiftStartTime: startTime,
      startingCashCents: startCash,
    );
  }

  Future<void> startShift(int startingCashCents) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setBool('shift_active', true);
    await prefs.setString('shift_start', now.toIso8601String());
    await prefs.setInt('shift_cash', startingCashCents);

    state = ShiftState(
      isLoading: false,
      isShiftActive: true,
      shiftStartTime: now,
      startingCashCents: startingCashCents,
    );
  }

  Future<void> endShift() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('shift_active', false);
    await prefs.remove('shift_start');
    await prefs.remove('shift_cash');

    state = ShiftState(
      isLoading: false,
      isShiftActive: false,
      shiftStartTime: null,
      startingCashCents: 0,
    );
  }
}
