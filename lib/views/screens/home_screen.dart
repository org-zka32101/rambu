/// ホーム画面（メニュー）

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rambu_shogi/models/game_session.dart';
import 'package:rambu_shogi/views/screens/game_screen.dart';
import 'package:rambu_shogi/viewmodels/game_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('乱舞将棋'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ロゴ・タイトル
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  '乱舞将棋',
                  style: TextStyle(
                    fontSize: 48.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'HP制と飛び道具を持つ観戦映え特化の将棋',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16.0, color: Colors.grey),
                ),
              ),

              const SizedBox(height: 48.0),

              // ボタングループ
              _buildDifficultyButton(
                context,
                ref,
                difficulty: Difficulty.easy,
                label: '初級',
                color: Colors.green,
                description: '先手勝率 40-50%',
              ),

              const SizedBox(height: 16.0),

              _buildDifficultyButton(
                context,
                ref,
                difficulty: Difficulty.normal,
                label: '中級（推奨）',
                color: Colors.blue,
                description: '先手勝率 50±3%',
              ),

              const SizedBox(height: 16.0),

              _buildDifficultyButton(
                context,
                ref,
                difficulty: Difficulty.hard,
                label: '上級',
                color: Colors.red,
                description: '先手勝率 60%+',
              ),

              const SizedBox(height: 48.0),

              // その他ボタン
              SizedBox(
                width: 240.0,
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: チュートリアル画面へ遷移
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('チュートリアルはまだ実装されていません')),
                    );
                  },
                  child: const Text('遊び方'),
                ),
              ),

              const SizedBox(height: 8.0),

              SizedBox(
                width: 240.0,
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: 設定画面へ遷移
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('設定はまだ実装されていません')),
                    );
                  },
                  child: const Text('設定'),
                ),
              ),

              const SizedBox(height: 24.0),
            ],
          ),
        ),
      ),
    );
  }

  /// 難易度ボタンを作成
  Widget _buildDifficultyButton(
    BuildContext context,
    WidgetRef ref, {
    required Difficulty difficulty,
    required String label,
    required Color color,
    required String description,
  }) {
    return SizedBox(
      width: 240.0,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        onPressed: () {
          // ゲームを開始
          ref.read(gameSessionProvider.notifier).startGame(
                difficulty: difficulty,
                playerColor: PlayerColor.sente,
              );

          // ゲーム画面へ遷移
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const GameScreen(),
            ),
          );
        },
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              description,
              style: const TextStyle(
                fontSize: 12.0,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
