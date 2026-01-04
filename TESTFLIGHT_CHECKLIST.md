# TestFlightアップロード前チェックリスト

このドキュメントは、TestFlightアップロード前に確認・修正すべき項目をまとめたものです。

**作成日**: 2026年1月4日
**現在のステータス**: TestFlightアップロード準備中

---

## ✅ 完了済み項目

### コア機能
- [x] Firebase認証機能（メール/パスワード）
- [x] 店舗情報管理（店舗名、住所、電話番号、インボイス番号、印鑑画像）
- [x] 領収書作成・管理機能
- [x] PDF自動生成（日本語フォント対応）
- [x] QRコードPDF URL埋め込み
- [x] Firebase Storage自動アップロード
- [x] サブスクリプション機能（RevenueCat）
  - [x] 3日間無料トライアル
  - [x] 月額プラン（¥1,000/月）
  - [x] 年額プラン（¥10,000/年）
- [x] StoreKit Configuration（ローカルテスト環境）

### UI/UX
- [x] チュートリアル画面（6ページ）
- [x] 初回起動時の強制表示
- [x] 設定画面からチュートリアル再表示
- [x] 法的文書表示画面（Markdown）
- [x] サブスク画面UI

### 法的文書
- [x] プライバシーポリシー（日本語・英語）
- [x] 利用規約（日本語・英語）
- [x] サブスクリプション規約（日本語・英語）
- [x] App Store申請用テキスト版

### Firebase設定
- [x] Firestore Security Rules
- [x] Storage Rules（PDF公開読み取り）
- [x] Firebase Extensions対応準備

---

## ⚠️ 要確認・要修正項目

### 🔴 必須修正（アップロード前に必ず対応）

#### 1. Bundle Identifierの変更

**現在の設定**: `com.example.receiptApp`
**変更先**: `com.yourcompany.receiptqr`（実際のドメインに変更）

**変更手順**:

```bash
# 1. Xcodeでプロジェクトを開く
open ios/Runner.xcworkspace

# 2. Xcodeで以下を変更:
# - Project Navigator → Runner を選択
# - TARGETS → Runner を選択
# - General タブ → Bundle Identifier を変更
# - 例: com.yourcompany.receiptqr
```

**重要**: Bundle IDは一度App Store Connectに登録すると変更できません。慎重に決定してください。

**推奨形式**: `com.[会社名または個人名].[アプリ名]`

---

#### 2. アプリ表示名の確認

**現在の設定**: `Receipt App`（Info.plist）

**変更が必要な場合**:

```bash
# ios/Runner/Info.plist を編集
# CFBundleDisplayName の値を変更
<key>CFBundleDisplayName</key>
<string>ReceiptQR</string>
```

**注意**: この名前がiOSデバイスのホーム画面に表示されます（最大12文字推奨）。

---

#### 3. App Store Connectでアプリ登録

**App Store Connect URL**: https://appstoreconnect.apple.com/

**必要な情報**:
- **アプリ名**: ReceiptQR
- **主言語**: 日本語
- **Bundle ID**: 上記で設定した新しいBundle ID
- **SKU**: receipt-qr-001（任意のユニークID）

**登録手順**:
1. App Store Connectにログイン
2. 「マイApp」→「+」→「新規App」
3. 上記情報を入力して作成

---

#### 4. App Store Connectでサブスクリプション登録

RevenueCatで使用するプロダクトIDをApp Store Connectに登録する必要があります。

**登録するプロダクト**:

| プロダクトID | 名称 | 期間 | 価格 | トライアル |
|------------|------|------|------|-----------|
| `receipt_monthly` | 月額プラン | 1ヶ月 | ¥1,000 | 3日間無料 |
| `receipt_premium` | 年額プラン | 1年 | ¥10,000 | 3日間無料 |

**登録手順**:
1. App Store Connect →「マイApp」→ ReceiptQR
2. 「機能」タブ →「サブスクリプション」
3. 「+」ボタンでサブスクリプショングループを作成
   - グループ名: Premium
4. グループ内で各プロダクトを作成
   - プロダクトID: `receipt_monthly` / `receipt_premium`
   - サブスクリプション期間: 1ヶ月 / 1年
   - 価格: ¥1,000 / ¥10,000
   - 無料トライアル: 3日間

**重要**: プロダクトIDは `ios/Products.storekit` および RevenueCat ダッシュボードと完全一致させる必要があります。

---

#### 5. RevenueCat設定の確認

**RevenueCat Dashboard**: https://app.revenuecat.com/

**確認事項**:
- [x] プロジェクト作成済み
- [x] iOS App設定済み
- [x] API Key取得済み（`.env`に設定済み）
- [ ] App Store Connectとの連携確認
- [ ] プロダクトID同期確認
  - `receipt_monthly`
  - `receipt_premium`

**連携手順**:
1. RevenueCat Dashboard →「Apps」→ iOS App選択
2. 「App Store Connect」セクションで「Connect to App Store Connect」
3. App Store Connect APIキーまたは共有秘密鍵を入力
4. プロダクトが自動同期されることを確認

---

### 🟡 推奨対応（アップロード後でも可能）

#### 6. アプリアイコンの確認

**場所**: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

**必要なサイズ**:
- 20x20 (@2x, @3x)
- 29x29 (@2x, @3x)
- 40x40 (@2x, @3x)
- 60x60 (@2x, @3x)
- 1024x1024 (App Store用)

**確認方法**:
```bash
# アイコンディレクトリを確認
ls -la ios/Runner/Assets.xcassets/AppIcon.appiconset/
```

**アイコンが未設定の場合**:
1. 1024x1024のマスターアイコンを作成
2. オンラインツール（例: appicon.co）で各サイズを生成
3. `AppIcon.appiconset/` にファイルを配置

---

#### 7. プライバシーポリシーとサポートURLの準備

App Store Connectでは、プライバシーポリシーURLの入力が必須です。

**オプション1: GitHubページで公開**

```bash
# GitHub Pagesを有効化して、以下のURLで公開
https://[あなたのGitHubユーザー名].github.io/receipt_app/privacy_policy_ja.html
```

**オプション2: 独自ドメインで公開**

`assets/docs/appstore_privacy_policy_ja.txt` の内容をHTMLに変換してWebサーバーにアップロード。

**必要なURL**:
- プライバシーポリシーURL（必須）
- 利用規約URL（オプション、カスタムEULA使用時）
- サポートURL（推奨）

---

#### 8. テストアカウント情報の準備

App Store審査時に、審査員がアプリをテストするためのアカウント情報が必要です。

**準備するもの**:
```
メールアドレス: test@example.com
パスワード: TestPassword123!
特記事項:
- サブスクリプション機能をテストする場合はSandbox環境を使用
- 店舗情報は事前に登録済み
```

**作成手順**:
1. アプリで新規ユーザー登録
2. テスト用の店舗情報を登録
3. サンプル領収書を1〜2件作成
4. 上記情報をメモして審査時に提供

---

#### 9. スクリーンショットの準備

TestFlightアップロードには不要ですが、App Store申請時に必要です。

**必要なサイズ**:
- 6.7インチ（iPhone 14 Pro Max）: 1290 x 2796
- 6.5インチ（iPhone 11 Pro Max）: 1242 x 2688
- 5.5インチ（iPhone 8 Plus）: 1242 x 2208

**推奨枚数**: 各サイズ3〜5枚

**撮影する画面**:
1. チュートリアル画面（最初のページ）
2. 領収書作成画面
3. 領収書PDF表示画面
4. 領収書一覧画面
5. サブスクリプション画面

**撮影方法**:
- iOSシミュレータで撮影: Cmd + S
- または実機で撮影してスクリーンショットを転送

---

### 🔵 オプション（将来実装予定）

#### 10. メール送信機能（次回アップデート）

**現在の状態**: バックエンドロジック実装済み、UI非表示

**次回実装タスク**:
- [ ] SendGridアカウント作成
- [ ] Firebase Extension「Trigger Email from Firestore」インストール
- [ ] HTMLメールテンプレート作成
- [ ] 設定画面のコメントアウト解除

詳細: `SENDGRID_SETUP.md` 参照

---

#### 11. Analytics・Crashlytics（推奨）

**Firebase Analytics**:
```bash
# pubspec.yaml に追加（既存パッケージで有効化可能）
firebase_analytics: ^11.0.0
```

**Firebase Crashlytics**:
```bash
# pubspec.yaml に追加
firebase_crashlytics: ^4.0.0
```

**設定手順は次回アップデート時に実施予定**

---

## 📋 TestFlightアップロード直前チェックリスト

アップロード直前に、以下の項目を最終確認してください。

### コード・設定

- [ ] Bundle Identifierを本番用に変更済み
- [ ] pubspec.yaml のバージョン番号確認: `1.0.0+1`
- [ ] `.env` ファイルにRevenueCat API Key設定済み
- [ ] Firebase設定ファイル（GoogleService-Info.plist）配置済み
- [ ] アプリアイコン設定済み
- [ ] Xcode署名設定完了（Team選択済み）

### Firebase

- [ ] Firestore Security Rulesデプロイ済み
- [ ] Storage Rulesデプロイ済み
- [ ] Firebase Authenticationメール/パスワード認証有効化済み
- [ ] Firebase Storage有効化済み

### RevenueCat

- [ ] RevenueCatプロジェクト作成済み
- [ ] iOS App登録済み
- [ ] API Key取得済み
- [ ] App Store Connectとの連携完了
- [ ] プロダクトID同期確認

### App Store Connect

- [ ] Apple Developer Program登録済み（$99/年）
- [ ] App Store Connectでアプリ作成済み
- [ ] サブスクリプション登録済み（receipt_monthly, receipt_premium）
- [ ] プライバシーポリシーURL準備済み
- [ ] テストアカウント情報準備済み

### ローカル環境

- [ ] Xcode最新版インストール済み
- [ ] CocoaPods最新版インストール済み
- [ ] Flutter SDK最新版インストール済み
- [ ] 依存関係インストール完了（`flutter pub get` / `pod install`）

### 機能テスト

- [ ] ユーザー登録・ログイン動作確認
- [ ] 店舗情報登録・編集動作確認
- [ ] 領収書作成・PDF生成動作確認
- [ ] QRコードスキャンでPDF表示確認
- [ ] サブスクリプション購入フロー確認（Sandbox）
- [ ] チュートリアル表示確認

---

## 🚀 TestFlightアップロード手順（概要）

詳細な手順は `TESTFLIGHT_UPLOAD.md` を参照してください。

### ステップ1: ビルド番号確認
```bash
# pubspec.yaml
version: 1.0.0+1  # 初回はこのまま、2回目以降は+2, +3...
```

### ステップ2: クリーンビルド
```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
```

### ステップ3: Xcodeでアーカイブ
```bash
open ios/Runner.xcworkspace
# Product → Archive
```

### ステップ4: App Store Connectへアップロード
```
Organizer → Distribute App → App Store Connect → Upload
```

### ステップ5: TestFlightで内部テスターを招待
```
App Store Connect → TestFlight → 内部テスト → テスター追加
```

---

## ⚠️ 重要な注意事項

### Bundle IDについて
- **変更不可**: 一度App Store Connectに登録したBundle IDは変更できません
- **慎重に決定**: 会社名やドメインを含めた適切なIDを設定してください
- **推奨形式**: `com.[会社名].[アプリ名]`

### ビルド番号について
- **必ずインクリメント**: TestFlightアップロードごとにビルド番号を増やす
- **再利用不可**: 一度使用したビルド番号は削除しても再利用できません
- **管理方法**: `pubspec.yaml` の `version: 1.0.0+X` のXを増やす

### サブスクリプションテストについて
- **Sandbox環境**: 本番課金されないテスト環境を使用
- **テスター設定**: App Store Connect →「ユーザーとアクセス」→「Sandboxテスター」
- **デバイス設定**: iOS設定 →「App Store」→「Sandbox Account」でログイン
- **トライアル期間**: Sandboxでは3日間が3分間に短縮される

### TestFlightの制限
- **テスト期間**: 各ビルドは90日間有効
- **内部テスター**: 最大100人、審査不要、即座にテスト開始
- **外部テスター**: 最大10,000人、Apple審査必要（24〜48時間）

---

## 📞 次のステップ

TestFlightアップロードが完了したら：

1. **内部テスターでテスト**（1〜3日）
   - 主要機能の動作確認
   - バグやクラッシュの確認
   - サブスクリプション購入フローの確認

2. **フィードバック収集**
   - TestFlightのフィードバック機能を活用
   - クラッシュレポートの確認

3. **必要に応じて修正・再アップロード**
   - ビルド番号をインクリメント
   - 同じ手順で再度アップロード

4. **App Store申請準備**
   - スクリーンショット作成
   - アプリ説明文作成
   - 審査用情報の準備

---

## 📚 参考ドキュメント

- `TESTFLIGHT_UPLOAD.md` - TestFlightアップロード詳細手順
- `TODO.md` - 全体タスク管理
- `NEXT_UPDATE.md` - 次回アップデート予定
- `SENDGRID_SETUP.md` - SendGrid設定ガイド
- `REVENUECAT_SETUP.md` - RevenueCat設定ガイド

---

最終更新: 2026年1月4日
