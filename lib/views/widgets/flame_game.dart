/// 乱舞将棋のFlame盤面実装

import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rambu_shogi/models/board.dart';
import 'package:rambu_shogi/models/game_session.dart';
import 'package:rambu_shogi/models/move.dart';
import 'package:rambu_shogi/models/piece.dart';
import 'package:rambu_shogi/services/game_logic.dart';
import 'package:rambu_shogi/viewmodels/game_provider.dart';

/// Flame盤面ゲーム
class RambuShogiGame extends FlameGame {
  late GameSession gameSession;
  late Board board;

  // UI定数
  static const double squareSize = 48.0;  // 1マスのサイズ
  static const double boardStartX = 20.0;
  static const double boardStartY = 20.0;
  static const double boardWidth = 9 * squareSize;
  static const double boardHeight = 9 * squareSize;

  RambuShogiGame(this.gameSession) : board = gameSession.board;

  @override
  Future<void> onLoad() async {
    // 初期化処理
    print('RambuShogiGame loaded');
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 盤面背景を描画
    _drawBoard(canvas);

    // 升目を描画
    _drawSquares(canvas);

    // 駒を描画
    _drawPieces(canvas);

    // HPゲージを描画
    _drawHPBars(canvas);
  }

  /// 盤面背景を描画
  void _drawBoard(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFFD2B48C);  // タン色

    canvas.drawRect(
      Rect.fromLTWH(
        boardStartX,
        boardStartY,
        boardWidth,
        boardHeight,
      ),
      paint,
    );

    // 枠線
    final border = Paint()
      ..color = const Color(0xFF8B7355)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawRect(
      Rect.fromLTWH(
        boardStartX,
        boardStartY,
        boardWidth,
        boardHeight,
      ),
      border,
    );
  }

  /// 升目グリッドを描画
  void _drawSquares(Canvas canvas) {
    final linePaint = Paint()
      ..color = const Color(0xFF8B7355)
      ..strokeWidth = 1.0;

    // 横線
    for (int y = 0; y <= 9; y++) {
      canvas.drawLine(
        Offset(boardStartX, boardStartY + y * squareSize),
        Offset(boardStartX + boardWidth, boardStartY + y * squareSize),
        linePaint,
      );
    }

    // 縦線
    for (int x = 0; x <= 9; x++) {
      canvas.drawLine(
        Offset(boardStartX + x * squareSize, boardStartY),
        Offset(boardStartX + x * squareSize, boardStartY + boardHeight),
        linePaint,
      );
    }
  }

  /// 駒を描画
  void _drawPieces(Canvas canvas) {
    for (int y = 1; y <= 9; y++) {
      for (int x = 1; x <= 9; x++) {
        final piece = board.getPieceAt(Position(x, y));
        if (piece != null && piece.isAlive) {
          _drawPiece(canvas, piece, x, y);
        }
      }
    }
  }

  /// 単一の駒を描画
  void _drawPiece(Canvas canvas, Piece piece, int x, int y) {
    final squareStartX = boardStartX + (x - 1) * squareSize;
    final squareStartY = boardStartY + (y - 1) * squareSize;
    final centerX = squareStartX + squareSize / 2;
    final centerY = squareStartY + squareSize / 2;

    // 駒の背景色
    final bgColor = piece.player == PlayerColor.sente
        ? const Color(0xFFFFFFFF)  // 白
        : const Color(0xFF333333);  // 黒

    final bgPaint = Paint()..color = bgColor;

    // 駒を円で描画（簡易版）
    canvas.drawCircle(
      Offset(centerX, centerY),
      squareSize / 2.2,
      bgPaint,
    );

    // 駒の枠線
    final borderPaint = Paint()
      ..color = piece.player == PlayerColor.sente
          ? Colors.black
          : Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(
      Offset(centerX, centerY),
      squareSize / 2.2,
      borderPaint,
    );

    // 駒の文字を描画
    final textPainter = TextPainter(
      text: TextSpan(
        text: piece.type.label,
        style: TextStyle(
          color: piece.player == PlayerColor.sente
              ? Colors.black
              : Colors.white,
          fontSize: 14.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(centerX - textPainter.width / 2, centerY - textPainter.height / 2),
    );

    // HP表示
    if (piece.type != PieceType.king) {
      final hpText = '${piece.currentHP}/${piece.maxHP}';
      final hpPainter = TextPainter(
        text: TextSpan(
          text: hpText,
          style: const TextStyle(
            color: Colors.red,
            fontSize: 10.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      hpPainter.layout();
      hpPainter.paint(
        canvas,
        Offset(centerX - hpPainter.width / 2, centerY + squareSize / 4),
      );
    }
  }

  /// HPゲージを描画（盤面上部）
  void _drawHPBars(Canvas canvas) {
    final whiteHP = gameSession.getWhiteTotalHP();
    final blackHP = gameSession.getBlackTotalHP();
    const maxHP = 32.0;  // 駒の最大合計HP

    const barY = 10.0;
    const barHeight = 12.0;
    const barWidth = 150.0;

    // 先手HPバー
    const whiteBarX = boardStartX;
    _drawHPBar(canvas, whiteBarX, barY, barWidth, barHeight, whiteHP / maxHP,
        Colors.white, Colors.black);

    // 後手HPバー
    final blackBarX = boardStartX + boardWidth - barWidth;
    _drawHPBar(canvas, blackBarX, barY, barWidth, barHeight, blackHP / maxHP,
        Colors.black, Colors.white);
  }

  /// HPバーを描画
  void _drawHPBar(
    Canvas canvas,
    double x,
    double y,
    double width,
    double height,
    double ratio,
    Color barColor,
    Color textColor,
  ) {
    // 背景
    final bgPaint = Paint()..color = Colors.grey.shade300;
    canvas.drawRect(Rect.fromLTWH(x, y, width, height), bgPaint);

    // HP値
    final hpPaint = Paint()..color = barColor;
    canvas.drawRect(
      Rect.fromLTWH(x, y, width * ratio.clamp(0, 1), height),
      hpPaint,
    );

    // 枠線
    final borderPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTWH(x, y, width, height), borderPaint);
  }

  @override
  void onTapDown(TapDownEvent event) {
    // タップ位置から座標を計算
    final tapX = event.localPosition.x;
    final tapY = event.localPosition.y;

    // 盤面内のタップか確認
    if (tapX < boardStartX ||
        tapX > boardStartX + boardWidth ||
        tapY < boardStartY ||
        tapY > boardStartY + boardHeight) {
      return;
    }

    // 盤面座標に変換
    final boardX = ((tapX - boardStartX) / squareSize).floor() + 1;
    final boardY = ((tapY - boardStartY) / squareSize).floor() + 1;

    final pos = Position(boardX, boardY);

    if (pos.isValid) {
      _handleSquareTapped(pos);
    }
  }

  /// 升目がタップされた時の処理
  void _handleSquareTapped(Position pos) {
    final piece = board.getPieceAt(pos);
    print('Tapped: $pos, piece: $piece');

    // TODO: UIロジックとの連携
    // 自駒選択 → 移動先選択 → 着手実行の流れを実装
  }
}

/// Flame盤面Widgetラッパー
class RambuShogiGameWidget extends ConsumerWidget {
  const RambuShogiGameWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameSessionProvider);

    if (game == null) {
      return const Center(child: Text('ゲームセッションが初期化されていません'));
    }

    return GameWidget(
      game: RambuShogiGame(game),
    );
  }
}
