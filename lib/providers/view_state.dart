/// Represents the four canonical UI states every screen in the app can be in.
enum ViewStatus { initial, loading, success, empty, error }

class ViewState<T> {
  final ViewStatus status;
  final T? data;
  final String? errorMessage;

  const ViewState._({required this.status, this.data, this.errorMessage});

  const ViewState.initial() : this._(status: ViewStatus.initial);
  const ViewState.loading() : this._(status: ViewStatus.loading);
  const ViewState.success([T? data])
      : this._(status: ViewStatus.success, data: data);
  const ViewState.empty() : this._(status: ViewStatus.empty);
  const ViewState.error(String message)
      : this._(status: ViewStatus.error, errorMessage: message);

  bool get isLoading => status == ViewStatus.loading;
  bool get isError => status == ViewStatus.error;
  bool get isEmpty => status == ViewStatus.empty;
  bool get isSuccess => status == ViewStatus.success;
}
