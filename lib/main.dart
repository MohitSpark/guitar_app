import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guitar_app/screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'providers/guitar_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.black,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const GuitarApp());
}

class GuitarApp extends StatelessWidget {
  const GuitarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GuitarProvider(),
      child: MaterialApp(
        title: 'Guitar Pro',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF8B4513),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
