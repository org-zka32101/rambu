/// ハイライト生成サービス（Phase 3 MVP実装）

import 'package:rambu_shogi/models/game_session.dart';
import 'package:rambu_shogi/models/move.dart';
import 'package:rambu_shogi/utils/constants.dart';

/// ハイライトイベント
class HighlightEvent {
  final int moveNumber;           // 着手番号
  final String eventType;         // 'critical', 'bigDamage', 'reversal'
  final int damageDealt;
  final String affectedPiece;
  final double timestamp;         // ゲーム内秒数

  HighlightEvent({
    required this.moveNumber,
    required this.eventType,
    required this.damageDealt,
    required this.affectedPiece,
    required this.timestamp,
  });

  @override
  String toString() =>
      'HighlightEvent($eventType: $affectedPiece, damage=$damageDealt)';
}

/// ハイライト生成サービス
class HighlightService {
  /// ゲームセッションからハイライトイベントを検出
  List<HighlightEvent> detectHighlightEvents(GameSession game) {
    final events = <HighlightEvent>[];

    for (int i = 0; i < game.moveHistory.length; i++) {
      final move = game.moveHistory.moves[i];

      // クリティカル判定
      if (_isCriticalHit(move)) {
        events.add(HighlightEvent(
          moveNumber: i,
          eventType: 'critical',
          damageDealt: move.damageDealt,
          affectedPiece: move.moveType == MoveType.ranged
              ? move.piece.type.label
              : '',
          timestamp: move.timestamp?.toDouble() ?? i * 2.0,
        ));
      }

      // 大ダメージ判定
      if (_isBigDamage(move)) {
        events.add(HighlightEvent(
          moveNumber: i,
          eventType: 'bigDamage',
          damageDealt: move.damageDealt,
          affectedPiece: move.moveType == MoveType.ranged
              ? move.piece.type.label
              : '',
          timestamp: move.timestamp?.toDouble() ?? i * 2.0,
        ));
      }

      // 逆転判定
      if (_isReversal(game, i)) {
        events.add(HighlightEvent(
          moveNumber: i,
          eventType: 'reversal',
          damageDealt: 0,
          affectedPiece: '',
          timestamp: move.timestamp?.toDouble() ?? i * 2.0,
        ));
      }
    }

    return events.isEmpty ? [] : [events.reduce((a, b) {
      // 最重要度のイベントを1つ選択
      if (a.eventType == 'critical') return a;
      if (b.eventType == 'critical') return b;
      if (a.eventType == 'bigDamage') return a;
      if (b.eventType == 'bigDamage') return b;
      return a;
    })].toList();
  }

  /// クリティカルヒットか判定
  bool _isCriticalHit(Move move) {
    if (move.moveType != MoveType.ranged) return false;
    if (move.targetHPBefore == null || move.targetHPAfter == null) return false;

    // HP >= 2 → 1以下でクリティカル
    return move.targetHPBefore! >= 2 && move.targetHPAfter! <= 1;
  }

  /// 大ダメージか判定
  bool _isBigDamage(Move move) {
    return move.damageDealt >= HighlightConstants.bigDamageThreshold;
  }

  /// 逆転したか判定
  bool _isReversal(GameSession game, int moveIndex) {
    if (moveIndex < 5) return false;

    // 簡易版: 最後の5手で優位が反転したか判定
    // TODO: より正確な逆転判定ロジック

    return false;
  }

  /// フレーム範囲を計算
  FrameRange calculateFrameRange(HighlightEvent event) {
    final eventTimestamp = event.timestamp;
    const margin = HighlightConstants.eventMarginSeconds;
    const frameRate = HighlightConstants.frameRate;

    final startTime = (eventTimestamp - margin).clamp(0, double.infinity);
    final endTime = eventTimestamp + margin;

    final startFrame = (startTime * frameRate).toInt();
    final endFrame = (endTime * frameRate).toInt();

    return FrameRange(
      startFrame: startFrame,
      endFrame: endFrame,
      totalFrames: endFrame - startFrame,
    );
  }

  /// ハイライト動画情報を生成
  HighlightVideoMetadata createHighlightMetadata(
    GameSession game,
    HighlightEvent event,
  ) {
    final frameRange = calculateFrameRange(event);

    return HighlightVideoMetadata(
      sessionId: game.sessionId,
      eventType: event.eventType,
      moveNumber: event.moveNumber,
      frameStartIndex: frameRange.startFrame,
      frameEndIndex: frameRange.endFrame,
      durationSeconds: HighlightConstants.highlightDurationSeconds,
      createdAt: DateTime.now(),
      status: 'pending',
    );
  }
}

/// フレーム範囲
class FrameRange {
  final int startFrame;
  final int endFrame;
  final int totalFrames;

  FrameRange({
    required this.startFrame,
    required this.endFrame,
    required this.totalFrames,
  });
}

/// ハイライト動画メタデータ
class HighlightVideoMetadata {
  final String sessionId;
  final String eventType;  // 'critical', 'bigDamage', 'reversal'
  final int moveNumber;
  final int frameStartIndex;
  final int frameEndIndex;
  final int durationSeconds;
  final DateTime createdAt;
  String status;  // 'pending', 'processing', 'success', 'failed'

  String? videoUrl;
  String? thumbnailUrl;
  String? shareLink;

  HighlightVideoMetadata({
    required this.sessionId,
    required this.eventType,
    required this.moveNumber,
    required this.frameStartIndex,
    required this.frameEndIndex,
    required this.durationSeconds,
    required this.createdAt,
    required this.status,
    this.videoUrl,
    this.thumbnailUrl,
    this.shareLink,
  });

  @override
  String toString() => 'HighlightVideo('
      'sessionId=$sessionId, '
      'eventType=$eventType, '
      'status=$status'
      ')';
}
