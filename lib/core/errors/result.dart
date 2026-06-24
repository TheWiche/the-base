import 'failures.dart';

/// Functional result type used at every layer boundary.
///
/// Every repository method and use case returns [Result<T>] instead of
/// throwing exceptions. Callers exhaustively handle both branches via
/// Dart 3 pattern matching:
///
/// ```dart
/// final result = await repository.requestIncrease();
/// switch (result) {
///   case Ok(:final value): // use value
///   case Err(:final failure): // show failure.message
/// }
/// ```
sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  /// Unwraps the value. Throws [StateError] if this is [Err].
  /// Only call when you are certain the result is [Ok] — prefer pattern matching.
  T get value {
    final self = this;
    if (self is Ok<T>) return self.value;
    throw StateError('Called .value on an Err result: ${(self as Err<T>).failure}');
  }

  /// Transforms the success value without altering the error branch.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
        Ok(:final value) => Ok(transform(value)),
        Err(:final failure) => Err(failure),
      };

  /// Chains a fallible operation on the success value.
  Future<Result<R>> flatMapAsync<R>(
    Future<Result<R>> Function(T value) transform,
  ) async =>
      switch (this) {
        Ok(:final value) => transform(value),
        Err(:final failure) => Err(failure),
      };
}

/// Success branch — wraps a value of type [T].
final class Ok<T> extends Result<T> {
  const Ok(this.value);

  @override
  final T value;

  @override
  String toString() => 'Ok($value)';
}

/// Error branch — wraps a [Failure] describing what went wrong.
final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;

  /// Casts the error to a different success type without touching the failure.
  Err<R> cast<R>() => Err<R>(failure);

  @override
  String toString() => 'Err(${failure.message})';
}

// ── Convenience constructors ───────────────────────────────────────────────

/// Shorthand to create [Ok] results inline.
Result<T> ok<T>(T value) => Ok(value);

/// Shorthand to create [Err] results inline.
Result<T> err<T>(Failure failure) => Err(failure);
