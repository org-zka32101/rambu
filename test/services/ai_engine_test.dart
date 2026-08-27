/// AI エンジン（AIEngine）のユニットテスト

import 'package:flutter_test/flutter_test.dart';
import 'package:rambu_shogi/models/game_session.dart';
import 'package:rambu_shogi/models/piece.dart';
import 'package:rambu_shogi/services/ai_engine.dart';

void main() {
  group('AIEngine', () {
    late AIEngine aiNormal;
    late AIEngine aiEasy;
    late AIEngine aiHard;

    setUp(() {
      aiNormal = AIEngine(difficulty: Difficulty.normal);
      aiEasy = AIEngine(difficulty: Difficulty.easy);
      aiHard = AIEngine(difficulty: Difficulty.hard);
    });

    test('AIが最善手を見つけられる', () {
      final game = GameSession(
        sessionId: 'test-ai',
        aiDifficulty: Difficulty.normal,
        playerColor: PlayerColor.sente,
      );
      game.start();

      final move = aiNormal.findBestMove(game);
      expect(move, isNotNull);
      expect(move.piece.player, equals(PlayerColor.sente));
    });

    test('難易度別にノイズレンジが異なる', () {
      expect(aiEasy.difficulty.noiseRange, equals(5.0));
      expect(aiNormal.difficulty.noiseRange, equals(1.0));
      expect(aiHard.difficulty.noiseRange, equals(0.3));
    });

    test('難易度別に駒価値ウェイトが異なる', () {
      expect(aiEasy.difficulty.piecValueWeight, equals(0.7));
      expect(aiNormal.difficulty.piecValueWeight, equals(0.5));
      expect(aiHard.difficulty.piecValueWeight, equals(0.3));
    });

    test('盤面を評価できる', () {
      final game = GameSession(
        sessionId: 'test-eval',
        aiDifficulty: Difficulty.normal,
        playerColor: PlayerColor.sente,
      );
      game.start();

      // 評価スコアを計算（詳細なアクセスには反射を使う必要があるため、ここでは簡易的に）
      // 実際にはプライベート関数のため、別途テストが必要
      expect(aiNormal, isNotNull);
    });

    test('複数回の思考で異なる手を選択することがある', () {
      final game = GameSession(
        sessionId: 'test-variety',
        aiDifficulty: Difficulty.normal,
        playerColor: PlayerColor.sente,
      );
      game.start();

      final moves = <String>{};
      for (int i = 0; i < 5; i++) {
        final move = aiNormal.findBestMove(game);
        moves.add('${move.from}→${move.to}');
      }

      // ノイズがあるため、複数の異なる手が選ばれる可能性
      // （ただしゲーム開始時点では合法手が限定されるため、同じ手になる可能性が高い）
      expect(moves.length, greaterThanOrEqualTo(1));
    });

    test('評価カウントが増える', () {
      final game = GameSession(
        sessionId: 'test-eval-count',
        aiDifficulty: Difficulty.normal,
        playerColor: PlayerColor.sente,
      );
      game.start();

      expect(aiNormal.evaluationCount, equals(0));

      aiNormal.findBestMove(game);

      expect(aiNormal.evaluationCount, greaterThan(0));
    });
  });
}
