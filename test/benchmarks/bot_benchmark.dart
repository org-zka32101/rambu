/// Bot AI の先手勝率計測ベンチマーク
///
/// 実行: `dart run test/benchmarks/bot_benchmark.dart`
/// 目標: 中級の先手勝率 50±3%

import 'dart:io';
import 'package:rambu_shogi/models/game_session.dart';
import 'package:rambu_shogi/models/piece.dart';
import 'package:rambu_shogi/services/ai_engine.dart';
import 'package:rambu_shogi/services/game_logic.dart';

void main() async {
  print('🤖 乱舞将棋 Bot AI ベンチマーク');
  print('================================\n');

  // 難易度別に計測
  await benchmarkDifficulty(Difficulty.normal, games: 100);
  await benchmarkDifficulty(Difficulty.easy, games: 20);
  await benchmarkDifficulty(Difficulty.hard, games: 20);
}

/// 難易度別ベンチマークを実行
Future<void> benchmarkDifficulty(Difficulty difficulty, {int games = 100}) async {
  print('📊 難易度: ${difficulty.label}');
  print('予定対局数: $games');
  print('---');

  int whiteWins = 0;
  int blackWins = 0;
  int totalTurns = 0;
  final gameDurations = <int>[];

  for (int i = 0; i < games; i++) {
    final (winner, turns, duration) = await playGame(difficulty);

    if (winner == PlayerColor.sente) {
      whiteWins++;
    } else {
      blackWins++;
    }

    totalTurns += turns;
    gameDurations.add(duration);

    // 進捗表示
    if ((i + 1) % 10 == 0 || i + 1 == games) {
      final progress = ((i + 1) / games * 100).toStringAsFixed(1);
      print('進行中... $progress% ($whiteWins先手 vs $blackWins後手)');
    }
  }

  // 結果計算
  final whiteWinRate = whiteWins / games * 100;
  final avgTurns = totalTurns / games;
  final avgDuration = gameDurations.reduce((a, b) => a + b) / games;

  print('\n✅ 結果:');
  print('  先手勝率: ${whiteWinRate.toStringAsFixed(1)}% ($whiteWins/$games)');
  print('  後手勝率: ${(100 - whiteWinRate).toStringAsFixed(1)}% ($blackWins/$games)');
  print('  平均ターン: ${avgTurns.toStringAsFixed(1)}');
  print('  平均ゲーム時間: ${avgDuration.toStringAsFixed(1)}秒');

  // バランス判定
  final target = 50.0;
  final tolerance = 3.0;
  final diff = (whiteWinRate - target).abs();

  if (diff <= tolerance) {
    print('  🎯 バランス判定: ✅ 良好（目標範囲内）');
  } else if (whiteWinRate > target + tolerance) {
    print('  ⚠️ バランス判定: 先手優位（補正が必要）');
  } else {
    print('  ⚠️ バランス判定: 後手優位（補正が必要）');
  }

  print('\n');
}

/// 単一ゲームを実行
/// 返値: (勝者, ターン数, ゲーム時間秒数)
Future<(PlayerColor, int, int)> playGame(Difficulty difficulty) async {
  final game = GameSession(
    sessionId: 'bench-${DateTime.now().millisecondsSinceEpoch}',
    aiDifficulty: difficulty,
    playerColor: PlayerColor.sente,
  );

  game.start();
  final startTime = DateTime.now();

  final aiSente = AIEngine(difficulty: difficulty);
  final aiGote = AIEngine(difficulty: difficulty);

  // 最大500手でゲーム終了
  while (!game.isGameOver && game.turnCount < 500) {
    try {
      if (game.currentPlayer == PlayerColor.sente) {
        // 先手（AI）のターン
        if (!game.board.secondHandBonusAvailable) {
          final move = aiSente.findBestMove(game);
          game.applyMove(move);
        } else {
          // 後手ボーナス時は先手パス
          game.board.secondHandBonusAvailable = false;
          game.turnCount++;
          game.currentPlayer = game.currentPlayer.opponent;
        }
      } else {
        // 後手（AI）のターン
        if (!game.board.secondHandBonusAvailable) {
          final move = aiGote.findBestMove(game);
          game.applyMove(move);
        } else {
          // 後手ボーナス移動
          final moves = GameLogic.getLegalMoves(game);
          if (moves.isNotEmpty) {
            game.applyMove(moves.first);
          }
        }
      }
    } catch (e) {
      // エラーが発生した場合はゲーム終了
      print('⚠️ ゲーム実行エラー: $e');
      break;
    }
  }

  final endTime = DateTime.now();
  final duration = endTime.difference(startTime).inSeconds;

  final winner = game.winner ?? PlayerColor.gote;  // デフォルト: 後手
  return (winner, game.turnCount, duration);
}
