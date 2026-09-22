import 'package:flutter/material.dart';
import 'package:{{project_name}}/networking/api_response.dart';
import 'package:{{project_name}}/utils/extensions/context_ext.dart';
import 'package:{{project_name}}/utils/extensions/exception_ext.dart';
import 'package:{{project_name}}/utils/widgets/ui/app_error_state.dart';
import 'package:{{project_name}}/utils/widgets/ui/app_loading_state.dart';

/// A declarative widget that binds an [ApiResponse] stream directly to the UI.
///
/// Automatically handles:
/// - Initial & Loading states -> [loadingWidget] or [AppLoadingState]
/// - Error state -> [errorBuilder] or [AppErrorState] (with auto-retry button if [onRetry] or [ErrorResponse.retry] is present)
/// - Completed state -> calls your [builder] with non-null typed data
///
/// ```dart
/// AppResponseBuilder<UserProfileResponse>(
///   stream: _bloc.profile$,
///   builder: (context, profile) => ProfileContentWidget(data: profile),
///   onRetry: () => _bloc.fetchProfile(),
/// )
/// ```
class AppResponseBuilder<T> extends StatelessWidget {
  const AppResponseBuilder({
    super.key,
    required this.stream,
    required this.builder,
    this.initialWidget,
    this.loadingWidget,
    this.errorBuilder,
    this.onRetry,
    this.errorTitle,
  });

  /// The reactive stream emitting [ApiResponse] states.
  final Stream<ApiResponse<T>> stream;

  /// Builder invoked when the response is [Completed].
  final Widget Function(BuildContext context, T data) builder;

  /// Optional widget displayed for [InitialResponse] state before any request starts.
  final Widget? initialWidget;

  /// Optional custom widget displayed while [Loading]. Defaults to [AppLoadingState].
  final Widget? loadingWidget;

  /// Optional custom error builder.
  final Widget Function(
    BuildContext context,
    String message,
    VoidCallback? onRetry,
  )? errorBuilder;

  /// Fallback retry callback if not specified inside the [Error] response state.
  final VoidCallback? onRetry;

  /// Optional title for default [AppErrorState].
  final String? errorTitle;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ApiResponse<T>>(
      stream: stream,
      builder: (context, snapshot) {
        final response = snapshot.data;

        return switch (response) {
          null ||
          InitialResponse<T>() =>
            initialWidget ?? loadingWidget ?? const AppLoadingState(),
          LoadingResponse<T>() => loadingWidget ?? const AppLoadingState(),
          SuccessResponse<T>(:final data) => builder(context, data),
          ErrorResponse<T>(:final error, :final retry) => errorBuilder != null
              ? errorBuilder!(
                  context,
                  error.userMessage(context),
                  retry ?? onRetry,
                )
              : AppErrorState(
                  title: errorTitle ?? context.l10n.errorTitle,
                  message: error.userMessage(context),
                  onRetry: retry ?? onRetry,
                ),
        };
      },
    );
  }
}
