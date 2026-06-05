# IBM i MCP Server

VS Code と IBM i を接続し、ソースメンバーの取得・編集・保存・コンパイル・デプロイを行うための MCP Server プロジェクト。

## 目的

IBM i の既存ソース資産を維持しながら、

* VS Code
* Git
* AI支援ツール

を活用したモダン開発環境を構築する。

---

## Code for IBM i との違い

本プロジェクトは Code for IBM i の代替を目的としたものではない。

### Code for IBM i

Code for IBM i は IBM i 開発向けの成熟した VS Code 拡張であり、

* ライブラリー参照
* ソース編集
* コンパイル
* IFS操作
* ジョブ実行

などを標準機能として提供する。

日常的な IBM i 開発では Code for IBM i の利用を推奨する。

### MCP Server

本プロジェクトは IBM i の操作を API 化し、

* VS Code Task
* AI Coding Assistant
* Claude
* ChatGPT
* 将来的な AI Agent

から利用できる開発基盤を構築することを目的とする。

---

### 位置付け

```text
Code for IBM i
  = 人間中心の開発環境

MCP Server
  = AI連携を前提とした開発基盤
```

両者は競合するものではなく、用途に応じて併用することを想定している。


## システム構成

```text
IBM i
 ↓
MCP Server
 ↓
Workspace
 ↓
VS Code
    ├─ VS Code Task
    ├─ Git
    └─ AI Assistant
```

---

## ライブラリー構成

```text
KJNML   = 本番ライブラリー

KJNMLD  = 開発ライブラリー

KJNMLT  = テストライブラリー
```

### 基本ルール

* 本番ライブラリー（KJNML）は直接編集しない
* 開発はKJNMLDで行う
* コンパイル・検証はKJNMLTで行う
* Gitで履歴管理を行う
* 検証完了後に本番へ反映する


---

## セットアップ

### Repository Clone

```powershell
git clone https://github.com/vivian415/study.git mcp-server

cd mcp-server
```

### Node.js Package Install

```powershell
npm install
```

### .env 作成

```env
IBMI_HOST=
IBMI_USER=
IBMI_PASSWORD=
API_KEY=
```

### MCP Server 起動

VS Code Task

```text
Start MCP Server
```

---

### PowerShell Profile

IBM i MCP コマンドは共通 Profile として管理する。

```powershell
. .\scripts\profile.ps1
```

登録される主なコマンド

* OPENLIB
* OPENOBJ
* OPENMBR
* CODEMBR
* SAVEMBR
* CPYSRC
* CPYMBR
* CRTRPG
* CALLPGM
* DEPLOYMBR
* DEPLOYOBJ

### Profile一本化の理由

PowerShell には複数の Profile が存在する。

* Microsoft.PowerShell_profile.ps1
* Microsoft.VSCode_profile.ps1

それぞれに個別定義を行うと、

* コマンド追加漏れ
* 修正漏れ
* 動作差異

が発生しやすい。

実際に開発中、DEPLOYMBR が VS Code Profile にのみ存在しない状態となり、原因調査が必要になった。

このため、本プロジェクトでは IBM i MCP コマンドを scripts/profile.ps1 に集約し、各 Profile から共通 Profile を読み込む構成としている。

これにより保守性向上と設定差異の防止を図る。


---

## Git運用

### 基本方針

ソースの正本は Git とする。

```text
Workspace
 ↓
Git
 ↓
GitHub
```

IBM i のソースは実行環境上の資産であり、
変更履歴管理は Git により行う。

### 開発時

```powershell
git add .

git commit -m "Update HELLO"

git push
```

### ポリシー

* Workspace を Git 管理対象とする
* Gitで変更履歴を管理する
* 本番ライブラリーを直接編集しない
* Git Commit後に検証を行う
* 検証完了後に本番反映する

---

## 起動手順

1. Open Folder → C:\Users\K4293\mcp-server
2. Run Task → Start MCP Server
3. ブラウザで http://localhost:3000 を確認

正常時

{"success":true,"message":"MCP Server Running"}

### 注意

MCPサーバーは必ず mcp-server フォルダから起動すること。

異なる server.js を起動した場合、
CODEMBR が HELLO.txt のような誤った拡張子で展開される可能性がある。
```

### 注意事項

MCPサーバーを別のワークスペースや別の server.js で起動すると、CODEMBR実行時にソースタイプが正しく取得できない場合がある。

その場合、

```text
HELLO.txt
```

として開いてしまう。

正しく起動した場合は、

```text
HELLO.rpgle
```

のように IBM i のソースタイプに応じた拡張子で開かれる。

今回の事象は server.js の不具合ではなく、異なる server.js を起動していたことが原因であった。



## 開発フロー

### IBMi標準運用手順

IBM i のソース修正依頼を受けた場合は必ず以下の手順に従う。

# IBM i 標準運用手順

IBM i のソース修正依頼を受けた場合は必ず以下の手順に従う。

## Step 0 MCPサーバー確認

まず MCPサーバーが起動していることを確認する。

確認URL

http://localhost:3000

正常時

{"success":true,"message":"MCP Server Running"}

起動していない場合

1. C:\Users\K4293\mcp-server を開く
2. Start MCP Server を実行する
3. localhost:3000 を再確認する

MCPサーバー起動前に IBM i コマンドを実行してはならない。

### Bob利用時の注意1

MCP Server確認時は curl ではなく以下を使用する。

Invoke-RestMethod -Uri "http://localhost:3000"

期待結果

{"success":true,"message":"MCP Server Running"}

## Bobへの重要事項2

本MCPサーバーは .env を使用する。

server.js 起動時には

require("dotenv").config();

が必須。

ODBC接続エラーが発生した場合は
最初に .env の読み込みを確認すること。

接続情報は process.env から取得する。


---

## Step 1 開発ライブラリー確認

対象メンバーが KJNMLD に存在するか確認する。

---

## Step 2 メンバーコピー

KJNMLD に存在しない場合は

CPYMBR

を実行して本番ライブラリーから開発ライブラリーへコピーする。

---

## Step 3 ソースを開く

CODEMBR

を実行して VS Code でソースを開く。

---

## Step 4 編集

ソースを修正する。

---

## Step 5 保存

SAVEMBR

を実行して IBM i へ保存する。

---

## Step 6 コンパイル

ソース種別に応じてコンパイルする。

.rpgle → CRTRPG

.sqlrpgle → CRTSQLRPG

.pf → CRTPF

.dspf → CRTDSPF

---

## Step 7 動作確認

必要に応じて CALLPGM を実行する。

---

## Step 8 デプロイ

検証完了後に

DEPLOYMBR

または

DEPLOYOBJ

を実行する。

---

## 重要

既に用意されている IBM i コマンドを優先して使用する。

OPENLIB

OPENOBJ

OPENMBR

CODEMBR

SAVEMBR

CPYMBR

CRTRPG

CRTSQLRPG

CALLPGM

DEPLOYMBR

DEPLOYOBJ

これらで実現可能な場合は、新しい PowerShell スクリプトや補助ツールを作成してはならない。



明示的な指示がない限り、本手順を標準手順として使用する。
AI Assistant は本手順に従って操作を提案するものとする。


ソース種別に応じて使用するコンパイルコマンドは異なる。

| ソース種別    | 拡張子       | コンパイルコマンド |
| -------- | --------- | --------- |
| RPGLE    | .rpgle    | CRTRPG    |
| SQLRPGLE | .sqlrpgle | CRTSQLRPG |
| PF DDS   | .pf       | CRTPF     |
| DSPF DDS | .dspf     | CRTDSPF   |

CODEMBR実行時にソースタイプを取得し、適切な拡張子でVS Codeへ展開する。

例

```text
HELLO.rpgle
  → CRTRPG

TESTEMP.sqlrpgle
  → CRTSQLRPG

MSHINAF.pf
  → CRTPF
```

## AI Assistant Guidelines

本プロジェクトでは以下を前提とする。

- 本番ライブラリーを直接編集しない
- 編集対象は開発ライブラリーとする
- コンパイルは検証ライブラリーで行う
- デプロイ前にコンパイル確認を行う
- ソース種別に応じたコンパイルコマンドを使用する

ソース種別とコンパイルコマンド

.rpgle    → CRTRPG
.sqlrpgle → CRTSQLRPG
.pf        → CRTPF
.dspf      → CRTDSPF

対象メンバーが開発ライブラリーに存在しない場合は、
本番ライブラリーから開発ライブラリーへ CPYMBR を実行してから CODEMBR を実行する。

AI Assistant は明示的な指示がない限り、以下を前提とする。
* 編集対象は開発ライブラリー
* コンパイル対象は検証ライブラリー
* デプロイ先は本番ライブラリー

ライブラリー名よりも役割（本番・開発・検証）を優先して判断する。

## AI Assistant Additional Rules

既存のIBM iコマンドで実現可能な場合は、
新しいPowerShellスクリプトや補助ツールを作成してはならない。

まず以下のコマンドの利用を検討すること。

OPENLIB
OPENOBJ
OPENMBR
CODEMBR
SAVEMBR
CPYMBR
CRTRPG
CRTSQLRPG
CRTPF
CRTDSPF
CALLPGM
DEPLOYMBR
DEPLOYOBJ

---

## デプロイ方針

### ソース

```text
KJNMLD
 ↓
DEPLOYMBR
 ↓
KJNML
```

### オブジェクト

```text
KJNMLT
 ↓
DEPLOYOBJ
 ↓
KJNML
```

### 正本

```text
ソースの正本 = Git

オブジェクトの正本 = KJNMLT
```

---

## 実装済みコマンド

### ソース操作

| Command | Description |
|----------|-------------|
| OPENLIB | ライブラリー一覧表示 |
| OPENOBJ | オブジェクト一覧表示 |
| OPENMBR | メンバー一覧表示 |
| CODEMBR | メンバーを Workspace に展開し VS Code で開く |
| SAVEMBR | Workspace の内容を IBM i へ保存 |
| CPYSRC | ソースファイルコピー |
| CPYMBR | メンバーコピー |

### コンパイル

| コマンド | 用途 | 状態 |
|----------|------|------|
| CRTRPG | RPGLEコンパイル | ✅ 検証済み |
| CRTSQLRPG | SQLRPGLEコンパイル | ✅ 検証済み |
| CRTPF | PF作成 | ✅ 検証済み※ |
| CRTDSPF | DSPFコンパイル | ⏳ 未検証 |

※ CRTPF は作成先に同名オブジェクトが存在する場合、CPF7302で失敗する。

### 実行

CALLPGM

### デプロイ

DEPLOYMBR

DEPLOYOBJ

---

### コマンド例

```text
cpysrc kjnml qrpgsrc@1 kjnmld

cpymbr kjnml qrpgsrc@1 hello kjnmld

codembr kjnmld qrpgsrc@1 hello

savembr kjnmld qrpgsrc@1 hello

crtrpg kjnmlt kjnmld qrpgsrc@1 hello

callpgm kjnmlt hello

deploymbr kjnmld qrpgsrc@1 hello kjnml

deployobj hello *pgm kjnmlt kjnml
```

SQLRPGLE

```text
codembr kjnmld qrpgsrc@1 testemp

savembr kjnmld qrpgsrc@1 testemp

crtsqlrpg kjnmlt kjnmld qrpgsrc@1 testemp

callpgm kjnmlt testemp
```

DDS (PF)

```text
crtpf kjnmlt kjnml qddssrc mshinaf
```


---

## 検証済み

HELLO メンバーにて以下を確認済み。

```text
OPENMBR
 ↓
CODEMBR
 ↓
編集
 ↓
SAVEMBR
 ↓
CRTRPG
 ↓
CALLPGM
 ↓
DEPLOYMBR
 ↓
DEPLOYOBJ
```

---

## VS Code Task Integration

主要コマンドは VS Code Task として登録済み。

* OPENLIB
* OPENOBJ
* OPENMBR
* CODEMBR
* SAVEMBR
* CPYSRC
* CPYMBR
* CRTRPG
* CRTSQLRPG
* CRTPF
* CALLPGM
* DEPLOYMBR
* DEPLOYOBJ

---

## 今後の予定

* DSPPGMREF
* DSPOBJD
* RTVMBRD
* RUNSQL

* コンパイルエラー解析
* 影響範囲分析
* AI支援機能拡張
* AI Agent連携
