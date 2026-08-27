/// 乱舞将棋の着手（移動）情報

import 'package:rambu_shogi/models/piece.dart';

/// 着手タイプ
enum MoveType {
  normal,      // 通常移動
  ranged,      // 飛び道具攻撃
  capture,     // 駒を取る移動
  promote;     // 成り（本実装では不使用）
}

/// 盤面上の座標 (x, y)
/// x: 1-9（左が1、右が9）
/// y: 1-9（上が1、下が9）
class Position {
  final int x;
  final int y;

  const Position(this.x, this.y);

  /// 有効な座標か判定
  bool get isValid => x >= 1 && x <= 9 && y >= 1 && y <= 9;

  /// 距離を計算
  int distanceTo(Position other) =>
      (x - other.x).abs() + (y - other.y).abs();

  /// チェビシェフ距離（チェス的な距離）
  int chebyshevDistanceTo(Position other) =>
      (x - other.x).abs() > (y - other.y).abs()
          ? (x - other.x).abs()
          : (y - other.y).abs();

  Position copy({int? x, int? y}) => Position(x ?? this.x, y ?? this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position && x == other.x && y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  @override
  String toString() => '($x, $y)';
}

/// 乱舞将棋の着手クラス
class Move {
  /// 移動元の座標
  final Position from;

  /// 移動先の座標
  final Position to;

  /// 着手を行ったプレイヤー
  final PlayerColor player;

  /// 着手の種類
  final MoveType moveType;

  /// 移動した駒
  final Piece piece;

  /// 取られた駒（あれば）
  final Piece? capturedPiece;

  /// ダメージ量（飛び道具の場合）
  final int damageDealt;

  /// 対象駒のHP（飛び道具の場合）
  final int? targetHPBefore;
  final int? targetHPAfter;

  /// 着手時刻（システム時間のミリ秒）
  final int? timestamp;

  /// このターン何手目か（棋譜用）
  int? moveIndex;

  Move({
    required this.from,
    required this.to,
    required this.player,
    required this.piece,
    this.moveType = MoveType.normal,
    this.capturedPiece,
    this.damageDealt = 0,
    this.targetHPBefore,
    this.targetHPAfter,
    this.timestamp,
  });

  /// 飛び道具攻撃か
  bool get isRangedAttack => moveType == MoveType.ranged;

  /// 駒を取るか
  bool get isCapture => capturedPiece != null;

  /// クリティカルか（HP >= 2 → 1以下）
  bool get isCritical {
    if (!isRangedAttack || targetHPBefore == null || targetHPAfter == null) {
      return false;
    }
    return targetHPBefore! >= 2 && targetHPAfter! <= 1;
  }

  /// 大ダメージか（3以上のダメージ）
  bool get isBigDamage => damageDealt >= 3;

  /// クローンを作成
  Move clone() {
    return Move(
      from: from.copy(),
      to: to.copy(),
      player: player,
      piece: piece.clone(),
      moveType: moveType,
      capturedPiece: capturedPiece?.clone(),
      damageDealt: damageDealt,
      targetHPBefore: targetHPBefore,
      targetHPAfter: targetHPAfter,
      timestamp: timestamp,
    )..moveIndex = moveIndex;
  }

  @override
  String toString() {
    final typeStr = switch (moveType) {
      MoveType.normal => '移動',
      MoveType.ranged => '飛び道具',
      MoveType.capture => '取得',
      MoveType.promote => '成り',
    };
    return '${piece.type.label} $from → $to ($typeStr)';
  }
}

/// 着手履歴
class MoveHistory {
  final List<Move> _moves = [];

  int get length => _moves.length;

  bool get isEmpty => _moves.isEmpty;

  List<Move> get moves => List.unmodifiable(_moves);

  void add(Move move) {
    move.moveIndex = _moves.length;
    _moves.add(move);
  }

  Move? get(int index) => index >= 0 && index < _moves.length ? _moves[index] : null;

  Move? getLast() => isEmpty ? null : _moves.last;

  List<Move> getRange(int start, int end) {
    return _moves.sublist(
      start.clamp(0, _moves.length),
      end.clamp(0, _moves.length),
    );
  }

  void clear() => _moves.clear();

  @override
  String toString() => 'MoveHistory(${_moves.length} moves)';
}
