import 'package:material_ui/material_ui.dart';

import 'core/theme/app_theme.dart';

/// Root widget for the Cat Directory application.
class CatDirectoryApp extends StatelessWidget {
  const CatDirectoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cat Directory',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const Scaffold(
        body: Center(
          child: Text('Cat Directory App'),
        ),
      ),
    );
  }
}
