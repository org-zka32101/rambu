/// 乱舞将棋の盤面（9x9）の状態管理

import 'package:rambu_shogi/models/piece.dart';
import 'package:rambu_shogi/models/move.dart';

/// 9x9盤の将棋盤面管理
class Board {
  /// 盤面: board[y][x] で (x, y) の駒にアクセス
  /// x: 1-9, y: 1-9
  late List<List<Piece?>> _board;

  /// 先手と後手の駒リスト
  late List<Piece> _whitePieces;  // 先手（白）
  late List<Piece> _blackPieces;  // 後手（黒）

  /// 後手の追加移動が可能か（初手直後のハンデ）
  bool secondHandBonusAvailable = false;

  Board() {
    _initializeBoard();
  }

  /// 盤面を初期化（将棋の標準配置）
  void _initializeBoard() {
    // 9x9の二次元配列を作成（添字は0-8、座標は1-9に対応）
    _board = List.generate(9, (_) => List.filled(9, null));

    _whitePieces = [];
    _blackPieces = [];

    // === 先手（白）の駒配置 ===
    // 1段目：後ろの陣地
    _addPiece(1, 1, PieceType.rook, PlayerColor.sente);     // 飛車
    _addPiece(2, 1, PieceType.gold, PlayerColor.sente);
    _addPiece(3, 1, PieceType.silver, PlayerColor.sente);
    _addPiece(4, 1, PieceType.king, PlayerColor.sente);     // 王
    _addPiece(5, 1, PieceType.bishop, PlayerColor.sente);   // 角
    _addPiece(6, 1, PieceType.gold, PlayerColor.sente);
    _addPiece(7, 1, PieceType.silver, PlayerColor.sente);
    _addPiece(8, 1, PieceType.lance, PlayerColor.sente);
    _addPiece(9, 1, PieceType.knight, PlayerColor.sente);

    // 2段目：金と銀
    // TODO: 本来の配置に修正（実装簡略化のため省略）

    // 3段目：歩
    for (int x = 1; x <= 9; x++) {
      _addPiece(x, 3, PieceType.pawn, PlayerColor.sente);
    }

    // === 後手（黒）の駒配置 ===
    // 7段目：歩
    for (int x = 1; x <= 9; x++) {
      _addPiece(x, 7, PieceType.pawn, PlayerColor.gote);
    }

    // 8段目：金と銀
    // TODO: 本来の配置に修正

    // 9段目：後ろの陣地
    _addPiece(1, 9, PieceType.knight, PlayerColor.gote);
    _addPiece(2, 9, PieceType.lance, PlayerColor.gote);
    _addPiece(3, 9, PieceType.silver, PlayerColor.gote);
    _addPiece(4, 9, PieceType.gold, PlayerColor.gote);
    _addPiece(5, 9, PieceType.king, PlayerColor.gote);      // 王
    _addPiece(6, 9, PieceType.silver, PlayerColor.gote);
    _addPiece(7, 9, PieceType.gold, PlayerColor.gote);
    _addPiece(8, 9, PieceType.bishop, PlayerColor.gote);    // 角
    _addPiece(9, 9, PieceType.rook, PlayerColor.gote);      // 飛車
  }

  /// 駒を盤面に追加
  void _addPiece(int x, int y, PieceType type, PlayerColor player) {
    final piece = Piece(type: type, player: player);
    _board[y - 1][x - 1] = piece;
    if (player == PlayerColor.sente) {
      _whitePieces.add(piece);
    } else {
      _blackPieces.add(piece);
    }
  }

  /// 座標 (x, y) の駒を取得
  Piece? getPieceAt(Position pos) {
    if (!pos.isValid) return null;
    return _board[pos.y - 1][pos.x - 1];
  }

  /// 座標 (x, y) に駒を配置
  void setPieceAt(Position pos, Piece? piece) {
    if (!pos.isValid) return;
    _board[pos.y - 1][pos.x - 1] = piece;
  }

  /// すべての駒を取得
  List<Piece> getAllPieces() {
    return _board
        .expand((row) => row.whereType<Piece>())
        .toList();
  }

  /// 先手の駒リストを取得
  List<Piece> getWhitePieces() => List.unmodifiable(_whitePieces);

  /// 後手の駒リストを取得
  List<Piece> getBlackPieces() => List.unmodifiable(_blackPieces);

  /// プレイヤーの駒リストを取得
  List<Piece> getPiecesForPlayer(PlayerColor player) {
    return player == PlayerColor.sente ? _whitePieces : _blackPieces;
  }

  /// 指定プレイヤーの王を取得
  Piece? getKing(PlayerColor player) {
    return getPiecesForPlayer(player)
        .firstWhere((p) => p.type == PieceType.king);
  }

  /// 着手を適用
  void applyMove(Move move) {
    final fromPiece = getPieceAt(move.from);
    if (fromPiece == null) return;

    // 移動元から駒を削除
    setPieceAt(move.from, null);

    // 移動先に駒を配置
    setPieceAt(move.to, fromPiece);

    // 飛び道具攻撃の場合、対象駒にダメージ
    if (move.isRangedAttack) {
      final targetPiece = getPieceAt(move.to);
      if (targetPiece != null && targetPiece.player != move.player) {
        targetPiece.takeDamage(move.damageDealt);

        // 死亡した駒を盤面から削除
        if (!targetPiece.isAlive) {
          setPieceAt(move.to, null);
        }
      }
    }

    // 駒の飛び道具使用フラグをリセット
    fromPiece.hasAttackedThisTurn = false;
  }

  /// 着手を取り消す（未実装）
  void undoMove(Move move) {
    // TODO: 着手の取り消し実装
  }

  /// 盤面をリセット
  void reset() {
    _whitePieces.clear();
    _blackPieces.clear();
    _initializeBoard();
    secondHandBonusAvailable = false;
  }

  /// 盤面をクローン
  Board clone() {
    final newBoard = Board();
    newBoard._whitePieces.clear();
    newBoard._blackPieces.clear();

    // 盤面のコピー
    for (int y = 1; y <= 9; y++) {
      for (int x = 1; x <= 9; x++) {
        final piece = getPieceAt(Position(x, y));
        if (piece != null) {
          final clonedPiece = piece.clone();
          newBoard.setPieceAt(Position(x, y), clonedPiece);
          if (clonedPiece.player == PlayerColor.sente) {
            newBoard._whitePieces.add(clonedPiece);
          } else {
            newBoard._blackPieces.add(clonedPiece);
          }
        }
      }
    }

    newBoard.secondHandBonusAvailable = secondHandBonusAvailable;
    return newBoard;
  }

  /// 盤面を文字列表示（デバッグ用）
  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('  1 2 3 4 5 6 7 8 9');
    for (int y = 1; y <= 9; y++) {
      buffer.write('$y ');
      for (int x = 1; x <= 9; x++) {
        final piece = getPieceAt(Position(x, y));
        if (piece == null) {
          buffer.write('・ ');
        } else {
          final label = piece.type.label;
          final player = piece.player == PlayerColor.sente ? '☆' : '●';
          buffer.write('$player$label ');
        }
      }
      buffer.writeln();
    }
    return buffer.toString();
  }
}
