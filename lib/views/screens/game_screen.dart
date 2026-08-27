/// ゲーム画面（Flame盤面表示）

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rambu_shogi/models/game_session.dart';
import 'package:rambu_shogi/views/widgets/flame_game.dart';
import 'package:rambu_shogi/viewmodels/game_provider.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameSessionProvider);
    final gameTime = ref.watch(gameTimeProvider);

    if (game == null) {
      return const Scaffold(
        body: Center(child: Text('ゲームセッションが初期化されていません')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('乱舞将棋 - 対局中'),
        centerTitle: true,
        actions: [
          // ゲーム時間表示
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: gameTime.when(
              data: (time) => Center(
                child: Text('${time}秒'),
              ),
              loading: () => const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (_, __) => const Text('エラー'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 対戦情報バー
          Container(
            color: Colors.grey.shade200,
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 先手情報
                _buildPlayerInfo(
                  label: '先手',
                  isCurrentTurn: game.currentPlayer == PlayerColor.sente,
                  hp: ref.watch(whiteHPProvider),
                ),

                // ターン情報
                Center(
                  child: Column(
                    children: [
                      Text(
                        game.currentPlayer == PlayerColor.sente ? '先手' : '後手',
                        style: const TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${game.turnCount}手',
                        style: const TextStyle(fontSize: 12.0),
                      ),
                    ],
                  ),
                ),

                // 後手情報
                _buildPlayerInfo(
                  label: '後手',
                  isCurrentTurn: game.currentPlayer == PlayerColor.gote,
                  hp: ref.watch(blackHPProvider),
                ),
              ],
            ),
          ),

          // Flame盤面
          Expanded(
            child: Container(
              color: Colors.grey.shade100,
              child: const RambuShogiGameWidget(),
            ),
          ),

          // ゲーム終了時のダイアログまたはボタン
          if (game.isGameOver) ...[
            Container(
              color: Colors.grey.shade200,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    game.winner == PlayerColor.sente ? '先手勝利！' : '後手勝利！',
                    style: const TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('ホームに戻る'),
                  ),
                ],
              ),
            ),
          ] else ...[
            // ゲーム中のボタン
            Container(
              color: Colors.grey.shade200,
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (game.board.secondHandBonusAvailable)
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        onPressed: () {
                          // TODO: 後手ボーナス移動UI
                        },
                        child: const Text('追加移動'),
                      ),
                    )
                  else
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // TODO: 棋譜表示 or その他
                        },
                        child: const Text('棋譜'),
                      ),
                    ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // ゲーム中止確認
                        _showConfirmDialog(context, ref);
                      },
                      child: const Text('中止'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// プレイヤー情報を表示
  Widget _buildPlayerInfo({
    required String label,
    required bool isCurrentTurn,
    required double hp,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        border: Border.all(
          color: isCurrentTurn ? Colors.blue : Colors.grey,
          width: isCurrentTurn ? 2.0 : 1.0,
        ),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isCurrentTurn ? Colors.blue : Colors.black,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            'HP: ${hp.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 12.0),
          ),
        ],
      ),
    );
  }

  /// ゲーム中止確認ダイアログ
  void _showConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('対局を中止しますか？'),
        content: const Text('この対局は記録されません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              ref.read(gameSessionProvider.notifier).endGame();
              Navigator.pop(context);
              Navigator.pop(context);  // ゲーム画面を閉じる
            },
            child: const Text('中止'),
          ),
        ],
      ),
    );
  }
}
