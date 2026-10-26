import 'package:dio/dio.dart';
import 'package:recipe_app/features/dashboard/model/stats_model.dart';
import 'package:recipe_app/features/dashboard/repo/dashboard_repo.dart';
import 'package:recipe_app/networking/api_exceptions.dart';
import 'package:recipe_app/networking/api_response.dart';
import 'package:recipe_app/networking/cancel_token_owner.dart';
import 'package:rxdart/rxdart.dart';

final class DashboardBloc with CancelTokenOwner {
  DashboardBloc({DashboardRepo? repo}) : _repo = repo ?? DashboardRepo();

  final DashboardRepo _repo;
  final CompositeSubscription subscriptions = CompositeSubscription();

  final BehaviorSubject<ApiResponse<StatsModel>> _stats =
      BehaviorSubject.seeded(const ApiResponse.initial());
  final BehaviorSubject<ApiResponse<Map<String, dynamic>>> _profile =
      BehaviorSubject.seeded(const ApiResponse.initial());

  Stream<ApiResponse<StatsModel>> get stats$ => _stats.stream;
  Stream<ApiResponse<Map<String, dynamic>>> get profile$ => _profile.stream;

  // Recipe E.
  // recipe-block: 9

  Future<void> _loadProfile(CancelToken token, {bool refresh = false}) async {
    try {
      final json = await _repo.fetchProfile(cancelToken: token);
      _emitProfile(ApiResponse.completed(json));
    } on RequestCancelledException {
      // Superseded.
    } on ApiException catch (e) {
      _emitProfile(ApiResponse.error(e));
    }
  }

  void _emitStats(ApiResponse<StatsModel> state) {
    if (!_stats.isClosed) _stats.add(state);
  }

  void _emitProfile(ApiResponse<Map<String, dynamic>> state) {
    if (!_profile.isClosed) _profile.add(state);
  }

  // Recipe G.
  // recipe-block: 11

  // Recipe H.
  // recipe-block: 13

  void dispose() {
    cancelRequests();
    subscriptions.dispose();
    _stats.close();
    _profile.close();
    _tab.close();
  }
}
