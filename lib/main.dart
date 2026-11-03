import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api_client.dart';
import 'core/router.dart';
import 'repositories/equipment_repository.dart';
import 'state/auth_notifier.dart';
import 'state/equipment_list_notifier.dart';
import 'widgets/inactivity_watcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  final prefs = await SharedPreferences.getInstance();
  runApp(CampRentApp(prefs: prefs));
}

class CampRentApp extends StatefulWidget {
  final SharedPreferences prefs;
  final Dio? dio;

  const CampRentApp({super.key, required this.prefs, this.dio});

  @override
  State<CampRentApp> createState() => _CampRentAppState();
}

class _CampRentAppState extends State<CampRentApp> {
  late final AuthNotifier _auth;
  late final Dio _dio;

  @override
  void initState() {
    super.initState();
    _dio =
        widget.dio ??
        buildDio(
          tokenProvider: () => _auth.accessToken,
          onRefreshToken: () => _auth.refreshTokens(),
          onForceLogout: () => _auth.logout(),
        );
    _auth = AuthNotifier(widget.prefs, _dio);
    _auth.restore();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        Provider<Dio>.value(value: _dio),
        Provider<EquipmentRepository>(create: (_) => EquipmentRepository(_dio)),
        ChangeNotifierProxyProvider<EquipmentRepository, EquipmentListNotifier>(
          create: (ctx) =>
              EquipmentListNotifier(ctx.read<EquipmentRepository>()),
          update: (_, repo, notifier) =>
              notifier ?? EquipmentListNotifier(repo),
        ),
      ],
      child: InactivityWatcher(
        timeout: const Duration(minutes: 3),
        onTimeout: () => _auth.logout(),
        child: MaterialApp.router(
          title: 'CampRent — Прокат снаряжения',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
          routerConfig: createRouter(_auth),
        ),
      ),
    );
  }
}
