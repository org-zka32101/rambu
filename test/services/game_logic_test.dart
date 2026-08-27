/// ゲームロジック（GameLogic）のユニットテスト

import 'package:flutter_test/flutter_test.dart';
import 'package:rambu_shogi/models/board.dart';
import 'package:rambu_shogi/models/game_session.dart';
import 'package:rambu_shogi/models/move.dart';
import 'package:rambu_shogi/models/piece.dart';
import 'package:rambu_shogi/services/game_logic.dart';

void main() {
  group('GameLogic', () {
    late Board board;
    late GameSession game;

    setUp(() {
      board = Board();
      game = GameSession(
        sessionId: 'test-session',
        aiDifficulty: Difficulty.normal,
        playerColor: PlayerColor.sente,
      );
      game.start();
    });

    test('駒の移動可能な範囲を取得できる', () {
      // 先手の歩
      final pawn = board.getPieceAt(Position(5, 3));
      expect(pawn, isNotNull);
      expect(pawn!.type, equals(PieceType.pawn));

      final movable = GameLogic.getMovablePositions(board, Position(5, 3), pawn!);
      expect(movable.length, greaterThan(0));
      expect(movable.contains(Position(5, 4)), isTrue);
    });

    test('飛び道具の攻撃可能な範囲を取得できる', () {
      // 先手の角を (5, 5) に配置
      board.setPieceAt(Position(5, 1), null);
      final bishop = Piece(type: PieceType.bishop, player: PlayerColor.sente);
      board.setPieceAt(Position(5, 5), bishop);

      final ranged =
          GameLogic.getRangedAttackPositions(board, Position(5, 5), bishop);

      // 斜めに3マス先まで攻撃可能
      expect(ranged.length, greaterThan(0));
    });

    test('着手が合法かどうか判定できる', () {
      game.state = GameState.playing;
      game.currentPlayer = PlayerColor.sente;

      final pawn = board.getPieceAt(Position(5, 3));
      expect(pawn, isNotNull);

      // 前への移動は合法
      final isLegal = GameLogic.isMoveLegal(
        game,
        pawn!,
        Position(5, 3),
        Position(5, 4),
      );
      expect(isLegal, isTrue);
    });

    test('ゲーム中でない時は着手が合法にならない', () {
      game.state = GameState.waiting;

      final pawn = board.getPieceAt(Position(5, 3));
      expect(pawn, isNotNull);

      final isLegal = GameLogic.isMoveLegal(
        game,
        pawn!,
        Position(5, 3),
        Position(5, 4),
      );
      expect(isLegal, isFalse);
    });

    test('有効な着手リストを取得できる', () {
      game.state = GameState.playing;
      game.currentPlayer = PlayerColor.sente;

      final moves = GameLogic.getLegalMoves(game);
      expect(moves.length, greaterThan(0));
    });

    test('先手が有利な場合を判定できる', () {
      // 先手のHP を増やす
      for (final piece in board.getWhitePieces()) {
        if (piece.type != PieceType.king) {
          piece.fullHeal();
        }
      }

      // 後手のHP を減らす
      for (final piece in board.getBlackPieces()) {
        if (piece.type != PieceType.king && piece.currentHP > 1) {
          piece.takeDamage(1);
        }
      }

      final isFavor = GameLogic.isGameInFavorOfSente(board);
      expect(isFavor, isTrue);
    });
  });

  group('Move', () {
    test('クリティカルアタックを判定できる', () {
      // HP >= 2 → 1以下でクリティカル
      final move = Move(
        from: Position(1, 1),
        to: Position(2, 2),
        player: PlayerColor.sente,
        piece: Piece(type: PieceType.bishop, player: PlayerColor.sente),
        moveType: MoveType.ranged,
        damageDealt: 1,
        targetHPBefore: 2,
        targetHPAfter: 1,
      );

      expect(move.isCritical, isTrue);
    });

    test('大ダメージを判定できる', () {
      final move = Move(
        from: Position(1, 1),
        to: Position(2, 2),
        player: PlayerColor.sente,
        piece: Piece(type: PieceType.bishop, player: PlayerColor.sente),
        moveType: MoveType.ranged,
        damageDealt: 4,
      );

      expect(move.isBigDamage, isTrue);
    });

    test('着手をクローンできる', () {
      final original = Move(
        from: Position(1, 1),
        to: Position(2, 2),
        player: PlayerColor.sente,
        piece: Piece(type: PieceType.pawn, player: PlayerColor.sente),
      );

      final cloned = original.clone();

      expect(identical(original, cloned), isFalse);
      expect(cloned.from, equals(original.from));
      expect(cloned.to, equals(original.to));
      expect(cloned.player, equals(original.player));
    });
  });
}
