import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/lexicon_core_service.dart';

/// Global application state.
class AppState {
  final bool isRecording;
  final SessionId? activeSessionId;
  final ViewType activeView;
  final ThermalState thermalState;

  const AppState({
    this.isRecording = false,
    this.activeSessionId,
    this.activeView = ViewType.note,
    this.thermalState = ThermalState.nominal,
  });

  AppState copyWith({
    bool? isRecording,
    SessionId? activeSessionId,
    bool clearActiveSession = false,
    ViewType? activeView,
    ThermalState? thermalState,
  }) {
    return AppState(
      isRecording: isRecording ?? this.isRecording,
      activeSessionId:
          clearActiveSession ? null : (activeSessionId ?? this.activeSessionId),
      activeView: activeView ?? this.activeView,
      thermalState: thermalState ?? this.thermalState,
    );
  }
}

/// Device thermal state.
enum ThermalState {
  /// Normal operating temperature.
  nominal,

  /// Slightly elevated temperature.
  fair,

  /// High temperature, should reduce workload.
  serious,

  /// Critical temperature, must reduce workload immediately.
  critical,
}

/// Global app state notifier.
class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(const AppState());

  void setRecording(bool isRecording) {
    state = state.copyWith(isRecording: isRecording);
  }

  void setActiveSession(SessionId? id) {
    if (id == null) {
      state = state.copyWith(clearActiveSession: true);
    } else {
      state = state.copyWith(activeSessionId: id);
    }
  }

  void setActiveView(ViewType view) {
    state = state.copyWith(activeView: view);
  }

  void setThermalState(ThermalState thermalState) {
    state = state.copyWith(thermalState: thermalState);
  }
}

/// Provider for global app state.
final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>(
  (ref) => AppStateNotifier(),
);

/// Provider for checking if recording is active.
final isRecordingProvider = Provider<bool>((ref) {
  return ref.watch(appStateProvider).isRecording;
});

/// Provider for current thermal state.
final thermalStateProvider = Provider<ThermalState>((ref) {
  return ref.watch(appStateProvider).thermalState;
});
