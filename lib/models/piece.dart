/// 乱舞将棋の駒定義
/// HP制と飛び道具の仕様を含む

import 'package:flutter/foundation.dart';

/// 駒種の列挙型
enum PieceType {
  pawn,        // 歩
  lance,       // 香
  knight,      // 桂
  silver,      // 銀
  gold,        // 金
  bishop,      // 角（飛び道具対応）
  rook,        // 飛（飛び道具対応）
  king;        // 王

  String get label {
    return switch (this) {
      PieceType.pawn => '歩',
      PieceType.lance => '香',
      PieceType.knight => '桂',
      PieceType.silver => '銀',
      PieceType.gold => '金',
      PieceType.bishop => '角',
      PieceType.rook => '飛',
      PieceType.king => '王',
    };
  }

  String get englishLabel {
    return switch (this) {
      PieceType.pawn => 'Pawn',
      PieceType.lance => 'Lance',
      PieceType.knight => 'Knight',
      PieceType.silver => 'Silver',
      PieceType.gold => 'Gold',
      PieceType.bishop => 'Bishop',
      PieceType.rook => 'Rook',
      PieceType.king => 'King',
    };
  }
}

/// プレイヤー（先手/後手）
enum PlayerColor {
  sente,   // 先手（白）
  gote;    // 後手（黒）

  String get label => this == PlayerColor.sente ? '先手' : '後手';

  PlayerColor get opponent =>
      this == PlayerColor.sente ? PlayerColor.gote : PlayerColor.sente;
}

/// 乱舞将棋の駒クラス
class Piece {
  final PieceType type;
  final PlayerColor player;
  int currentHP;
  bool hasAttackedThisTurn = false;  // 今ターン飛び道具使用済みフラグ

  Piece({
    required this.type,
    required this.player,
    int? initialHP,
  }) : currentHP = initialHP ?? type.maxHP;

  /// 駒の最大HP（ゲームバランスから定義）
  static int getMaxHP(PieceType type) {
    return switch (type) {
      PieceType.pawn => 1,
      PieceType.lance => 1,
      PieceType.knight => 1,
      PieceType.silver => 2,
      PieceType.gold => 2,
      PieceType.bishop => 2,
      PieceType.rook => 2,
      PieceType.king => 0, // キングはHP制度対象外
    };
  }

  /// 駒の駒価値（センティセント単位）
  static double getPieceValue(PieceType type) {
    return switch (type) {
      PieceType.pawn => 1.0,
      PieceType.lance => 3.0,
      PieceType.knight => 3.0,
      PieceType.silver => 5.5,      // HP補正 +0.5
      PieceType.gold => 5.5,        // HP補正 +0.5
      PieceType.bishop => 9.0,      // HP補正 +1.0
      PieceType.rook => 9.0,        // HP補正 +1.0
      PieceType.king => double.infinity, // 王は最重要
    };
  }

  /// 駒の基本攻撃力
  static int getAttackPower(PieceType type) {
    return switch (type) {
      PieceType.pawn => 1,
      PieceType.lance => 1,
      PieceType.knight => 1,
      PieceType.silver => 2,
      PieceType.gold => 2,
      PieceType.bishop => 2,
      PieceType.rook => 2,
      PieceType.king => 1,
    };
  }

  /// 飛び道具を持つか
  bool get hasRangedAttack => type == PieceType.bishop || type == PieceType.rook;

  /// 飛び道具の射程（マス数）
  int get rangedRange => hasRangedAttack ? 3 : 0;

  /// クールタイム（手数）
  int get cooldownTurns => hasRangedAttack ? 3 : 0;

  /// HP比率（0.0-1.0）
  double get hpRatio => type == PieceType.king ? 1.0 : currentHP / maxHP;

  /// 最大HP
  int get maxHP => PieceType.getMaxHP(type);

  /// ダメージを与える
  void takeDamage(int damage) {
    if (type == PieceType.king) {
      // 王はHP制度対象外
      return;
    }
    currentHP = (currentHP - damage).clamp(0, maxHP);
  }

  /// 回復する
  void heal(int amount) {
    if (type == PieceType.king) {
      return;
    }
    currentHP = (currentHP + amount).clamp(0, maxHP);
  }

  /// 完全回復
  void fullHeal() {
    if (type != PieceType.king) {
      currentHP = maxHP;
    }
  }

  /// 生存しているか
  bool get isAlive => type == PieceType.king || currentHP > 0;

  /// クローンを作成
  Piece clone() {
    return Piece(
      type: type,
      player: player,
      initialHP: currentHP,
    )..hasAttackedThisTurn = hasAttackedThisTurn;
  }

  @override
  String toString() => '${player.label}$type.label(HP:$currentHP/$maxHP)';
}
