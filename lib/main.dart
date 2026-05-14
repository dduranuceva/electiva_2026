import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:electiva_2026/providers/theme_provider.dart';
import 'package:electiva_2026/routes/app_router.dart';
import 'package:electiva_2026/services/categoria_service.dart';
import 'package:electiva_2026/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'themes/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.init();

  _listenCategoriaChanges();

  runApp(
    ChangeNotifierProvider<ThemeProvider>.value(
      value: themeProvider,
      child: const MyApp(),
    ),
  );
}

void _listenCategoriaChanges() {
  CategoriaService.watchChanges().listen((change) {
    final isNew = change.type == DocumentChangeType.added;
    NotificationService.show(
      id: change.categoria.id.hashCode.abs(),
      title: isNew ? 'Nueva categoría' : 'Categoría actualizada',
      body: isNew
          ? 'Se agregó: ${change.categoria.nombre}'
          : 'Se actualizó: ${change.categoria.nombre}',
    );
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp.router(
          title: 'Flutter - UCEVA',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          routerConfig: appRouter,
        );
      },
    );
  }
}
