# ReceiptQR - 次回アップデート予定

最終更新: 2026年1月4日

## 優先度：高

### 1. メール送信機能の実装

**概要**: 領収書PDF作成後に自動でメール送信する機能

**必要な作業**:
- [ ] SendGridアカウント作成
- [ ] SendGrid API Key取得
- [ ] SendGrid Sender Authentication設定
  - Single Sender Verification（y_akagi@improve-biz.com）
  - または Domain Authentication（improve-biz.com - DNS設定必要）
- [ ] Firebase Extension「Trigger Email from Firestore」インストール
- [ ] Extension設定
  - Email documents collection: `emailQueue`
  - Email from address: `y_akagi@improve-biz.com`
  - Email from name: `ReceiptQR`
  - SMTP connection URI: `smtps://apikey:[API_KEY]@smtp.sendgrid.net:465`
  - Reply-to address: `y_akagi@improve-biz.com`
- [ ] HTMLメールテンプレート作成（オプション）
  - Firestoreに`emailTemplates`コレクション作成
  - ドキュメント`receiptCreated`を追加
- [ ] テスト送信実行
- [ ] エラーハンドリング確認

**実装状況**:
- ✅ ReceiptRepositoryにメール送信キュー追加機能実装済み
- ✅ 設定画面でメール送信ON/OFF切り替え実装済み
- ❌ Firebase Extension未インストール（外部設定が必要）

**参考ドキュメント**:
- SendGrid公式: https://sendgrid.com/
- Firebase Extension: https://extensions.dev/extensions/firebase/firestore-send-email

**想定工数**: 2-3時間（DNS設定待ち時間除く）

---

### 2. アプリ説明文の作成

**概要**: App Store・Google Play用のアプリ説明文作成

**必要な作業**:
- [ ] 短い説明文（80文字以内）
- [ ] 詳細説明文（4000文字以内）
- [ ] キーワード選定
- [ ] スクリーンショット用の文言
- [ ] 日本語・英語両方

**想定工数**: 1-2時間

---

### 3. ユーザー向けヘルプ・FAQ

**概要**: アプリ内FAQページの作成

**必要な作業**:
- [ ] よくある質問のリストアップ
- [ ] 回答の作成（Markdown形式）
- [ ] FAQ表示画面の実装
- [ ] 設定画面からのリンク追加

**想定工数**: 2-3時間

---

### 4. エラーメッセージの改善

**概要**: ユーザーフレンドリーなエラーメッセージに改善

**必要な作業**:
- [ ] 既存エラーメッセージの洗い出し
- [ ] わかりやすい日本語メッセージに書き換え
- [ ] エラー時の対処方法を含める
- [ ] constants.dartにエラーメッセージを集約

**想定工数**: 2-3時間

---

## 優先度：中

### 5. アナリティクス・トラッキングの実装

**概要**: ユーザー行動分析のための実装

**必要な作業**:
- [ ] Firebase Analytics設定確認
- [ ] 主要イベントの定義
  - 領収書作成
  - PDF生成
  - サブスクリプション購入
  - ログイン/ログアウト
- [ ] イベントログ実装
- [ ] Google Analytics連携（オプション）

**想定工数**: 3-4時間

---

### 6. Firebase Crashlytics の設定

**概要**: クラッシュレポート収集

**必要な作業**:
- [ ] Firebase Crashlytics SDK追加（既に追加済みか確認）
- [ ] iOS/Android設定
- [ ] テストクラッシュ実行
- [ ] ダッシュボード確認

**想定工数**: 1-2時間

---

## 優先度：低

### 7. 領収書デザインのカスタマイズ機能

**概要**: ユーザーが領収書のレイアウトやスタイルを選択可能に

**想定工数**: 8-10時間

---

### 8. 領収書の一括エクスポート機能

**概要**: 複数の領収書をZIPでまとめてダウンロード

**想定工数**: 4-5時間

---

### 9. ダークモード対応

**概要**: アプリ全体のダークテーマ実装

**想定工数**: 5-6時間

---

### 10. 多言語対応（英語）

**概要**: アプリUIの英語対応

**想定工数**: 8-10時間

---

## 技術的改善項目

### コードリファクタリング
- [ ] Provider → Riverpod 2.0完全移行確認
- [ ] テストコード追加（Unit Test, Widget Test）
- [ ] CI/CD パイプライン構築

### パフォーマンス最適化
- [ ] 画像圧縮処理の最適化
- [ ] PDF生成速度の改善
- [ ] Firestore読み込み最適化（キャッシュ活用）

---

## 完了済み（今回のアップデート）

- ✅ サブスクリプション機能実装（3日間トライアル、月額/年額プラン）
- ✅ StoreKit Configuration（ローカルテスト環境）
- ✅ プライバシーポリシー作成（日本語・英語）
- ✅ 利用規約作成（日本語・英語）
- ✅ サブスクリプション法的表示作成
- ✅ App Store申請用ドキュメント作成（テキスト形式）
- ✅ 法的文書表示画面実装（Markdown対応）
- ✅ 設定画面・サブスクリプション画面への法的文書リンク追加
- ✅ QRコードをPDF URLに変更（データからURLへ）
- ✅ PDF生成2段階方式（QRコード付きPDF再生成）
- ✅ チュートリアル画面実装（予定）

---

## 備考

### DNS設定待ち
- SendGrid Domain Authentication設定が可能になり次第実施
- 現在はSingle Sender Verificationで対応可能

### App Store審査前チェックリスト
- [ ] プライバシーポリシーURL設定
- [ ] 利用規約URL設定（カスタムEULA）
- [ ] スクリーンショット準備（必須サイズ）
- [ ] アプリアイコン最終確認
- [ ] テストアカウント情報準備
- [ ] ビルド番号インクリメント
- [ ] リリースノート作成
