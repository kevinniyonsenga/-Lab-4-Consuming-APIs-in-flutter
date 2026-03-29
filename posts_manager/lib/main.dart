import 'package:flutter/material.dart';
import 'screens/post_list_screen.dart';

void main() {
  runApp(const PostsManagerApp());
}

class PostsManagerApp extends StatelessWidget {
  const PostsManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Posts Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A5F),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(centerTitle: true),
        cardTheme:
            const CardThemeData(surfaceTintColor: Colors.white), // ← fixed
      ),
      home: const PostListScreen(),
    );
  }
}
