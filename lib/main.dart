import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_life/screen/onboarding.dart';
import 'package:focus_life/screen/splash.dart';
import 'package:focus_life/provider/onboarding_provider.dart';

void main() {
  runApp(
    // ProviderScope는 앱의 최상위에 위치해야 합니다
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Safe Work',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SplashRiverpod(),
    );
  }
}
