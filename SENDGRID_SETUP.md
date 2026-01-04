# SendGrid + Firebase Extension 設定ガイド

## 概要

ReceiptQRアプリでは、領収書PDF作成後に自動的にメール送信する機能を実装予定です。
この機能はFirebase ExtensionとSendGridを組み合わせて実現します。

**メール送信フロー**:
1. ユーザーが領収書作成
2. PDF生成 → Firebase Storage アップロード
3. `emailQueue` Firestoreコレクションにドキュメント追加
4. Firebase Extensionが自動検知してSendGrid経由でメール送信
5. メールにPDFを添付して送信

---

## 実装状況

### ✅ 完了済み

- ReceiptRepositoryにメール送信キュー追加機能実装
- Firestoreの`emailQueue`コレクションへのドキュメント追加処理
- 設定画面でメール送信ON/OFF切り替え機能

**実装ファイル**:
- `lib/repositories/receipt_repository.dart`: `_addToEmailQueue()` メソッド
- `lib/screens/settings/settings_screen.dart`: メール送信トグルスイッチ
- `lib/models/store.dart`: `emailNotificationEnabled` フィールド

### ❌ 未実装（外部設定が必要）

- SendGridアカウント設定
- Firebase Extension インストール
- メールテンプレートカスタマイズ（オプション）

---

## セットアップ手順

### ステップ1: SendGridアカウント作成

1. **アカウント登録**
   - https://sendgrid.com/ にアクセス
   - 「Start for Free」をクリック
   - 必要情報を入力して登録
   - メールアドレスを認証

2. **プラン選択**
   - Free Plan: 100通/日（開発・テスト用）
   - Essentials: $19.95/月〜 40,000通/月（本番運用）

   まずはFree Planで開始推奨

---

### ステップ2: SendGrid API Key 作成

1. SendGridダッシュボードにログイン
2. 左メニュー「Settings」→「API Keys」
3. 「Create API Key」ボタンをクリック
4. 設定:
   - API Key Name: `ReceiptQR Production`
   - API Key Permissions: **Mail Send** または **Full Access**
5. 「Create & View」をクリック
6. **表示されたAPI Keyを必ずコピーして安全な場所に保存**
   - 例: `SG.abc123xyz789...`（再表示不可）

---

### ステップ3: Sender Authentication（送信元認証）

メール送信にはSendGridでの送信元認証が必須です。2つの方法があります：

#### オプション1: Single Sender Verification（簡単・推奨）

**メリット**: DNS設定不要、5分で完了
**デメリット**: 1つのメールアドレスのみ

1. SendGridダッシュボード → 「Settings」→「Sender Authentication」
2. 「Single Sender Verification」セクションの「Get Started」
3. フォーム入力:
   ```
   From Name: ReceiptQR
   From Email Address: y_akagi@improve-biz.com
   Reply To: y_akagi@improve-biz.com
   Company Address: 北海道帯広市東3条南12丁目1-5-205
   City: 帯広市
   Country: Japan
   ```
4. 「Create」をクリック
5. `y_akagi@improve-biz.com` 宛に届く認証メールのリンクをクリック
6. 認証完了（即時利用可能）

#### オプション2: Domain Authentication（本格運用向け）

**メリット**: ドメイン全体で利用可能、配信率向上
**デメリット**: DNS設定が必要（最大48時間）

⚠️ **現在DNS反映待ちのため、後日実施推奨**

1. SendGridダッシュボード → 「Settings」→「Sender Authentication」
2. 「Authenticate Your Domain」セクションの「Get Started」
3. DNS Provider選択（お使いのDNSサービスを選択）
4. ドメイン入力: `improve-biz.com`
5. 表示されたDNSレコードをDNS設定に追加:
   ```
   Type: CNAME
   Host: em1234.improve-biz.com
   Value: u1234567.wl.sendgrid.net

   Type: CNAME
   Host: s1._domainkey.improve-biz.com
   Value: s1.domainkey.u1234567.wl.sendgrid.net

   Type: CNAME
   Host: s2._domainkey.improve-biz.com
   Value: s2.domainkey.u1234567.wl.sendgrid.net
   ```
6. DNS反映を待つ（最大48時間）
7. SendGridで「Verify」をクリックして確認

---

### ステップ4: Firebase Extension インストール

1. **Firebase Consoleにアクセス**
   - https://console.firebase.google.com/
   - プロジェクト: `receipt20260102`

2. **Extensionページを開く**
   - 左メニュー「Extensions」
   - 「Browse Extensions」をクリック

3. **Extension検索**
   - 検索: `Trigger Email from Firestore`
   - 提供元: Firebase（公式）
   - 「Install」をクリック

4. **Extension設定**

   以下の項目を入力:

   | 項目 | 値 | 説明 |
   |------|-----|------|
   | Cloud Functions location | `asia-northeast1` | 東京リージョン |
   | Email documents collection | `emailQueue` | コードで使用中のコレクション名 |
   | Email from address | `y_akagi@improve-biz.com` | 送信元メールアドレス |
   | Email from name | `ReceiptQR` | 送信者名 |
   | SMTP connection URI | `smtps://apikey:[YOUR_API_KEY]@smtp.sendgrid.net:465` | 下記参照 |
   | Default reply-to address | `y_akagi@improve-biz.com` | 返信先 |
   | Users collection | `users` | オプション |
   | Templates collection | `emailTemplates` | オプション |

   **SMTP connection URI の作成方法**:
   ```
   smtps://apikey:[YOUR_SENDGRID_API_KEY]@smtp.sendgrid.net:465
   ```

   例（API Key が `SG.abc123xyz` の場合）:
   ```
   smtps://apikey:SG.abc123xyz@smtp.sendgrid.net:465
   ```

5. **インストール実行**
   - 「Install extension」をクリック
   - 3〜5分待つ
   - ステータスが「Active」になることを確認

6. **Cloud Functions確認**
   - 左メニュー「Functions」
   - 以下の関数が作成されていることを確認:
     - `ext-firestore-send-email-processQueue`

---

### ステップ5: HTMLメールテンプレート作成（オプション）

カスタムHTMLメールを送信する場合、Firestoreにテンプレートを作成します。

1. **Firebase Console → Firestore Database**

2. **コレクション作成**
   - コレクションID: `emailTemplates`

3. **ドキュメント作成**
   - ドキュメントID: `receiptCreated`
   - フィールド:

   ```json
   {
     "subject": "領収書が作成されました - {{receiptNumber}}",
     "html": "<html><body><h2>領収書作成完了</h2><p>{{storeName}}から領収書が発行されました。</p><table><tr><td>領収書番号:</td><td>{{receiptNumber}}</td></tr><tr><td>宛名:</td><td>{{recipientName}}</td></tr><tr><td>金額:</td><td>¥{{totalAmount}}</td></tr><tr><td>発行日:</td><td>{{issueDateString}}</td></tr></table><p>PDFファイルを添付しています。</p><p>---<br>ReceiptQR<br>https://improve-biz.com</p></body></html>",
     "text": "領収書が作成されました\n\n店舗: {{storeName}}\n領収書番号: {{receiptNumber}}\n宛名: {{recipientName}}\n金額: ¥{{totalAmount}}\n発行日: {{issueDateString}}\n\nPDFファイルを添付しています。\n\n---\nReceiptQR\nhttps://improve-biz.com"
   }
   ```

**変数の説明**:
- `{{receiptNumber}}`: 領収書番号
- `{{recipientName}}`: 宛名
- `{{totalAmount}}`: 金額（フォーマット済み）
- `{{issueDateString}}`: 発行日
- `{{storeName}}`: 店舗名

---

### ステップ6: テスト送信

1. **アプリで設定画面を開く**
   - 「PDF作成後のメール送信」トグルをON

2. **領収書を1件作成**
   - ホーム画面から領収書作成
   - 必要事項を入力して「作成」

3. **Firestore確認**
   - Firebase Console → Firestore Database
   - `emailQueue` コレクションを確認
   - 新しいドキュメントが追加されていることを確認
   - `status` フィールドが以下のように変化:
     - `pending` → `processing` → `success`

4. **メール受信確認**
   - `y_akagi@improve-biz.com` のメールボックスを確認
   - 件名「領収書が作成されました - R-2026-00001」のようなメールが届く
   - PDFが添付されていることを確認

---

## トラブルシューティング

### 問題: メールが届かない

#### 確認1: Firestoreのstatusフィールド

```javascript
// Firestore emailQueue コレクション
{
  status: "error",
  error: {
    message: "エラーメッセージ"
  }
}
```

**よくあるエラー**:
- `Invalid API key`: API Keyが間違っている
- `Sender not verified`: 送信元認証が未完了
- `SMTP authentication failed`: SMTP URIの形式が間違っている

#### 確認2: SendGrid Activity

1. SendGridダッシュボード → 「Email Activity」
2. 送信履歴とエラーを確認
3. Blocked/Bounced メールがないか確認

#### 確認3: Cloud Functions Logs

1. Firebase Console → 「Functions」
2. `ext-firestore-send-email-processQueue` をクリック
3. 「Logs」タブでエラーメッセージを確認

#### 確認4: SMTP接続情報

SMTP URIの形式を再確認:
```
smtps://apikey:[API_KEY]@smtp.sendgrid.net:465
```

- `apikey` の後のコロンとAPI Keyの間にスペースがないこと
- API Keyが完全にコピーされていること
- `@smtp.sendgrid.net:465` が正しいこと

---

### 問題: statusが"pending"のまま変わらない

**原因**: Extension未インストールまたは未起動

**解決方法**:
1. Firebase Console → 「Extensions」で状態確認
2. ステータスが「Active」であることを確認
3. 「Functions」でCloud Functionが存在することを確認
4. Extensionを再インストール

---

### 問題: メールは届くがPDFが添付されていない

**原因**: PDFのURLが正しくない、またはアクセス権限がない

**解決方法**:
1. Firestoreの`emailQueue`ドキュメントを確認
2. `attachments`配列の`path`フィールドを確認
3. Firebase StorageのPDFファイルの公開設定を確認
4. Storage Rulesで`pdfUrl`が読み取り可能か確認

---

## 料金について

### SendGrid

| プラン | 料金 | 送信数 | 備考 |
|--------|------|--------|------|
| Free | $0/月 | 100通/日 | 開発・テスト用 |
| Essentials | $19.95/月 | 40,000通/月 | 本番運用 |
| Pro | $89.95/月 | 150,000通/月 | 大規模運用 |

**推奨**: まずFree Planで開始 → 送信数が増えたらEssentialsに移行

### Firebase

- **Cloud Functions**: 200万回/月まで無料
- **Extension実行**: 無料枠内で十分対応可能
- **Firestore読み書き**: emailQueueの読み書き程度なら無料枠内

**注意**: Firebase Blaze Plan（従量課金）への移行が必要

---

## 本番運用前チェックリスト

- [ ] SendGrid API Key作成完了
- [ ] SendGrid Sender Authentication完了（Single SenderまたはDomain）
- [ ] Firebase Extension「Trigger Email from Firestore」インストール完了
- [ ] Extension設定でSMTP URIにAPI Key設定完了
- [ ] テストメール送信成功（PDFも添付されている）
- [ ] Firebase Blaze Plan有効化
- [ ] SendGrid送信制限確認（Free: 100通/日）
- [ ] メール本文のカスタマイズ（HTMLテンプレート）
- [ ] エラー通知設定（Firebase Functions Logsアラート）
- [ ] SendGrid Webhook設定（Bounced/Spam対応）

---

## 参考リンク

- **SendGrid公式ドキュメント**: https://docs.sendgrid.com/
- **Firebase Extension**: https://extensions.dev/extensions/firebase/firestore-send-email
- **SendGrid API Reference**: https://docs.sendgrid.com/api-reference/
- **Firebase Functions**: https://firebase.google.com/docs/functions

---

## 補足: 現在の実装詳細

### `lib/repositories/receipt_repository.dart`

```dart
/// メール送信キューに追加
Future<void> _addToEmailQueue({
  required String userId,
  required Receipt receipt,
  required Store store,
}) async {
  try {
    final userDoc = await _firestore
        .collection(FirestoreCollections.users)
        .doc(userId)
        .get();

    final userEmail = userDoc.data()?['email'] as String?;
    if (userEmail == null) {
      print('🟡 ReceiptRepository: ユーザーのメールアドレスが見つかりません');
      return;
    }

    // メール送信キューにドキュメントを追加
    await _firestore.collection('emailQueue').add({
      'to': userEmail,
      'template': {
        'name': 'receiptCreated',
        'data': {
          'receiptNumber': receipt.receiptNumber,
          'recipientName': receipt.recipientName,
          'totalAmount': Formatters.formatAmount(receipt.totalAmount),
          'issueDateString': receipt.issueDateString,
          'storeName': store.storeName,
        },
      },
      'attachments': receipt.pdfUrl != null
          ? [
              {
                'filename': '${receipt.receiptNumber}.pdf',
                'path': receipt.pdfUrl,
              }
            ]
          : [],
      'status': 'pending',
      'userId': userId,
      'receiptId': receipt.id,
      'createdAt': Timestamp.now(),
    });

    print('🟢 ReceiptRepository: メール送信キュー追加成功 - to: $userEmail');
  } catch (e) {
    print('🔴 ReceiptRepository: メール送信キュー追加エラー - $e');
    // メール送信エラーは無視して処理を続行
  }
}
```

### Firestoreドキュメント構造

**コレクション**: `emailQueue`

```json
{
  "to": "y_akagi@improve-biz.com",
  "template": {
    "name": "receiptCreated",
    "data": {
      "receiptNumber": "R-2026-00001",
      "recipientName": "株式会社サンプル",
      "totalAmount": "10,000",
      "issueDateString": "2026年1月4日",
      "storeName": "業務改善屋さん"
    }
  },
  "attachments": [
    {
      "filename": "R-2026-00001.pdf",
      "path": "https://firebasestorage.googleapis.com/v0/b/..."
    }
  ],
  "status": "pending",
  "userId": "abc123",
  "receiptId": "xyz789",
  "createdAt": "2026-01-04T12:00:00Z"
}
```

---

最終更新: 2026年1月4日
