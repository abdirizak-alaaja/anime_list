import '../errors/app_exception.dart';

/// The lifecycle of a single asynchronous load.
sealed class AsyncState<T> {
  const AsyncState();
}

final class AsyncLoading<T> extends AsyncState<T> {
  const AsyncLoading();
}

final class AsyncData<T> extends AsyncState<T> {
  const AsyncData(this.value);

  final T value;
}

final class AsyncFailure<T> extends AsyncState<T> {
  const AsyncFailure(this.error);

  final AppException error;
}
