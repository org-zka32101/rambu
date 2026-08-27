# 乱舞将棋 (rambu_shogi) — Claude 開発ガイド

**プロジェクト名**: 乱舞将棋（らんぶしょうぎ）  
**内部コード**: rambu_shogi  
**開発ブランチ**: `claude/ranbu-shogi-dev-bn07oa`  
**開発期間**: 2026-08-22 ～ 2026-10-31（Phase 0-4）  
**ステータス**: Phase 1 開発開始

---

## Vision / Mission

**Vision**: 将棋を知らない視聴者でも「うわ、今の一撃やばい」で盛り上がる、切り抜き文化に乗る将棋バリアント

**Mission**: 将棋の「静かな読み合い」に「殴り合いの爽快感」を足し、配信・SNSで拡散される将棋を作る

---

## 🎮 ゲーム概要

**本将棋ベース** + **HP制** + **飛び道具駒** による観戦映え特化の将棋バリアント。

### 主要ゲームバランス（確定版）

| 駒 | HP | 攻撃力 | 飛び道具 | 備考 |
|---|---|---|---|---|
| 歩/香/桂 | 1 | 1 | なし | 即死維持 |
| 銀/金 | 2 | 2 | なし | 耐久UP |
| 角/飛 | 2 | 2 | ✓ 射程3・威力1・CT3手 | 遠隔攻撃 |
| 王 | — | 1 | なし | HP不適用・通常詰みルール |

**先後バランス**: 後手が初手直後に「追加移動1回」（通常移動のみ）でハンデ → 先手勝率50%に調整済み

### Aha Moment

**飛び道具のクリティカルアタックが相手の主力にヒットして HP が0になる瞬間**  
→ HP可視化 + 着弾エフェクト + 画面シェイク + SE の3点セット演出

---

## 🛠️ テック・スタック

```
Frontend:
  - Flutter 3.x + Dart 3.x
  - Flame 2D game engine（盤面レンダリング）
  - Riverpod（状態管理）
  - Lottie（エフェクト演出）

Backend:
  - Firebase Firestore（対局ログ・ユーザー管理）
  - Firebase Auth（認証）
  - Firebase Analytics（計測）
  - Firebase Cloud Functions（ハイライト生成）
  - Cloud Storage（動画・画像ストレージ）

External:
  - RevenueCat（課金管理）
  - Bitly API（短縮URL生成）

Dependencies:
  - petit_core / petit_ui（内部ライブラリ・再実装禁止）
```

---

## 📁 プロジェクト構成

```
lib/
  models/
    board.dart              # 盤面（駒配置・HP・着手履歴）
    move.dart               # 着手情報
    piece.dart              # 駒種・HP値
    game_session.dart       # 対局全体・計測
    highlight.dart          # ハイライト動画entity

  services/
    game_logic.dart         # ターン管理・詰み判定・着手適用
    ai_engine.dart          # Bot AI（評価関数・アルファベータ）
    firestore_service.dart  # Firestore連携
    highlight_service.dart  # ハイライト生成
    analytics_service.dart  # KPI計測

  viewmodels/
    game_provider.dart      # Riverpod: 対局状態管理
    board_provider.dart     # Riverpod: 盤面状態
    ai_provider.dart        # Riverpod: AI思考フラグ

  views/
    screens/
      onboarding_screen.dart      # 3枚説明画面
      home_screen.dart            # メニュー画面
      game_screen.dart            # 対局画面（Flame埋め込み）
      tutorial_screen.dart        # チュートリアル（後手ハンデ体感）
      result_screen.dart          # 結果画面
      settings_screen.dart        # 設定
      paywall_screen.dart         # 課金画面

    widgets/
      flame_game.dart             # Flame盤面実装
      hp_bar_widget.dart          # HPゲージ表示
      highlight_preview.dart      # ハイライト予告

  utils/
    constants.dart          # 駒価値表・盤面定義
    enums.dart              # 列挙型

assets/
  images/pieces/            # 駒イラスト
  sounds/                   # SE・BGM
```

---

## 📋 実装フェーズ概要

### Phase 1: UI + Bot初期実装（Week 2-4・23日間）

**ゴール**: オンボーディング → 盤面 → 結果までのUIフロー実装完了 + CPU vs CPU 100局自動対局成功

**並行トラック**:

**A: UI実装（13日）**
1. オンボーディング＋ホーム（3日）
2. Flame盤面基本（4日）- 升目・駒・HP表示
3. チュートリアル（2日）- 後手ハンデ体感
4. 結果画面（2日）
5. 設定＋ペイウォール（2日）

**B: Bot AI実装（9日）**
1. ゲームロジック（3日）- Board/Move/着手適用
2. 評価関数（2日）- 駒価値＋HP＋位置評価
3. アルファベータ探索（3日）- depth=4・中級難易度
4. ランダムノイズ（1日）

**終了条件**:
- [ ] UI: オンボーディング → 盤面 → 結果フロー実装完了
- [ ] Bot: CPU vs CPU 100局自動対局成功
- [ ] 統合テスト: ユーザーvsCPU 1局で盤面・HP・SEが動作

### Phase 2: Bot調整（Week 5-7・15日間）

**ゴール**: 先手勝率 50±3% に収束

**プロセス**:
- Week 5: 100局実施 → 勝率分析 → 原因特定
- Week 6: 補正実装（ランダムムーブ / 評価関数重み） → 再テスト
- Week 7: 微調整 + 難易度別実装（初級40-50%、上級60%+）

**リスク**: 最大の工数リスク。パラメータ試行錯誤が長くなる可能性 → バッファ +1w 用意

### Phase 3: ハイライト生成MVP（Week 8-9・11日間）

**ゴール**: 対局終了から15秒ハイライト動画の自動生成が完全に機能

**フロー**:
1. イベント検出（クリティカル・大ダメージ・逆転）
2. フレーム範囲特定（イベント ± 7.5秒）
3. Flame再レンダリング → PNG画像列
4. ffmpeg エンコード（Cloud Functions）
5. Cloud Storage アップロード
6. 共有リンク生成（Bitly + Fallback）
7. Firestore保存 + 通知

**終了条件**:
- [ ] ハイライト生成成功率 100%（5回中5回）
- [ ] 生成時間 100-180秒以内
- [ ] 30日自動削除が機能

### Phase 4: テスト・ストア準備（Week 10・5日間）

**ゴール**: ソフトローンチゴー

**作業**:
- 統合テスト（25対局）
- パフォーマンステスト
- エラーシナリオテスト
- ストア提出準備（メタデータ・スクショ・プライバシーマニフェスト）
- ソフトローンチ設定（Remote Config・Analytics計測）

**終了条件**:
- [ ] 統合テスト 25局全クリア
- [ ] App Store / Google Play 提出準備完了
- [ ] ソフトローンチゲート条件（Day1 20%+, Aha 60%+, Bot勝率50±3%）計測可能

---

## 🎯 実装上の核になるポイント

### 1. Aha Moment は演出で決まる

飛び道具のクリティカル演出が生命線。最優先で作り込む：

```dart
if (move.moveType == 'ranged' && targetPiece.currentHP <= 1) {
  playLottieAnimation('critical_impact');  // 大型エフェクト
  playSound('critical_hit.wav');           // SE
  screenShake(duration: 200);              // 画面ぐらつき
  displayDamageText('+${damage} CRITICAL');// フローティング
}
```

### 2. Bot先手勝率50%が最大のリスク

**自動テストツールで毎日計測**:

```dart
// bot_benchmark.dart - 毎日CI実行
for (int i = 0; i < 100; i++) {
  Game game = startNewGame();
  while (!game.isGameOver()) {
    Move move = ai.getBestMove(game);
    game.applyMove(move);
  }
  if (game.winner == Color.white) whiteWins++;
}
print('White win rate: ${whiteWins}% (目標: 50±3%)');
```

パラメータ（ランダムノイズ、評価関数重み）を変えながら「50%に最も近い設定」を探す。

### 3. 後手ハンデの説明コスト削減

ルール説明の文字ではなく、チュートリアル対局で**操作体験させる**：

```dart
if (isPlayerSecondHand && tutorialStep == 'hamde_introduction') {
  showButton('追加移動ボタン', glowing: true);  // 点灯演出
  onPlayerTapButton() {
    makeSecondHandBonus();
    showCelebrationAnimation();  // 視覚的に理解させる
  }
}
```

### 4. ハイライト生成は非同期バックグラウンド

対局終了後に「生成中...」という待機画面は見せない。結果画面をすぐ表示し、バックグラウンドで生成開始：

```dart
void onGameOver() {
  navigator.push(ResultScreen(game: game));  // すぐ表示
  _generateHighlightAsync(game);  // 非同期・await なし
}
```

### 5. Firestore コスト削減

対局中の盤面状態はローカル状態管理（Riverpod）で完結。Firestore Realtime listener は不可避な場面のみ：

```dart
// 対局中: ローカル状態（リスナー不要）
final boardState = ref.watch(boardProvider);

// 対局終了後: 1回の書き込み
await gameService.saveGameSession(game);

// ランキング画面: リスナー許容
ref.watch(rankingStream);
```

---

## 🚨 要注意・陥りやすいバグ

| 項目 | バグ | 対策 |
|---|---|---|
| **座標系** | 9x9盤で1マスズレが全体崩壊 | Unit test で座標計算を10パターン以上検証 |
| **HP初期化** | 対局開始時にHP初期化忘れ | Board.reset() で明示的に全HP初期化 |
| **詰み判定** | 王手だけで「詰み」判定→実は逃げ道あり | 「王手 + 逃げ道ない」両方チェック |
| **Move ログ** | タイムスタンプなし→ハイライト時にズレ | Move.timestamp = System.currentTimeMillis() 必須 |
| **飛び道具CD** | クールダウンが「結果表示後」に計算→実質短縮バグ | Move.apply() 時点で計算 |
| **ランダムノイズ** | ノイズ大きすぎ→AI弱くなりすぎ | 中級 ±1.0 は堅い、±0.5以下に絞る検討 |

---

## 📊 AI評価関数（中級・推奨）

### 構成

```
評価スコア = 駒価値スコア + HP価値スコア + 位置評価スコア + テンポボーナス + ランダムノイズ
単位: センティセント（1.0 = 1歩相当）
```

### 駒価値表

| 駒 | 価値 | HP補正 | スペック値 |
|---|---|---|---|
| 歩/香/桂 | 1 | 0 | 1.0 |
| 銀/金 | 5 | +0.5 | 5.5 |
| 角/飛 | 8 | +1.0 | 9.0 |

### 難易度別パラメータ

| 難易度 | 駒価値:HP価値 | 勝率目標 | ノイズ |
|---|---|---|---|
| 初級 | 70:30 | 40-50% | ±5.0 |
| **中級** | **50:50** | **50±3%** | **±1.0** |
| 上級 | 30:70 | 60%+ | ±0.3 |

### クリティカル局面の特殊評価

```
相手の王に隣接する駒配置      → +50
クリティカルダメージ可能位置   → +30
相手の角/飛を攻撃可能          → +20
自駒HP満タン                  → +5
相手駒HP1（一撃死寸前）        → +15
```

**詳細は** `docs/rambu_shogi_ai_evaluation_spec_v1_0.md` **を参照**

---

## 🔗 参考設計書

すべて `/uploads/` ディレクトリに保存済み：

1. **rambu_shogi_ai_evaluation_spec_v1_0.md** - AI評価関数詳細
2. **乱舞将棋_企画設計書_v1_0.md** - ゲーム企画・バランス検証
3. **rambu_shogi_highlight_flow_v1_0.md** - ハイライト生成フロー
4. **rambu_shogi_implementation_schedule_v1_0.md** - 工程スケジュール・人日
5. **rambu_shogi_code_handoff_v1_0.md** - コード実装引き継ぎ書

---

## 🚀 実装開始チェックリスト

実装着手前に確認：

- [ ] Flutter 3.x + Dart 3.x インストール確認
- [ ] `flutter pub get` で依存パッケージ取得完了
- [ ] Firebase プロジェクト作成済み（Firestore, Auth, Analytics, Cloud Functions）
- [ ] RevenueCat アカウント取得
- [ ] Bitly API キー取得（or 自社ドメイン設定）
- [ ] Unit test フレームワーク（test / mockito）セットアップ完了
- [ ] GitHub Actions CI/CD セットアップ完了

---

## 📝 ブランチ運用

- **開発ブランチ**: `claude/ranbu-shogi-dev-bn07oa`
- **各Phase完了時**: `main` 向けに Pull Request 作成（Draft）
- **コミットメッセージ**: 規約に従い、`Co-Authored-By: Claude Haiku 4.5` 付記

---

## 📞 開発中の判断ポイント

**Gate 1 (Phase 0 → 1)**: 事前設計が完全か ✅ 完了
**Gate 2 (Phase 1 → 2)**: UI実装完了 + 100局自動対局成功か
**Gate 3 (Phase 2 中盤)**: 先手勝率が 50±5% 圏内か
**Gate 4 (Phase 2 → 3)**: 先手勝率が 50±3% に収束したか ← **最大リスク**
**Gate 5 (Phase 3 → 4)**: ハイライト生成成功率 100% か
**Gate 6 (Phase 4 完了)**: 統合テスト全クリア + ストア提出準備完了か

各Gateで詳細設計書を参照し、必要に応じて意思決定。

---

**Last Updated**: 2026-08-27  
**Next Action**: Phase 1 Step 1 - データモデル実装開始
