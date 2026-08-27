/// 乱舞将棋の定数定義

import 'package:rambu_shogi/models/piece.dart';

/// 盤面定数
class BoardConstants {
  static const int boardSize = 9;
  static const int minX = 1;
  static const int maxX = 9;
  static const int minY = 1;
  static const int maxY = 9;

  /// 先手の陣地（y = 1-3）
  static const int senteBaselineY = 1;
  static const int senteBaseZoneY = 3;

  /// 後手の陣地（y = 7-9）
  static const int goteBaselineY = 9;
  static const int goteBaseZoneY = 7;
}

/// 駒の評価値定数（センティセント）
class PieceValues {
  static const Map<PieceType, double> basicValue = {
    PieceType.pawn: 1.0,
    PieceType.lance: 3.0,
    PieceType.knight: 3.0,
    PieceType.silver: 5.5,  // HP補正 +0.5
    PieceType.gold: 5.5,    // HP補正 +0.5
    PieceType.bishop: 9.0,  // HP補正 +1.0
    PieceType.rook: 9.0,    // HP補正 +1.0
    PieceType.king: 999.0,  // 王は最重要
  };

  static double getValue(PieceType type) => basicValue[type] ?? 0.0;
}

/// AI評価関数の定数
class EvaluationConstants {
  /// 駒価値とHP価値の比率（駒価値のウェイト）
  static const double easyPieceValueWeight = 0.7;      // 初級: 70:30
  static const double normalPieceValueWeight = 0.5;    // 中級: 50:50
  static const double hardPieceValueWeight = 0.3;      // 上級: 30:70

  /// ランダムノイズレンジ
  static const double easyNoiseRange = 5.0;
  static const double normalNoiseRange = 1.0;
  static const double hardNoiseRange = 0.3;

  /// テンポボーナス（手番の価値）
  static const double tempoBonus = 0.5;

  /// クリティカル局面の特殊加算
  static const double criticalAdjacentBonus = 50.0;         // 王に隣接
  static const double criticalDamageBonus = 30.0;           // クリティカルダメージ可能
  static const double enemyMajorPieceAttackBonus = 20.0;    // 角/飛を攻撃可能
  static const double fullHPBonus = 5.0;                    // 自駒HP満タン
  static const double enemyLowHPBonus = 15.0;               // 相手駒HP1

  /// 位置評価表（先手視点）
  /// 行番号: y (1-9), 列番号: x (1-9)
  /// 値: 位置ボーナス
  static const List<List<int>> positionBonusTable = [
    [0, 0, 0, 0, 0, 0, 0, 0, 0], // y=1 先手陣地
    [0, 0, 0, 0, 0, 0, 0, 0, 0], // y=2
    [0, 1, 2, 2, 3, 2, 2, 1, 0], // y=3 若干前進ボーナス
    [0, 1, 2, 3, 4, 3, 2, 1, 0], // y=4
    [0, 1, 2, 3, 5, 3, 2, 1, 0], // y=5 中央の価値+
    [0, 1, 2, 3, 4, 3, 2, 1, 0], // y=6
    [0, 1, 2, 2, 3, 2, 2, 1, 0], // y=7 後手陣地へ接近
    [0, 0, 0, 0, 0, 0, 0, 0, 0], // y=8
    [0, 0, 0, 0, 0, 0, 0, 0, 0], // y=9 後手陣地・リスク
  ];

  /// 位置ボーナス係数（駒種ごと）
  static const Map<PieceType, double> positionBonusCoefficient = {
    PieceType.pawn: 0.1,
    PieceType.lance: 0.1,
    PieceType.knight: 0.15,
    PieceType.silver: 0.15,
    PieceType.gold: 0.15,
    PieceType.bishop: 0.25,
    PieceType.rook: 0.25,
    PieceType.king: 0.0,  // 王は位置評価対象外
  };

  static double getPositionBonus(int x, int y, PieceType type) {
    if (y < 1 || y > 9 || x < 1 || x > 9) return 0.0;

    final bonusValue = positionBonusTable[y - 1][x - 1];
    final coefficient = positionBonusCoefficient[type] ?? 0.0;
    return bonusValue * coefficient;
  }
}

/// アルファベータ探索の定数
class SearchConstants {
  /// 初期値
  static const int initialAlpha = -999999;
  static const int initialBeta = 999999;

  /// 最大探索深度
  static const int maxDepth = 4;  // 中級: depth 4

  /// タイムアウト（ミリ秒）
  static const int searchTimeoutMs = 5000;
}

/// ハイライト生成の定数
class HighlightConstants {
  /// ハイライト動画の尺（秒）
  static const int highlightDurationSeconds = 15;

  /// イベント前後の秒数
  static const double eventMarginSeconds = 7.5;

  /// フレームレート
  static const int frameRate = 30;

  /// 対象フレーム数
  static const int targetFrameCount = highlightDurationSeconds * frameRate;

  /// Cloud Storageのキャッシュ保期間（日）
  static const int storageCacheDays = 30;

  /// イベント検出の条件
  static const int criticalHPThreshold = 1;  // HP1以下でクリティカル
  static const int bigDamageThreshold = 3;   // ダメージ3以上で大ダメージ
}

/// 計測・分析の定数
class AnalyticsConstants {
  /// Aha Momentの定義イベント
  static const String ahaMomentEvent = 'critical_hit_moment';

  /// Day 1 リテンション目標
  static const double day1RetentionTarget = 0.20;  // 20%

  /// Aha達成率目標
  static const double ahaAchievementTarget = 0.60;  // 60%

  /// Bot勝率の目標範囲
  static const double botWinRateTarget = 0.50;     // 50%
  static const double botWinRateTolerance = 0.03;  // ±3%
}

/// ゲームバランスの定数
class GameBalanceConstants {
  /// 後手の初手後ボーナス移動（何手分）
  static const int secondHandBonusMovesPerTurn = 1;

  /// 飛び道具のクールタイム（手数）
  static const int rangedAttackCooldown = 3;

  /// 飛び道具の射程（マス）
  static const int rangedAttackRange = 3;

  /// 飛び道具の威力
  static const int rangedAttackPower = 1;
}
