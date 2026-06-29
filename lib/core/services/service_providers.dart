import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database_service.dart';
import 'storage_service.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  throw UnimplementedError('databaseService must be overridden in ProviderScope');
});

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('storageService must be overridden in ProviderScope');
});
