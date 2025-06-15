#!/bin/bash

# ビルド
swift build

# バンドルディレクトリの作成
mkdir -p .build/debug/NovakeyIM.bundle/Contents/MacOS
mkdir -p .build/debug/NovakeyIM.bundle/Contents/Resources

# バイナリのコピー
cp .build/debug/libNovakeyIM.dylib .build/debug/NovakeyIM.bundle/Contents/MacOS/NovakeyIM

# Info.plistのコピー
cp Sources/NovakeyIM/Info.plist .build/debug/NovakeyIM.bundle/Contents/

# 入力メソッドのインストール
sudo mkdir -p /Library/Input\ Methods/
sudo cp -r .build/debug/NovakeyIM.bundle /Library/Input\ Methods/

echo "インストールが完了しました。"
echo "システム環境設定の「キーボード」→「入力ソース」から「Novakey」を追加してください。" 