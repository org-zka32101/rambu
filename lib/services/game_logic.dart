/// 乱舞将棋のゲームロジック
/// 着手の合法性判定、詰み判定、ターン管理など

import 'dart:math' as math;
import 'package:rambu_shogi/models/board.dart';
import 'package:rambu_shogi/models/game_session.dart';
import 'package:rambu_shogi/models/move.dart';
import 'package:rambu_shogi/models/piece.dart';
import 'package:rambu_shogi/utils/constants.dart';

/// ゲームロジック処理
class GameLogic {
  /// 指定位置から指定駒が移動可能な範囲を取得
  static List<Position> getMovablePositions(
    Board board,
    Position from,
    Piece piece,
  ) {
    final positions = <Position>{};

    // 駒種ごとの移動可能なベクトルを定義
    final moveVectors = _getMoveVectors(piece.type, piece.player);

    for (final (dx, dy) in moveVectors) {
      int x = from.x + dx;
      int y = from.y + dy;

      // 連続移動可能な駒（飛車・角）
      if (piece.type == PieceType.bishop || piece.type == PieceType.rook) {
        // 連続移動
        while (Position(x, y).isValid) {
          final targetPiece = board.getPieceAt(Position(x, y));

          if (targetPiece == null) {
            // 空きマス
            positions.add(Position(x, y));
          } else if (targetPiece.player != piece.player) {
            // 敵駒（取得可能）
            positions.add(Position(x, y));
            break;  // 敵駒の向こう側には移動不可
          } else {
            // 味方駒
            break;  // 味方駒の向こう側には移動不可
          }

          x += dx;
          y += dy;
        }
      } else {
        // 連続移動不可な駒（歩・香・桂・銀・金）
        final pos = Position(x, y);
        if (!pos.isValid) continue;

        final targetPiece = board.getPieceAt(pos);
        if (targetPiece == null || targetPiece.player != piece.player) {
          positions.add(pos);
        }
      }
    }

    return positions.toList();
  }

  /// 駒の移動ベクトル（先手視点）
  static List<(int, int)> _getMoveVectors(PieceType type, PlayerColor player) {
    // 先手と後手で移動方向が異なる
    final direction = player == PlayerColor.sente ? -1 : 1;

    return switch (type) {
      PieceType.pawn => [
        (0, direction),  // 前
      ],
      PieceType.lance => [
        (0, direction),  // 前
        (0, 2 * direction),
        (0, 3 * direction),
        // 連続移動
      ],
      PieceType.knight => [
        (-1, 2 * direction),
        (1, 2 * direction),
      ],
      PieceType.silver => [
        (-1, direction),
        (0, direction),
        (1, direction),
        (-1, -direction),
        (1, -direction),
      ],
      PieceType.gold => [
        (-1, direction),
        (0, direction),
        (1, direction),
        (-1, 0),
        (1, 0),
        (0, -direction),
      ],
      PieceType.bishop => [
        // 斜め移動（連続）
        (-1, -1),
        (-1, 1),
        (1, -1),
        (1, 1),
      ],
      PieceType.rook => [
        // 十字移動（連続）
        (-1, 0),
        (1, 0),
        (0, -1),
        (0, 1),
      ],
      PieceType.king => [
        (-1, -1),
        (0, -1),
        (1, -1),
        (-1, 0),
        (1, 0),
        (-1, 1),
        (0, 1),
        (1, 1),
      ],
    };
  }

  /// 飛び道具で攻撃可能な位置を取得
  static List<Position> getRangedAttackPositions(
    Board board,
    Position from,
    Piece piece,
  ) {
    if (!piece.hasRangedAttack) return [];

    final range = piece.rangedRange;
    final positions = <Position>{};

    final moveVectors = _getMoveVectors(piece.type, piece.player);

    for (final (dx, dy) in moveVectors) {
      for (int i = 1; i <= range; i++) {
        final x = from.x + (dx * i);
        final y = from.y + (dy * i);
        final pos = Position(x, y);

        if (!pos.isValid) break;

        final targetPiece = board.getPieceAt(pos);
        if (targetPiece != null && targetPiece.player != piece.player) {
          // 敵駒に命中
          positions.add(pos);
        }
      }
    }

    return positions.toList();
  }

  /// 着手の合法性を判定
  static bool isMoveLegal(
    GameSession game,
    Piece piece,
    Position from,
    Position to,
    {bool isRangedAttack = false},
  ) {
    // ゲーム状態確認
    if (!game.isPlaying) return false;

    // プレイヤー確認
    if (piece.player != game.currentPlayer) return false;

    // 移動先確認
    if (!to.isValid) return false;

    // 後手ボーナス移動中は、通常移動のみ可
    if (game.board.secondHandBonusAvailable && isRangedAttack) {
      return false;
    }

    if (isRangedAttack) {
      // 飛び道具攻撃
      if (!piece.hasRangedAttack) return false;

      // 飛び道具使用済みチェック
      if (piece.hasAttackedThisTurn) return false;

      final targets = getRangedAttackPositions(game.board, from, piece);
      return targets.contains(to);
    } else {
      // 通常移動
      final movable = getMovablePositions(game.board, from, piece);
      return movable.contains(to);
    }
  }

  /// 着手を実行し、Moveオブジェクトを生成
  static Move createAndApplyMove(
    GameSession game,
    Position from,
    Position to,
    {bool isRangedAttack = false},
  ) {
    final piece = game.board.getPieceAt(from);
    if (piece == null) throw ArgumentError('No piece at $from');

    if (!isLegal(game, piece, from, to, isRangedAttack: isRangedAttack)) {
      throw ArgumentError('Illegal move: $piece $from → $to');
    }

    final capturedPiece = game.board.getPieceAt(to);
    late Move move;

    if (isRangedAttack) {
      // 飛び道具攻撃
      final targetPiece = capturedPiece;
      if (targetPiece == null || targetPiece.player == piece.player) {
        throw ArgumentError('Invalid ranged attack target');
      }

      final damageDealt = Piece.getAttackPower(piece.type);
      final hpBefore = targetPiece.currentHP;

      targetPiece.takeDamage(damageDealt);
      final hpAfter = targetPiece.currentHP;

      move = Move(
        from: from,
        to: to,
        player: piece.player,
        piece: piece,
        moveType: MoveType.ranged,
        damageDealt: damageDealt,
        targetHPBefore: hpBefore,
        targetHPAfter: hpAfter,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      // 駒が死亡した場合、盤面から削除
      if (!targetPiece.isAlive) {
        game.board.setPieceAt(to, null);
      }
    } else {
      // 通常移動
      game.board.setPieceAt(from, null);
      game.board.setPieceAt(to, piece);

      final moveType = capturedPiece != null ? MoveType.capture : MoveType.normal;
      move = Move(
        from: from,
        to: to,
        player: piece.player,
        piece: piece,
        moveType: moveType,
        capturedPiece: capturedPiece,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
    }

    game.moveHistory.add(move);

    // 後手ボーナス移動の処理
    if (game.currentPlayer == PlayerColor.sente && !game.board.secondHandBonusAvailable) {
      game.board.secondHandBonusAvailable = true;
      // ターン交代なし
    } else {
      game.board.secondHandBonusAvailable = false;
      game.turnCount++;
      game.currentPlayer = game.currentPlayer.opponent;
    }

    // 詰み判定
    if (_isCheckmated(game, game.currentPlayer)) {
      game.state = game.currentPlayer == PlayerColor.sente
          ? GameState.blackWon
          : GameState.whiteWon;
      game.winner = game.currentPlayer.opponent;
      game.endedAt = DateTime.now();
    }

    return move;
  }

  /// 詰みを判定（簡易版：王手 + 逃げ道なし）
  static bool _isCheckmated(GameSession game, PlayerColor player) {
    final king = game.board.getKing(player);
    if (king == null || !king.isAlive) {
      return true;  // 王が死んでいる
    }

    // TODO: 本格的な詰み判定
    // 1. 王が王手されているか確認
    // 2. 王手を防ぐ手があるか確認
    // 3. 王が逃げられるか確認

    return false;
  }

  /// 盤面が先手に有利か判定（AHa Moment検出用）
  static bool isGameInFavorOfSente(Board board) {
    final whiteHP = board.getWhitePieces()
        .where((p) => p.type != PieceType.king)
        .fold(0, (sum, p) => sum + p.currentHP);

    final blackHP = board.getBlackPieces()
        .where((p) => p.type != PieceType.king)
        .fold(0, (sum, p) => sum + p.currentHP);

    return whiteHP > blackHP;
  }

  /// 逆転したか判定（ハイライト検出用）
  static bool isReversal(GameSession game, int beforeMoveIndex) {
    if (beforeMoveIndex < 5) return false;

    // 5手前の局面を復元（TODO: 正確な局面復元）
    // 現在がどちらに有利か判定
    // 5手前がどちらに有利だったか判定
    // ひっくり返っていたら逆転

    return false;
  }

  /// 有効な着手リストを取得（AIの候補手生成用）
  static List<Move> getLegalMoves(GameSession game) {
    final moves = <Move>[];
    final pieces = game.board.getPiecesForPlayer(game.currentPlayer);

    for (final piece in pieces) {
      if (!piece.isAlive) continue;

      // 駒の位置を探す
      Position? piecePosition;
      for (int y = 1; y <= 9; y++) {
        for (int x = 1; x <= 9; x++) {
          if (game.board.getPieceAt(Position(x, y)) == piece) {
            piecePosition = Position(x, y);
            break;
          }
        }
        if (piecePosition != null) break;
      }

      if (piecePosition == null) continue;

      // 通常移動
      final movable = getMovablePositions(game.board, piecePosition, piece);
      for (final to in movable) {
        if (isMoveLegal(game, piece, piecePosition, to, isRangedAttack: false)) {
          moves.add(createAndApplyMove(game.clone(), piecePosition, to,
              isRangedAttack: false));
        }
      }

      // 飛び道具攻撃
      if (piece.hasRangedAttack && !piece.hasAttackedThisTurn) {
        final ranged = getRangedAttackPositions(game.board, piecePosition, piece);
        for (final to in ranged) {
          if (isMoveLegal(game, piece, piecePosition, to, isRangedAttack: true)) {
            moves.add(createAndApplyMove(game.clone(), piecePosition, to,
                isRangedAttack: true));
          }
        }
      }
    }

    return moves;
  }

  // Alias for backward compatibility
  static bool isLegal(
    GameSession game,
    Piece piece,
    Position from,
    Position to,
    {bool isRangedAttack = false},
  ) =>
      isMoveLegal(game, piece, from, to, isRangedAttack: isRangedAttack);
}
