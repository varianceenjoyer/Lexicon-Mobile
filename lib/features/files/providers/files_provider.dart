import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/service_providers.dart';
import '../../../services/lexicon_core_service.dart';

/// Sort order for file list.
enum SortOrder {
  dateDesc,
  dateAsc,
  nameAsc,
  nameDesc,
  durationDesc,
}

/// Files view state.
class FilesState {
  final List<SessionSummary> sessions;
  final SessionSummary? selectedSession;
  final Session? selectedSessionDetail;
  final SortOrder sortOrder;
  final String searchQuery;
  final List<SearchResult> searchResults;
  final bool isLoading;
  final bool isSearching;
  final String? errorMessage;

  const FilesState({
    this.sessions = const [],
    this.selectedSession,
    this.selectedSessionDetail,
    this.sortOrder = SortOrder.dateDesc,
    this.searchQuery = '',
    this.searchResults = const [],
    this.isLoading = false,
    this.isSearching = false,
    this.errorMessage,
  });

  FilesState copyWith({
    List<SessionSummary>? sessions,
    SessionSummary? selectedSession,
    bool clearSelectedSession = false,
    Session? selectedSessionDetail,
    bool clearSelectedSessionDetail = false,
    SortOrder? sortOrder,
    String? searchQuery,
    List<SearchResult>? searchResults,
    bool? isLoading,
    bool? isSearching,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FilesState(
      sessions: sessions ?? this.sessions,
      selectedSession: clearSelectedSession
          ? null
          : (selectedSession ?? this.selectedSession),
      selectedSessionDetail: clearSelectedSessionDetail
          ? null
          : (selectedSessionDetail ?? this.selectedSessionDetail),
      sortOrder: sortOrder ?? this.sortOrder,
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: searchResults ?? this.searchResults,
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Files view state notifier.
class FilesNotifier extends StateNotifier<FilesState> {
  final Ref _ref;

  FilesNotifier(this._ref) : super(const FilesState()) {
    _loadSessions();
  }

  LexiconCoreService get _lexiconCore => _ref.read(lexiconCoreProvider);

  Future<void> _loadSessions() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final sessions = await _lexiconCore.listSessions();
      final sorted = _sortSessions(sessions, state.sortOrder);
      state = state.copyWith(
        sessions: sorted,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load sessions: $e',
      );
    }
  }

  /// Refresh session list.
  Future<void> refresh() async {
    await _loadSessions();
  }

  /// Select a session for preview.
  Future<void> selectSession(SessionId id) async {
    try {
      // Find in list
      final summary = state.sessions.firstWhere((s) => s.id == id);
      state = state.copyWith(
        selectedSession: summary,
        clearSelectedSessionDetail: true,
      );

      // Load full session
      final session = await _lexiconCore.getSession(id);
      if (session != null) {
        state = state.copyWith(selectedSessionDetail: session);
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to load session: $e',
      );
    }
  }

  /// Clear selected session.
  void clearSelection() {
    state = state.copyWith(
      clearSelectedSession: true,
      clearSelectedSessionDetail: true,
    );
  }

  /// Set sort order.
  void setSortOrder(SortOrder order) {
    if (order == state.sortOrder) return;

    final sorted = _sortSessions(state.sessions, order);
    state = state.copyWith(
      sortOrder: order,
      sessions: sorted,
    );
  }

  /// Search transcriptions.
  Future<void> search(String query) async {
    if (query.isEmpty) {
      clearSearch();
      return;
    }

    state = state.copyWith(
      searchQuery: query,
      isSearching: true,
    );

    try {
      final results = await _lexiconCore.searchTranscriptions(query);
      state = state.copyWith(
        searchResults: results,
        isSearching: false,
      );
    } catch (e) {
      state = state.copyWith(
        isSearching: false,
        errorMessage: 'Search failed: $e',
      );
    }
  }

  /// Clear search.
  void clearSearch() {
    state = state.copyWith(
      searchQuery: '',
      searchResults: [],
      isSearching: false,
    );
  }

  /// Delete session.
  Future<void> deleteSession(SessionId id) async {
    try {
      await _lexiconCore.deleteSession(id);

      // Remove from list
      final updated = state.sessions.where((s) => s.id != id).toList();

      // Clear selection if deleted
      final clearSelection = state.selectedSession?.id == id;

      state = state.copyWith(
        sessions: updated,
        clearSelectedSession: clearSelection,
        clearSelectedSessionDetail: clearSelection,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to delete session: $e',
      );
    }
  }

  /// Rename session.
  Future<void> renameSession(SessionId id, String newTitle) async {
    try {
      await _lexiconCore.renameSession(id, newTitle);

      // Update in list
      final updated = state.sessions.map((s) {
        if (s.id == id) {
          return SessionSummary(
            id: s.id,
            title: newTitle,
            createdAt: s.createdAt,
            updatedAt: DateTime.now(),
            duration: s.duration,
            viewType: s.viewType,
          );
        }
        return s;
      }).toList();

      state = state.copyWith(sessions: updated);

      // Reload selection if renamed
      if (state.selectedSession?.id == id) {
        await selectSession(id);
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to rename session: $e',
      );
    }
  }

  List<SessionSummary> _sortSessions(
      List<SessionSummary> sessions, SortOrder order) {
    final sorted = [...sessions];
    switch (order) {
      case SortOrder.dateDesc:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case SortOrder.dateAsc:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case SortOrder.nameAsc:
        sorted.sort((a, b) => a.title.compareTo(b.title));
      case SortOrder.nameDesc:
        sorted.sort((a, b) => b.title.compareTo(a.title));
      case SortOrder.durationDesc:
        sorted.sort((a, b) =>
            (b.duration?.inSeconds ?? 0).compareTo(a.duration?.inSeconds ?? 0));
    }
    return sorted;
  }
}

/// Provider for Files view state.
final filesProvider = StateNotifierProvider<FilesNotifier, FilesState>(
  (ref) => FilesNotifier(ref),
);

/// Provider for session list.
final sessionsProvider = Provider<List<SessionSummary>>((ref) {
  return ref.watch(filesProvider).sessions;
});

/// Provider for selected session.
final selectedSessionProvider = Provider<SessionSummary?>((ref) {
  return ref.watch(filesProvider).selectedSession;
});

/// Provider for search results.
final searchResultsProvider = Provider<List<SearchResult>>((ref) {
  return ref.watch(filesProvider).searchResults;
});
