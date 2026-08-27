/// 盤面（Board）のユニットテスト

import 'package:flutter_test/flutter_test.dart';
import 'package:rambu_shogi/models/board.dart';
import 'package:rambu_shogi/models/move.dart';
import 'package:rambu_shogi/models/piece.dart';

void main() {
  group('Board', () {
    late Board board;

    setUp(() {
      board = Board();
    });

    test('初期化時に全駒が配置される', () {
      final pieces = board.getAllPieces();
      expect(pieces.length, equals(32)); // 先手16駒 + 後手16駒
    });

    test('先手の王が初期位置にある', () {
      final whiteKing = board.getKing(PlayerColor.sente);
      expect(whiteKing, isNotNull);
      expect(whiteKing!.type, equals(PieceType.king));
    });

    test('後手の王が初期位置にある', () {
      final blackKing = board.getKing(PlayerColor.gote);
      expect(blackKing, isNotNull);
      expect(blackKing!.type, equals(PieceType.king));
    });

    test('座標で駒を取得できる', () {
      final piece = board.getPieceAt(Position(5, 1));
      expect(piece, isNotNull);
      expect(piece!.type, equals(PieceType.bishop));
    });

    test('座標が無効なら null を返す', () {
      final piece = board.getPieceAt(Position(10, 10));
      expect(piece, isNull);

      final piece2 = board.getPieceAt(Position(0, 5));
      expect(piece2, isNull);
    });

    test('駒を配置できる', () {
      final newPiece = Piece(type: PieceType.pawn, player: PlayerColor.sente);
      board.setPieceAt(Position(5, 5), newPiece);

      final placed = board.getPieceAt(Position(5, 5));
      expect(placed, equals(newPiece));
    });

    test('盤面をクローンできる', () {
      final cloned = board.clone();

      // 異なるインスタンスか確認
      expect(identical(board, cloned), isFalse);

      // 駒の状態が同じか確認
      for (int y = 1; y <= 9; y++) {
        for (int x = 1; x <= 9; x++) {
          final original = board.getPieceAt(Position(x, y));
          final clonedPiece = cloned.getPieceAt(Position(x, y));

          if (original == null) {
            expect(clonedPiece, isNull);
          } else {
            expect(clonedPiece, isNotNull);
            expect(clonedPiece!.type, equals(original.type));
            expect(clonedPiece!.player, equals(original.player));
            expect(clonedPiece!.currentHP, equals(original.currentHP));
          }
        }
      }
    });

    test('駒をリセットできる', () {
      // 先手のHP を 1に設定
      final whitePiece = board.getWhitePieces().first;
      whitePiece.takeDamage(99);

      // リセット
      board.reset();

      // HP が復元されたか確認
      final resetPiece = board.getWhitePieces().first;
      expect(resetPiece.currentHP, equals(resetPiece.maxHP));
    });

    test('先手の駒リストを取得できる', () {
      final whitePieces = board.getWhitePieces();
      expect(whitePieces.length, equals(16));
      expect(
        whitePieces.every((p) => p.player == PlayerColor.sente),
        isTrue,
      );
    });

    test('後手の駒リストを取得できる', () {
      final blackPieces = board.getBlackPieces();
      expect(blackPieces.length, equals(16));
      expect(
        blackPieces.every((p) => p.player == PlayerColor.gote),
        isTrue,
      );
    });
  });

  group('Position', () {
    test('有効な座標か判定できる', () {
      expect(Position(1, 1).isValid, isTrue);
      expect(Position(5, 5).isValid, isTrue);
      expect(Position(9, 9).isValid, isTrue);

      expect(Position(0, 5).isValid, isFalse);
      expect(Position(10, 5).isValid, isFalse);
      expect(Position(5, 0).isValid, isFalse);
      expect(Position(5, 10).isValid, isFalse);
    });

    test('距離を計算できる', () {
      expect(Position(1, 1).distanceTo(Position(1, 1)), equals(0));
      expect(Position(1, 1).distanceTo(Position(2, 2)), equals(2));
      expect(Position(5, 5).distanceTo(Position(5, 8)), equals(3));
    });

    test('座標が等しいか判定できる', () {
      expect(Position(5, 5), equals(Position(5, 5)));
      expect(Position(5, 5) == Position(6, 6), isFalse);
    });

    test('座標をコピーできる', () {
      final pos = Position(5, 5);
      final copied = pos.copy(x: 6);

      expect(copied.x, equals(6));
      expect(copied.y, equals(5));
    });
  });
}
