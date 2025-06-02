# Novakey

macOSのキーボード入力監視・ロギングサービス

## 機能

- キーボード入力のリアルタイム監視
- 修飾キー（Shift, Control, Option, Command）の状態記録
- アクティブなアプリケーション情報の記録
- ログファイルへの出力
- デバッグモード

## 必要条件

- macOS 13.0以上
- アクセシビリティ権限

## インストール

1. リポジトリをクローン
```bash
git clone https://github.com/yourusername/novakey.git
cd novakey
```

2. ビルド
```bash
swift build -c release
```

## 使用方法

### 基本的な使用方法

```bash
.build/release/novakey
```

### ログファイルへの出力

```bash
.build/release/novakey --log-file /path/to/log.txt
```

### デバッグモード

```bash
.build/release/novakey --debug
```

## アクセシビリティ権限の設定

1. システム環境設定 > プライバシーとセキュリティ > アクセシビリティ
2. 鍵アイコンをクリックして設定を解除
3. 「+」ボタンをクリック
4. アプリケーションを選択して追加

## セキュリティとプライバシー

- このアプリケーションはキーボード入力を監視するため、アクセシビリティ権限が必要です
- 取得した情報は指定されたログファイルにのみ保存されます
- パスワードなどの機密情報は適切に処理してください

## ライセンス

MIT License 