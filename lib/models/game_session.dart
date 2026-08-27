/// 乱舞将棋の対局セッション全体を管理

import 'package:rambu_shogi/models/board.dart';
import 'package:rambu_shogi/models/move.dart';
import 'package:rambu_shogi/models/piece.dart';

/// ゲームの状態
enum GameState {
  waiting,       // 待機中
  playing,       // 進行中
  whiteWon,      // 先手勝利
  blackWon,      // 後手勝利
  draw;          // 引き分け

  String get label => switch (this) {
    GameState.waiting => '待機中',
    GameState.playing => '進行中',
    GameState.whiteWon => '先手勝利',
    GameState.blackWon => '後手勝利',
    GameState.draw => '引き分け',
  };
}

/// 難易度設定
enum Difficulty {
  easy,    // 初級（先手40-50%勝率目標）
  normal,  // 中級（先手50±3%勝率目標）
  hard;    // 上級（先手60%+勝率目標）

  String get label => switch (this) {
    Difficulty.easy => '初級',
    Difficulty.normal => '中級',
    Difficulty.hard => '上級',
  };

  /// ランダムノイズレンジ（評価関数用）
  double get noiseRange => switch (this) {
    Difficulty.easy => 5.0,
    Difficulty.normal => 1.0,
    Difficulty.hard => 0.3,
  };

  /// 駒価値とHP価値の比率（駒価値のウェイト）
  double get piecValueWeight => switch (this) {
    Difficulty.easy => 0.7,    // 70:30
    Difficulty.normal => 0.5,  // 50:50
    Difficulty.hard => 0.3,    // 30:70
  };
}

/// 対局セッション
class GameSession {
  /// セッションID（Firestore保存用）
  final String sessionId;

  /// 盤面
  late Board board;

  /// 着手履歴
  late MoveHistory moveHistory;

  /// 現在のゲーム状態
  GameState state = GameState.waiting;

  /// 現在のターン
  int turnCount = 0;

  /// 現在のプレイヤーの番
  PlayerColor currentPlayer = PlayerColor.sente;

  /// AI難易度
  Difficulty aiDifficulty;

  /// プレイヤーの色（先手なら sente, 後手なら gote）
  PlayerColor playerColor;

  /// ゲーム開始時刻
  DateTime? startedAt;

  /// ゲーム終了時刻
  DateTime? endedAt;

  /// 勝者（終了後に設定）
  PlayerColor? winner;

  /// 棋譜（KIF形式など、後で保存用）
  String? kifu;

  GameSession({
    required this.sessionId,
    this.aiDifficulty = Difficulty.normal,
    this.playerColor = PlayerColor.sente,
  }) {
    board = Board();
    moveHistory = MoveHistory();
  }

  /// ゲームを開始
  void start() {
    state = GameState.playing;
    startedAt = DateTime.now();
    endedAt = null;
    winner = null;
    turnCount = 0;
    currentPlayer = PlayerColor.sente;

    // 後手の初手直後ボーナス移動を有効化
    board.secondHandBonusAvailable = false;
  }

  /// ゲームが進行中か
  bool get isPlaying => state == GameState.playing;

  /// ゲームが終了したか
  bool get isGameOver => state != GameState.playing && state != GameState.waiting;

  /// 現在のプレイヤーがAIか
  bool get isCurrentPlayerAI => currentPlayer != playerColor;

  /// 着手を適用
  bool applyMove(Move move) {
    if (!isPlaying) return false;
    if (move.player != currentPlayer) return false;

    // 着手を履歴に追加
    moveHistory.add(move);

    // 盤面に反映
    board.applyMove(move);

    // 飛び道具使用フラグを設定
    if (move.isRangedAttack) {
      move.piece.hasAttackedThisTurn = true;
    }

    // 後手の初手直後ボーナス移動を処理
    if (currentPlayer == PlayerColor.sente && !board.secondHandBonusAvailable) {
      board.secondHandBonusAvailable = true;
      // 次は後手がボーナス移動を行う
      return true;  // ターン交代なし
    } else {
      board.secondHandBonusAvailable = false;
      // ターンを進める
      turnCount++;
      currentPlayer = currentPlayer.opponent;
    }

    // 詰みチェック
    if (_isCheckmated(currentPlayer)) {
      state = currentPlayer == PlayerColor.sente
          ? GameState.blackWon
          : GameState.whiteWon;
      winner = currentPlayer.opponent;
      endedAt = DateTime.now();
    }

    return true;
  }

  /// 指定プレイヤーが詰んでいるか
  bool _isCheckmated(PlayerColor player) {
    final king = board.getKing(player);
    if (king == null || !king.isAlive) {
      return true;  // 王が死んでいる = 敗北
    }

    // TODO: 本将棋の詰み判定ロジック実装
    // 王手状態 + 逃げ道がない = 詰み
    return false;
  }

  /// 先手の総HP
  double getWhiteTotalHP() {
    return board.getWhitePieces()
        .where((p) => p.type != PieceType.king)
        .fold(0.0, (sum, p) => sum + p.currentHP);
  }

  /// 後手の総HP
  double getBlackTotalHP() {
    return board.getBlackPieces()
        .where((p) => p.type != PieceType.king)
        .fold(0.0, (sum, p) => sum + p.currentHP);
  }

  /// ゲーム時間（秒）
  int? getGameDurationSeconds() {
    if (startedAt == null) return null;
    final end = endedAt ?? DateTime.now();
    return end.difference(startedAt!).inSeconds;
  }

  /// セッションをリセット
  void reset() {
    board.reset();
    moveHistory.clear();
    state = GameState.waiting;
    turnCount = 0;
    currentPlayer = PlayerColor.sente;
    startedAt = null;
    endedAt = null;
    winner = null;
  }

  /// 対局をクローン（AI思考用）
  GameSession clone() {
    final newSession = GameSession(
      sessionId: sessionId,
      aiDifficulty: aiDifficulty,
      playerColor: playerColor,
    );
    newSession.board = board.clone();
    newSession.state = state;
    newSession.turnCount = turnCount;
    newSession.currentPlayer = currentPlayer;

    // 着手履歴もコピー
    for (final move in moveHistory.moves) {
      newSession.moveHistory.add(move.clone());
    }

    return newSession;
  }

  @override
  String toString() {
    return 'GameSession('
        'sessionId=$sessionId, '
        'state=$state, '
        'turnCount=$turnCount, '
        'currentPlayer=$currentPlayer'
        ')';
  }
}
