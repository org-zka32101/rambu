/// 乱舞将棋のゲーム状態管理（Riverpod）

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rambu_shogi/models/game_session.dart';
import 'package:rambu_shogi/models/move.dart';
import 'package:rambu_shogi/models/piece.dart';
import 'package:rambu_shogi/services/ai_engine.dart';
import 'package:rambu_shogi/services/game_logic.dart';
import 'package:uuid/uuid.dart';

/// ゲームセッションプロバイダ
final gameSessionProvider =
    StateNotifierProvider<GameSessionNotifier, GameSession?>((ref) {
  return GameSessionNotifier();
});

/// ゲーム状態管理
class GameSessionNotifier extends StateNotifier<GameSession?> {
  GameSessionNotifier() : super(null);

  /// ゲームを開始
  void startGame({
    Difficulty difficulty = Difficulty.normal,
    PlayerColor playerColor = PlayerColor.sente,
  }) {
    const uuid = Uuid();
    final sessionId = uuid.v4();

    state = GameSession(
      sessionId: sessionId,
      aiDifficulty: difficulty,
      playerColor: playerColor,
    );

    state!.start();
  }

  /// ゲームをリセット
  void resetGame() {
    state?.reset();
  }

  /// ゲームを再開始
  void restartGame() {
    if (state != null) {
      state!.reset();
      state!.start();
    }
  }

  /// ゲームを終了
  void endGame() {
    if (state != null) {
      state!.state = GameState.draw;
      state!.endedAt = DateTime.now();
    }
  }

  /// 着手を実行
  Future<bool> makeMove(
    Position from,
    Position to, {
    bool isRangedAttack = false,
  }) async {
    if (state == null || !state!.isPlaying) {
      return false;
    }

    try {
      // 着手の実行
      GameLogic.createAndApplyMove(
        state!,
        from,
        to,
        isRangedAttack: isRangedAttack,
      );

      // ゲーム終了チェック
      if (state!.isGameOver) {
        return true;
      }

      // AIターンの場合、非同期で思考実行
      if (state!.isCurrentPlayerAI) {
        // 次のフレームで実行するようスケジュール
        Future.delayed(Duration(milliseconds: 500), _performAIMove);
      }

      // リビルドトリガー
      state = state;
      return true;
    } catch (e) {
      print('Error making move: $e');
      return false;
    }
  }

  /// 後手ボーナス移動を実行
  Future<bool> makeSecondHandBonusMove(Position from, Position to) async {
    if (state == null || !state!.board.secondHandBonusAvailable) {
      return false;
    }

    try {
      GameLogic.createAndApplyMove(
        state!,
        from,
        to,
        isRangedAttack: false,
      );

      // リビルドトリガー
      state = state;
      return true;
    } catch (e) {
      print('Error making bonus move: $e');
      return false;
    }
  }

  /// AI の着手を実行
  Future<void> _performAIMove() async {
    if (state == null || !state!.isPlaying || !state!.isCurrentPlayerAI) {
      return;
    }

    try {
      final ai = AIEngine(difficulty: state!.aiDifficulty);
      final move = ai.findBestMove(state!);

      if (move.isRangedAttack) {
        await makeMove(move.from, move.to, isRangedAttack: true);
      } else {
        await makeMove(move.from, move.to);
      }
    } catch (e) {
      print('Error performing AI move: $e');
    }
  }
}

/// AI思考中フラグプロバイダ
final aiThinkingProvider = StateProvider<bool>((ref) => false);

/// 選択中の駒プロバイダ
final selectedPieceProvider =
    StateProvider<Position?>((ref) => null);

/// 移動可能な位置リストプロバイダ
final movablePositionsProvider =
    StateProvider<List<Position>>((ref) => []);

/// 飛び道具攻撃可能な位置リストプロバイダ
final rangedAttackPositionsProvider =
    StateProvider<List<Position>>((ref) => []);

/// 難易度プロバイダ
final difficultyProvider = StateProvider<Difficulty>((ref) => Difficulty.normal);

/// プレイヤーの色プロバイダ
final playerColorProvider =
    StateProvider<PlayerColor>((ref) => PlayerColor.sente);

/// ゲーム時間（秒）を監視するプロバイダ
final gameTimeProvider = StreamProvider<int>((ref) async* {
  final game = ref.watch(gameSessionProvider);
  if (game == null || !game.isPlaying) {
    yield 0;
    return;
  }

  final startedAt = game.startedAt ?? DateTime.now();
  int elapsed = 0;

  while (game.isPlaying) {
    elapsed = DateTime.now().difference(startedAt).inSeconds;
    yield elapsed;
    await Future.delayed(Duration(seconds: 1));
  }
});

/// 先手のHP合計プロバイダ
final whiteHPProvider = Provider<double>((ref) {
  final game = ref.watch(gameSessionProvider);
  if (game == null) return 0.0;
  return game.getWhiteTotalHP();
});

/// 後手のHP合計プロバイダ
final blackHPProvider = Provider<double>((ref) {
  final game = ref.watch(gameSessionProvider);
  if (game == null) return 0.0;
  return game.getBlackTotalHP();
});

/// ゲーム履歴プロバイダ
final moveHistoryProvider = Provider<List<Move>>((ref) {
  final game = ref.watch(gameSessionProvider);
  if (game == null) return [];
  return game.moveHistory.moves;
});
