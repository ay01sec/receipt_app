import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '領収書アプリ',
      theme: ThemeData(
        fontFamily: 'NotoSansJP', // ここで登録したフォントを指定
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('フォントテスト')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '領収書',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Text(
                '¥12,000-',
                style: TextStyle(fontSize: 24),
              ),
              SizedBox(height: 10),
              Text(
                '但し、テスト品目として',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
