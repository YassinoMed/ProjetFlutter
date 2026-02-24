/// Base UseCase for Clean Architecture
/// Enforces the Single Responsibility Principle
library;

import 'package:dartz/dartz.dart';

import '../errors/failures.dart';

/// Base use case with parameters
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Use case with no parameters
abstract class UseCaseNoParams<Type> {
  Future<Either<Failure, Type>> call();
}

/// Use case with stream return
abstract class StreamUseCase<Type, Params> {
  Stream<Either<Failure, Type>> call(Params params);
}

/// No parameters marker class
class NoParams {
  const NoParams();
}
