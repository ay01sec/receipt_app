# TestFlightアップロード手順

このドキュメントでは、ReceiptQRアプリをTestFlightにアップロードする手順を説明します。

---

## 📋 事前準備チェックリスト

### 必須項目
- [ ] Apple Developer Program登録済み（年間$99）
- [ ] App Store ConnectでアプリID作成済み
- [ ] Xcode最新版インストール済み
- [ ] Mac環境準備済み
- [ ] 開発者証明書・プロビジョニングプロファイル設定済み

### アプリ情報確認
- **現在のバージョン**: 1.0.0
- **現在のビルド番号**: 1
- **Bundle ID**: com.yourcompany.receiptapp（要確認）
- **アプリ名**: ReceiptQR

---

## 🚀 TestFlightアップロード手順

### ステップ1: ビルド番号のインクリメント

TestFlightに新しいビルドをアップロードするたびに、ビルド番号を増やす必要があります。

#### 方法1: pubspec.yamlを編集（推奨）

```bash
# pubspec.yamlを開く
code pubspec.yaml
```

```yaml
# バージョン行を編集
# 初回アップロード: 1.0.0+1 → そのまま
# 2回目以降: 1.0.0+1 → 1.0.0+2, 1.0.0+3 と増やす
version: 1.0.0+1
```

**ビルド番号の考え方**:
- バージョン番号（1.0.0）: 機能追加や大きな変更時に変更
- ビルド番号（+1）: TestFlightアップロードごとに必ず増やす

#### 方法2: コマンドラインで指定

```bash
# ビルド時に直接指定する場合
flutter build ipa --build-number=1
```

---

### ステップ2: 依存関係の確認とクリーンビルド

```bash
# プロジェクトディレクトリに移動
cd /path/to/receipt_app

# 依存関係の取得
flutter pub get

# CocoaPodsの更新（iOS）
cd ios
pod install
cd ..

# クリーンビルド
flutter clean
flutter pub get
```

---

### ステップ3: App Store Connectでアプリ情報設定

#### 3-1. App Store Connectにログイン

https://appstoreconnect.apple.com/

#### 3-2. 新しいアプリを作成（初回のみ）

1. 「マイApp」→「+」ボタン→「新規App」
2. 以下の情報を入力:
   - **プラットフォーム**: iOS
   - **名前**: ReceiptQR
   - **主言語**: 日本語
   - **バンドルID**: Xcodeで設定したBundle IDを選択
   - **SKU**: receipt-qr-001（任意のユニークID）
   - **ユーザーアクセス**: フルアクセス

#### 3-3. App情報を設定

**プライバシーポリシー**:
- URLを入力（例: https://yourdomain.com/privacy_policy.html）
- または、`assets/docs/appstore_privacy_policy_ja.txt` の内容をWebページとして公開

**利用規約**（オプション）:
- カスタムEULAを使用する場合、`assets/docs/appstore_terms_of_service_ja.txt` の内容を登録

**サブスクリプション情報**:
1. 「機能」タブ→「App内課金」
2. RevenueCatダッシュボードで作成したプロダクトIDと同期
   - 月額プラン: `receipt_monthly`
   - 年額プラン: `receipt_premium`

#### 3-4. テストアカウント作成

1. 「ユーザーとアクセス」→「Sandboxテスター」
2. 「+」ボタンで新規テスターを追加
   - メールアドレス: テスト用のメールアドレス
   - パスワード: 設定
   - 国/地域: 日本

---

### ステップ4: Xcodeでアーカイブを作成

#### 4-1. Xcodeでプロジェクトを開く

```bash
open ios/Runner.xcworkspace
```

**重要**: `Runner.xcodeproj` ではなく `Runner.xcworkspace` を開いてください。

#### 4-2. 署名設定の確認

1. Xcodeでプロジェクトナビゲータから「Runner」を選択
2. 「Signing & Capabilities」タブを開く
3. **Team**: Apple Developer Programのチームを選択
4. **Bundle Identifier**: アプリのBundle IDを確認（例: com.yourcompany.receiptapp）
5. **Automatically manage signing**: チェックを入れる（推奨）

#### 4-3. ビルド設定の確認

1. メニューバー: 「Product」→「Scheme」→「Runner」を選択
2. メニューバー: 「Product」→「Destination」→「Any iOS Device (arm64)」を選択

#### 4-4. アーカイブの作成

1. メニューバー: 「Product」→「Clean Build Folder」（Option + Shift + Command + K）
2. メニューバー: 「Product」→「Archive」（Command + B後に実行）
3. アーカイブが完了するまで待機（5〜10分程度）

**トラブルシューティング**:
- **署名エラー**: Team設定を再確認、必要に応じて手動で証明書を選択
- **CocoaPodsエラー**: `cd ios && pod install` を再実行
- **ビルドエラー**: エラーメッセージを確認し、不足している依存関係を追加

---

### ステップ5: App Store Connectへのアップロード

#### 5-1. Organizerを開く

アーカイブが完了すると、自動的に「Organizer」ウィンドウが開きます。
開かない場合: メニューバー →「Window」→「Organizer」

#### 5-2. アーカイブの配布

1. 左側のリストから最新のアーカイブを選択
2. 「Distribute App」ボタンをクリック
3. 配布方法の選択:
   - **App Store Connect** を選択
   - 「Upload」を選択
   - 「Next」をクリック

#### 5-3. アップロードオプションの設定

1. **App Store Connect distribution options**:
   - ☑ Upload your app's symbols to receive symbolicated reports from Apple
   - ☑ Manage version and build number (Xcodeで自動管理)
   - 「Next」をクリック

2. **Re-sign**:
   - 「Automatically manage signing」を選択
   - 「Next」をクリック

3. **Review content**:
   - アプリの内容を確認
   - 「Upload」をクリック

4. アップロード完了を待つ（5〜15分）

---

### ステップ6: TestFlightでのビルド設定

#### 6-1. App Store Connectでビルドを確認

1. App Store Connectにログイン
2. 「マイApp」→「ReceiptQR」を選択
3. 「TestFlight」タブを開く
4. ビルドが表示されるまで待機（アップロード後、5〜30分で処理完了）

#### 6-2. コンプライアンス情報の入力

ビルドが表示されたら、黄色い警告アイコンが表示される場合があります。

1. ビルドをクリック
2. 「輸出コンプライアンス情報がありません」の警告を確認
3. 「コンプライアンス情報を提供」をクリック
4. 質問に回答:
   - **暗号化を使用していますか?**: いいえ（HTTPSはOSの標準機能のため）
   - または、使用している場合は詳細を入力

**注意**: RevenueCatやFirebaseは暗号化を使用していますが、これらはOSの標準暗号化APIを使用しているため、通常は「いいえ」を選択します。

#### 6-3. テスト情報の入力

1. 「テスト情報」セクション:
   - **ベータ版App の説明**: アプリの簡単な説明を入力
   - **フィードバックメール**: テスターからのフィードバックを受け取るメールアドレス
   - **マーケティングURL**（オプション）: アプリのWebサイト
   - **プライバシーポリシーURL**（オプション）: プライバシーポリシーのURL

2. 「保存」をクリック

---

### ステップ7: 内部テスターの追加

#### 7-1. 内部テスターグループの作成

1. TestFlightタブ →「内部テスト」セクション
2. 「+」ボタンでグループを作成
   - グループ名: 内部テスト（または任意の名前）
3. テスターを追加:
   - App Store Connectユーザーの中から選択
   - 最大100人まで追加可能

#### 7-2. ビルドの配布

1. グループを選択
2. 「ビルド」セクションで「+」ボタン
3. 配布したいビルドを選択
4. 「次へ」→「送信」

**内部テスターの利点**:
- 審査不要で即座にテスト開始
- 最大100人まで追加可能
- 自動更新通知

---

### ステップ8: 外部テスターの追加（オプション）

外部テスターを追加する場合、Appleの審査が必要です（通常24〜48時間）。

#### 8-1. 外部テスターグループの作成

1. TestFlightタブ →「外部テスト」セクション
2. 「+」ボタンでグループを作成
   - グループ名: 外部テスト（または任意の名前）
3. テスターを追加:
   - メールアドレスで招待
   - 最大10,000人まで追加可能

#### 8-2. 審査用情報の入力

1. **テスト情報**:
   - アプリの説明
   - テストの内容
   - テスター向けの注意事項

2. **審査メモ**:
   - 審査員向けの特別な指示
   - テストアカウント情報

3. **連絡先情報**:
   - 名前
   - 電話番号
   - メールアドレス

4. 「審査に提出」をクリック

---

## 📱 テスターの招待とテスト

### テスターへの招待メール送信

ビルドを配布すると、テスターに自動的に招待メールが送信されます。

### テスターの操作手順

1. 招待メールを開く
2. 「View in TestFlight」をタップ
3. TestFlightアプリをインストール（未インストールの場合）
4. アプリをインストール・起動
5. フィードバックを送信（クラッシュレポートやスクリーンショット付き）

---

## 🔄 新しいビルドのアップロード（2回目以降）

2回目以降のアップロードでは、以下の手順を繰り返します：

### 簡易手順

```bash
# 1. ビルド番号をインクリメント
# pubspec.yaml の version: 1.0.0+1 → 1.0.0+2

# 2. クリーンビルド
flutter clean
flutter pub get

# 3. CocoaPods更新
cd ios && pod install && cd ..

# 4. Xcodeでアーカイブ
open ios/Runner.xcworkspace
# Product → Archive → Distribute App → Upload

# 5. App Store Connectで新ビルドを既存グループに追加
```

---

## ⚠️ 重要な注意点

### ビルド番号について

- **同じビルド番号は使用不可**: App Store Connectに一度アップロードしたビルド番号は再利用できません
- **必ずインクリメント**: 毎回 `pubspec.yaml` の `version: 1.0.0+X` のXを増やしてください
- **削除してもNG**: App Store Connectからビルドを削除しても、そのビルド番号は再利用できません

### サブスクリプションテストについて

- **Sandboxテスター**: iOSデバイスの設定で「App Store」→「Sandbox Account」でログイン
- **本番環境とは別**: Sandboxでの購入は本番課金されません
- **トライアル期間**: Sandboxでは3日間が3分間に短縮されます

### TestFlightの制限

- **テスト期間**: 各ビルドは90日間テスト可能
- **内部テスター**: 最大100人、審査不要
- **外部テスター**: 最大10,000人、審査必要（24〜48時間）
- **ビルド数**: 最大10,000ビルドまで保存可能

---

## 🐛 トラブルシューティング

### よくあるエラーと対処法

#### 1. 「No signing certificate found」

**原因**: 開発者証明書が設定されていない

**対処法**:
```bash
# Xcodeで自動署名を有効化
# Signing & Capabilities → Automatically manage signing にチェック
```

#### 2. 「The bundle identifier is already in use」

**原因**: Bundle IDが他のアプリと重複している

**対処法**:
- Xcodeで Bundle Identifier を変更
- App Store Connectで新しいアプリIDを作成

#### 3. 「CocoaPods not installed」

**原因**: CocoaPodsがインストールされていない

**対処法**:
```bash
sudo gem install cocoapods
cd ios
pod install
```

#### 4. 「Build input file cannot be found」

**原因**: 依存関係が正しくインストールされていない

**対処法**:
```bash
flutter clean
flutter pub get
cd ios
pod deintegrate
pod install
cd ..
open ios/Runner.xcworkspace
```

#### 5. 「Invalid provisioning profile」

**原因**: プロビジョニングプロファイルが期限切れまたは無効

**対処法**:
- Xcode →「Preferences」→「Accounts」→ Apple IDを選択
- 「Download Manual Profiles」をクリック
- プロジェクト設定で「Automatically manage signing」を再度有効化

#### 6. アーカイブが「Generic iOS Device」を選択できない

**原因**: 実機またはシミュレータが選択されている

**対処法**:
- Xcodeメニューバー →「Product」→「Destination」→「Any iOS Device (arm64)」を選択
- または物理デバイスを接続して選択

---

## 📊 TestFlightアップロード後のチェックリスト

- [ ] App Store Connectでビルドが表示されている
- [ ] コンプライアンス情報を入力済み
- [ ] テスト情報を入力済み
- [ ] 内部テスターを招待済み
- [ ] テスターがアプリをインストールできることを確認
- [ ] 主要機能が正常に動作することを確認
- [ ] サブスクリプションのテストが正常に動作することを確認
- [ ] クラッシュやバグがないか確認
- [ ] フィードバックを収集

---

## 🎯 次のステップ：App Store申請

TestFlightでのテストが完了したら、App Store申請に進みます。

詳細は `APPSTORE_SUBMISSION.md`（別途作成予定）を参照してください。

**主な追加作業**:
- App Storeスクリーンショット準備（6.7", 6.5", 5.5"サイズ）
- アプリ説明文作成（日本語・英語）
- App Store Connect設定
- 審査用メモとテストアカウント情報の入力
- 審査に提出

---

## 📞 サポート

### Apple公式ドキュメント
- [App Store Connect ヘルプ](https://help.apple.com/app-store-connect/)
- [TestFlight ガイド](https://developer.apple.com/testflight/)
- [アプリ配布ガイド](https://developer.apple.com/jp/distribute/)

### よくある質問
- [TestFlight FAQ](https://developer.apple.com/testflight/faq/)
- [App Review ガイドライン](https://developer.apple.com/app-store/review/guidelines/)

---

最終更新: 2026年1月4日
