import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/config/app_config.dart';
import 'core/storage/local_storage_service.dart';
import 'core/utils/app_bloc_observer.dart';
import 'features/app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set global BLoC observer for logging transitions & errors
  Bloc.observer = AppBlocObserver();

  // Initialize local persistent storage
  final storageService = await LocalStorageService.init();

  const config = AppConfig(
    environment: AppEnvironment.dev,
    appTitle: 'Flutter BLoC & GoRouter',
  );

  runApp(App(localStorageService: storageService, config: config));
}
