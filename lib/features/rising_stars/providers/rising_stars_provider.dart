import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/config/api_config.dart';
import '../../../core/services/storage_service.dart';
import '../models/artist_ranking_model.dart';

/// State for Rising Stars feature
class RisingStarsState {
  final List<ArtistRanking> artists;
  final RankingPagination? pagination;
  final RisingStarsConfig? config;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final TimeWindow timeWindow;
  final FormulaType formula;

  const RisingStarsState({
    this.artists = const [],
    this.pagination,
    this.config,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.timeWindow = TimeWindow.thirtyDays,
    this.formula = FormulaType.balanced,
  });

  RisingStarsState copyWith({
    List<ArtistRanking>? artists,
    RankingPagination? pagination,
    RisingStarsConfig? config,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    TimeWindow? timeWindow,
    FormulaType? formula,
  }) {
    return RisingStarsState(
      artists: artists ?? this.artists,
      pagination: pagination ?? this.pagination,
      config: config ?? this.config,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      timeWindow: timeWindow ?? this.timeWindow,
      formula: formula ?? this.formula,
    );
  }
}

/// Rising Stars provider with filtering and pagination
class RisingStarsNotifier extends StateNotifier<RisingStarsState> {
  final Dio _dio;
  final StorageService _storage;

  RisingStarsNotifier(this._dio, this._storage) : super(const RisingStarsState());

  /// Load or refresh Rising Stars rankings
  Future<void> loadRankings({
    TimeWindow? timeWindow,
    FormulaType? formula,
    bool refresh = false,
  }) async {
    if (state.isLoading) return;

    try {
      // Update filters if provided
      final newTimeWindow = timeWindow ?? state.timeWindow;
      final newFormula = formula ?? state.formula;

      // Set loading state
      state = state.copyWith(
        isLoading: true,
        error: null,
        timeWindow: newTimeWindow,
        formula: newFormula,
      );

      // Clear artists if refreshing or filters changed
      if (refresh || timeWindow != null || formula != null) {
        state = state.copyWith(artists: []);
      }

      // Build query parameters
      final queryParams = {
        'sortBy': 'risingScore',
        'timeWindow': newTimeWindow.key,
        'formula': newFormula.key,
        'page': '1',
        'limit': '20',
      };

      // Get auth token
      final token = await _storage.getAccessToken();
      final headers = token != null
          ? {'Authorization': 'Bearer $token'}
          : <String, String>{};

      // Make API request
      final response = await _dio.get(
        '/api/${ApiConfig.apiVersion}/users/discover',
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      print('Rising Stars API Response: ${response.data}');

      // Parse response
      final risingStarsResponse = RisingStarsResponse.fromJson(response.data);

      state = state.copyWith(
        artists: risingStarsResponse.artists,
        pagination: risingStarsResponse.pagination,
        config: risingStarsResponse.risingStarsConfig,
        isLoading: false,
      );
    } catch (e) {
      print('Rising Stars Error: $e');
      print('Stack trace: ${StackTrace.current}');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load rankings: ${e.toString()}',
      );
    }
  }

  /// Load more artists (pagination)
  Future<void> loadMore() async {
    final pagination = state.pagination;
    if (pagination == null || !pagination.hasMore || state.isLoadingMore) {
      return;
    }

    try {
      state = state.copyWith(isLoadingMore: true);

      final nextPage = pagination.currentPage + 1;

      // Build query parameters
      final queryParams = {
        'sortBy': 'risingScore',
        'timeWindow': state.timeWindow.key,
        'formula': state.formula.key,
        'page': nextPage.toString(),
        'limit': '20',
      };

      // Get auth token
      final token = await _storage.getAccessToken();
      final headers = token != null
          ? {'Authorization': 'Bearer $token'}
          : <String, String>{};

      // Make API request
      final response = await _dio.get(
        '/api/${ApiConfig.apiVersion}/users/discover',
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      // Parse response
      final risingStarsResponse = RisingStarsResponse.fromJson(response.data);

      // Append new artists
      state = state.copyWith(
        artists: [...state.artists, ...risingStarsResponse.artists],
        pagination: risingStarsResponse.pagination,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: 'Failed to load more: ${e.toString()}',
      );
    }
  }

  /// Change time window filter
  Future<void> changeTimeWindow(TimeWindow timeWindow) async {
    if (timeWindow != state.timeWindow) {
      await loadRankings(timeWindow: timeWindow, refresh: true);
    }
  }

  /// Change formula filter
  Future<void> changeFormula(FormulaType formula) async {
    if (formula != state.formula) {
      await loadRankings(formula: formula, refresh: true);
    }
  }

  /// Refresh rankings with current filters
  Future<void> refresh() async {
    await loadRankings(refresh: true);
  }
}

/// Provider for Rising Stars feature
final risingStarsProvider =
    StateNotifierProvider<RisingStarsNotifier, RisingStarsState>((ref) {
  final dio = Dio();
  final storage = StorageService();
  return RisingStarsNotifier(dio, storage);
});
