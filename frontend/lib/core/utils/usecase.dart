/// Base UseCase for Clean Architecture
/// Enforces the Single Responsibility Principle
library;

import 'package:dartz/dartz.dart';

import '../errors/failures.dart';

/// Base use case with parameters
abstract class UseCase<Result, Params> {
  Future<Either<Failure, Result>> call(Params params);
}

/// Use case with no parameters
abstract class UseCaseNoParams<Result> {
  Future<Either<Failure, Result>> call();
}

/// Use case with stream return
abstract class StreamUseCase<Result, Params> {
  Stream<Either<Failure, Result>> call(Params params);
}

/// No parameters marker class
class NoParams {
  const NoParams();
}
