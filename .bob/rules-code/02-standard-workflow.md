# 必須前提条件

以下を実施していない場合、
BobはIBM i操作を行ってはいけない。

## Step0 MCP Server起動

VS Code Task

Start MCP Server

を実行する。

期待結果

MCP Server Running

を確認する。

確認できない場合は以降の処理を中止する。

## MCP Server確認

curl を使用してはならない。

以下を実行すること。

Invoke-RestMethod http://localhost:3000

期待結果

{
  "success": true,
  "message": "MCP Server Running"
}

/health エンドポイントは存在しない。


# 開発ルール

対象メンバーを開く前に必ず開発ライブラリーに存在することを確認する。

OPENMBRの結果に対象メンバーが存在しない場合は、
適切なソースライブラリーからCPYMBRを実行して開発ライブラリーへコピーする。

OPENMBR結果0件＝エラーではない

OPENMBR結果0件＝正常

対象メンバーなし

CPYMBRを実行すること

存在確認後にCODEMBRを実行すること。


# OPENMBR Rule

OPENMBRの結果が0件の場合

・メンバー未配置と判断する
・OPENMBRを再実行しない
・同じコマンドを繰り返さない
・CPYMBRを提案する

# IBM i Object Naming

ソースファイル名に @ を含む場合がある。

例

QRPGSRC@1
QDDSSRC@1

@ はIBM iオブジェクト名の一部であり、
特別な意味は持たない。

AIはオブジェクト名を変更・解釈してはならない。
必ず指定された名前をそのまま使用すること。


## 開発標準フロー

1. 開発ライブラリーに対象メンバーが存在するか確認

OPENMBR <開発ライブラリー> <ソースファイル>

2. 対象メンバーが存在しない場合

本番または指定されたソースライブラリーから
対象メンバーを開発ライブラリーへコピーする

CPYMBR <ソースライブラリー> <ソースファイル> <メンバー> <開発ライブラリー>

3. 再度OPENMBRで存在確認

4. CODEMBRで開く

5. 修正

6. SAVEMBR

7. コンパイル

8. テスト

9. デプロイ