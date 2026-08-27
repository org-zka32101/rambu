/// 結果画面

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rambu_shogi/models/game_session.dart';
import 'package:rambu_shogi/viewmodels/game_provider.dart';

class ResultScreen extends ConsumerWidget {
  final GameSession game;

  const ResultScreen({
    Key? key,
    required this.game,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duration = game.getGameDurationSeconds() ?? 0;
    final winner = game.winner;

    return Scaffold(
      appBar: AppBar(
        title: const Text('対局結果'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 結果表示
              Container(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    if (winner == PlayerColor.sente)
                      const Text(
                        '🎉 先手勝利！',
                        style: TextStyle(
                          fontSize: 36.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      )
                    else
                      const Text(
                        '🎉 後手勝利！',
                        style: TextStyle(
                          fontSize: 36.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    const SizedBox(height: 12.0),
                    Text(
                      'おめでとうございます！',
                      style: TextStyle(
                        fontSize: 18.0,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // ゲーム統計
              Container(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatRow('ターン数', '${game.turnCount}手'),
                    const SizedBox(height: 8.0),
                    _buildStatRow(
                      'ゲーム時間',
                      '${duration}秒',
                    ),
                    const SizedBox(height: 8.0),
                    _buildStatRow(
                      '難易度',
                      game.aiDifficulty.label,
                    ),
                    const SizedBox(height: 8.0),
                    _buildStatRow(
                      '先手HP',
                      game.getWhiteTotalHP().toStringAsFixed(1),
                    ),
                    const SizedBox(height: 8.0),
                    _buildStatRow(
                      '後手HP',
                      game.getBlackTotalHP().toStringAsFixed(1),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24.0),

              // ハイライト生成中の通知（後で実装）
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.blue.shade300),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue),
                      SizedBox(width: 12.0),
                      Expanded(
                        child: Text(
                          'ハイライト動画を生成中です...\n（Phase 3で実装予定）',
                          style: TextStyle(fontSize: 12.0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24.0),

              // ボタングループ
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                        ),
                        onPressed: () {
                          // TODO: ハイライト動画を見る
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('ハイライト機能は Phase 3 で実装予定です')),
                          );
                        },
                        child: const Text('ハイライト動画を見る'),
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          backgroundColor: Colors.grey.shade600,
                        ),
                        onPressed: () {
                          // TODO: シェア機能
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('シェア機能は Phase 3 で実装予定です')),
                          );
                        },
                        child: const Text('シェアする'),
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                        ),
                        onPressed: () {
                          // ホームに戻る
                          Navigator.of(context).popUntil(
                            (route) => route.isFirst,
                          );
                        },
                        child: const Text('ホームに戻る'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24.0),
            ],
          ),
        ),
      ),
    );
  }

  /// 統計行を表示
  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14.0,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
