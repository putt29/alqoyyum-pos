import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'repositories/admin_repository.dart';
import 'repositories/auth_repository.dart';
import 'repositories/catalog_repository.dart';
import 'repositories/report_repository.dart';
import 'repositories/transaction_repository.dart';
import 'services/api_client.dart';
import 'services/local_settings.dart';
import 'services/token_storage.dart';
import 'state/auth_controller.dart';
import 'state/cart_controller.dart';
import 'state/catalog_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');

  final settings = LocalSettings(await SharedPreferences.getInstance());
  final tokens = TokenStorage();
  final api = ApiClient(settings: settings, tokens: tokens);

  final authRepo = AuthRepository(api);
  final catalogRepo = CatalogRepository(api);
  final auth = AuthController(repository: authRepo, tokens: tokens);
  api.onUnauthorized = auth.handleUnauthorized;

  runApp(MultiProvider(
    providers: [
      Provider<LocalSettings>.value(value: settings),
      Provider<ApiClient>.value(value: api),
      Provider<CatalogRepository>.value(value: catalogRepo),
      Provider<TransactionRepository>.value(value: TransactionRepository(api)),
      Provider<ReportRepository>.value(value: ReportRepository(api)),
      Provider<AdminRepository>.value(value: AdminRepository(api)),
      ChangeNotifierProvider<AuthController>.value(value: auth),
      ChangeNotifierProvider<CatalogController>(create: (_) => CatalogController(catalogRepo)),
      ChangeNotifierProvider<CartController>(create: (_) => CartController()),
    ],
    child: const AlqoyyumApp(),
  ));
}
