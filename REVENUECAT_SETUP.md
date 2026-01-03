# RevenueCat セットアップガイド

このガイドでは、領収書アプリにRevenueCat（サブスクリプション管理）を設定する手順を説明します。

## 🎯 前提条件

- App Store Connectでサブスクリプション商品が作成済み
- RevenueCatアカウントが作成済み
- RevenueCatとApp Store Connectが連携済み

## 📋 セットアップ手順

### 1. パッケージのインストール

ターミナルでプロジェクトのルートディレクトリに移動し、以下のコマンドを実行してください：

```bash
flutter pub get
```

### 2. RevenueCat API キーの設定

#### 2-1. API キーを取得

1. RevenueCat ダッシュボードにログイン: https://app.revenuecat.com/
2. プロジェクトを選択
3. 左側メニューまたは上部メニューから「Settings」→「API keys」を選択
4. **Public app-specific API keys** セクションで iOS の API キーをコピー
   - 形式: `appl_xxxxxxxxxxxxxxxxxx`

#### 2-2. .env ファイルに API キーを設定

プロジェクトのルートディレクトリにある `.env` ファイルを開いて、以下のように API キーを設定してください：

```bash
# RevenueCat API Key
REVENUECAT_API_KEY=appl_xxxxxxxxxxxxxxxxxx
```

**注意**:
- `.env` ファイルは `.gitignore` に含まれているため、Git にコミットされません
- 実際の API キーに置き換えてください（`YOUR_API_KEY_HERE` の部分）

### 3. 設定の確認

以下の設定が正しく行われているか確認してください：

#### App Store Connect の商品ID
- 月額プラン: `receipt_monthly`
- 年額プラン: `receipt_premium`

#### RevenueCat の Entitlement ID
- `premium`

#### RevenueCat の Offering ID
- `default`

これらの設定は `lib/utils/constants.dart` の `RevenueCatConfig` クラスで定義されています。

### 4. アプリの実行

```bash
flutter run
```

アプリ起動時に以下のメッセージがコンソールに表示されれば成功です：

```
✅ RevenueCat APIキーを.envから読み込みました
```

もし以下のメッセージが表示される場合は、`.env` ファイルの設定を確認してください：

```
⚠️ RevenueCat APIキーが.envに設定されていません
```

## 🧪 テスト方法

### Sandbox テストアカウントの作成

1. App Store Connect にアクセス
2. 「ユーザとアクセス」→「Sandbox」タブ
3. テスト用の Apple ID を作成

### 実機でのテスト

1. iOS 実機でアプリをビルド・実行
2. Sandbox アカウントでサインイン
3. サブスクリプション購入をテスト
4. RevenueCat ダッシュボードの「Customers」タブで購入が記録されているか確認

## 📝 トラブルシューティング

### API キーが読み込まれない

- `.env` ファイルがプロジェクトのルートディレクトリにあることを確認
- API キーが正しい形式（`appl_` で始まる）であることを確認
- `flutter clean && flutter pub get` を実行してリビルド

### サブスクリプションが表示されない

- RevenueCat の Offerings が「Current」に設定されているか確認
- Package が正しい製品ID（`receipt_monthly`）に紐付いているか確認
- App Store Connect で商品のステータスが「審査待ち」または「承認済み」であるか確認

### 購入がエラーになる

- Sandbox アカウントでログインしているか確認
- 実機でテストしているか確認（シミュレータでは購入できません）
- App Store Connect と RevenueCat の連携（Shared Secret）が正しく設定されているか確認

## 🔐 セキュリティについて

- `.env` ファイルは **絶対に Git にコミットしないでください**
- `.gitignore` に `.env` が含まれていることを確認してください
- チームメンバーには `.env.example` を共有し、各自で `.env` ファイルを作成してもらってください

## 📚 参考資料

- [RevenueCat 公式ドキュメント](https://www.revenuecat.com/docs)
- [Flutter SDK ガイド](https://www.revenuecat.com/docs/getting-started/installation/flutter)
- [App Store Connect ヘルプ](https://developer.apple.com/help/app-store-connect/)
