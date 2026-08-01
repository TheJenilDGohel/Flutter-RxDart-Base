import 'package:redux/redux.dart';
import 'package:snug_logger/snug_logger.dart';
import 'package:{{project_name}}/redux/app_state.dart';

/// Logs every dispatched action and the resulting state using [snugLog].
void loggingMiddleware(
  Store<AppState> store,
  Object action,
  NextDispatcher next,
) {
  snugLog('Redux Action: ${action.runtimeType}', logType: LogType.info);
  next(action);
  snugLog('Redux State: ${store.state}', logType: LogType.info);
}
