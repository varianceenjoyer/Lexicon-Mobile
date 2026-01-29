import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/service_providers.dart';
import '../../../services/lexicon_core_service.dart';
import 'files_provider.dart';

/// Import state sealed class.
sealed class ImportState {
  const ImportState();
}

/// Idle state - no import in progress.
class ImportIdle extends ImportState {
  const ImportIdle();
}

/// Selecting file state.
class ImportSelecting extends ImportState {
  const ImportSelecting();
}

/// Processing state - import in progress.
class ImportProcessing extends ImportState {
  final double progress;
  final String fileName;

  const ImportProcessing({
    required this.progress,
    required this.fileName,
  });
}

/// Complete state - import finished successfully.
class ImportComplete extends ImportState {
  final SessionId sessionId;
  final String fileName;

  const ImportComplete({
    required this.sessionId,
    required this.fileName,
  });
}

/// Error state - import failed.
class ImportError extends ImportState {
  final String message;

  const ImportError({required this.message});
}

/// Import state notifier.
class ImportNotifier extends StateNotifier<ImportState> {
  final Ref _ref;
  bool _isCancelled = false;

  ImportNotifier(this._ref) : super(const ImportIdle());

  LexiconCoreService get _lexiconCore => _ref.read(lexiconCoreProvider);

  /// Start file selection.
  Future<void> selectFile() async {
    state = const ImportSelecting();

    try {
      // TODO: Use file_picker package to select file
      // For now, simulate file selection
      await Future.delayed(const Duration(milliseconds: 500));

      // Simulate selected file
      const mockFilePath = '/storage/emulated/0/Download/recording.mp3';
      await startImport(mockFilePath);
    } catch (e) {
      state = ImportError(message: 'Failed to select file: $e');
    }
  }

  /// Start import after file selected.
  Future<void> startImport(String filePath) async {
    _isCancelled = false;
    final fileName = filePath.split('/').last;

    state = ImportProcessing(progress: 0, fileName: fileName);

    try {
      final sessionId = await _lexiconCore.importAudioFile(
        filePath,
        const TranscriptionConfig(diarization: false),
        (progress) {
          if (!_isCancelled) {
            state = ImportProcessing(progress: progress, fileName: fileName);
          }
        },
      );

      if (_isCancelled) {
        await _lexiconCore.cancelImport(sessionId);
        state = const ImportIdle();
        return;
      }

      state = ImportComplete(sessionId: sessionId, fileName: fileName);

      // Refresh files list
      _ref.read(filesProvider.notifier).refresh();
    } catch (e) {
      if (!_isCancelled) {
        state = ImportError(message: 'Import failed: $e');
      }
    }
  }

  /// Cancel ongoing import.
  Future<void> cancelImport() async {
    _isCancelled = true;
    state = const ImportIdle();
  }

  /// Reset to idle state.
  void reset() {
    _isCancelled = false;
    state = const ImportIdle();
  }
}

/// Provider for Import state.
final importProvider = StateNotifierProvider<ImportNotifier, ImportState>(
  (ref) => ImportNotifier(ref),
);

/// Provider for checking if import is in progress.
final isImportingProvider = Provider<bool>((ref) {
  return ref.watch(importProvider) is ImportProcessing;
});

/// Provider for import progress.
final importProgressProvider = Provider<double?>((ref) {
  final state = ref.watch(importProvider);
  if (state is ImportProcessing) {
    return state.progress;
  }
  return null;
});
