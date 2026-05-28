# IBM i MCP Server

VS CodeからMCPサーバー経由でIBM iのソースメンバーを取得・編集・保存し、モダンな開発環境で管理するシステム。


## このプロジェクトについて

従来の IBM i 開発環境は、
5250 や SEU を中心とした人間操作を前提としており、
現代的な AI開発ツールから直接扱うことが難しい。

本プロジェクトでは、
IBM i のソース資産や開発操作を API 化し、
VS Code や AI支援ツールと接続することで、
AI活用型 IBM i 開発基盤の構築を目指す。

現在は、

* IBM i メンバーの VS Code 編集
* MCPサーバー経由での保存・コンパイル
* AI支援によるコーディング補助

を中心に検証を行っている。

将来的には、

* AIによるソース解析
* 自動修正
* コンパイル
* エラー解析
* 影響範囲分析
* Git連携

などを含む、
IBM i 開発の AIエージェント化を目標とする。


## MCPサーバー運用と Code for IBM i 運用の違い

### 概要

本環境では IBM i のソース編集方法として、以下の2つの方式を想定している。

- MCPサーバー経由の編集
- Code for IBM i を利用した編集

どちらも VS Code 上でソース編集可能だが、目的と役割が異なる。

### 1. Code for IBM i を利用した運用

### 標準機能

Code for IBM i は、IBM i 開発向けの VS Code 拡張であり、以下の機能を標準提供する。

- ライブラリ参照
- ソースファイル参照
- メンバー編集
- 保存
- コンパイル
- IFS操作
- ジョブ実行

### 運用イメージ

```text
IBM i
 ↓
Code for IBM i
 ↓
VS Code
 ↓
AI拡張（Claude / ChatGPT 等）
```

### 特徴

* 人間が操作主体
* IBM i 開発環境として成熟している
* RPG/DDS/CL の通常開発に向く
* Git連携が容易
* AI補助コーディングとの相性が良い

### 主な用途

* 日常開発
* 保守
* RPG修正
* SQL化
* FREE化
* Git運用


### 2. MCPサーバー経由の運用

### 構成

MCPサーバーは、IBM i の操作を API 化し、AIから利用可能にするための仕組みである。

Node.js + Express + SSH2 を利用して IBM i に接続し、コマンド実行やメンバー操作を行う。

### 運用イメージ

```text
IBM i
 ↓
MCP Server（API化）
 ↓
VS Code / AI
 ↓
Claude / ChatGPT
```

### 現段階での運用

現在は以下の流れで運用する。

```text
OPENMBR
 ↓
VS Codeで編集
 ↓
AI支援でコーディング
 ↓
SAVEMBR
 ↓
CRTRPG / CRTSQLRPG
```

AIが直接 IBM i メンバーを開くのではなく、
人間が MCP経由で開いたソースを AI が編集支援する形となる。

### 特徴

* AIエージェント化を想定
* IBM i 操作を API 化できる
* 将来的な自動化拡張が可能
* AIからコンパイル・解析連携可能

### 主な用途

* AI連携実験
* 自動化検証
* 将来的なAIエージェント開発
* IBM i API基盤構築

### 現時点での推奨運用

| 用途 | 推奨 |
|---|---|
| 日常開発 | Code for IBM i |
| AI連携・検証 | MCPサーバー |

用途に応じて両者を使い分ける。

### 将来的な構想

将来的には MCP を通じて AI が以下を自律実行可能となることを想定する。

- メンバー検索
- ソース解析
- 自動修正
- コンパイル
- エラー解析
- 影響範囲分析
- Git連携

IBM i 開発の AI エージェント化を目標とする。


## 開発コンセプト

VS CodeからMCPサーバー経由でIBM iに接続し、ソースメンバーの取得・編集・保存を行う。既存のソースPF（メンバー）資産を破棄することなく、IBM i（AS/400）の開発をモダナイズ（近代化）します。
### システム構成
```
IBM i Library / Source File / Member
         ↓
      ODBC
         ↓
   MCP Server (server.js)
         ↓
  PC Workspace Folder
         ↓
  VS Code Editor
```

---

## IBM i ファイル構造とPC側フォルダ対応

### IBM i 側の構造
```
ライブラリ (Library)
  ├── ソースファイル (Source File)
  │   ├── メンバー (Member) - RPGLE, CL, DDS等
  │   └── ...
  └── ...
```

**例：**
- ライブラリ: `KJNMLD`
- ソースファイル: `QRPGSRC@1`
- メンバー: `HELLO`

### PC側フォルダ構造
```
workspace/
├── KJNMLD/                    ← ライブラリ名
│   ├── QRPGSRC@1/            ← ソースファイル名
│   │   ├── HELLO.rpgle
│   │   └── ...
│   ├── QCLPSRC/
│   │   ├── SAMPLE.cl
│   │   └── ...
│   └── QDDSSRC/
│       ├── FILE001.dds
│       └── ...
├── CSCH@003/
│   ├── QRPGSRC@1/
│   │   ├── CH03001R.rpg
│   │   └── ...
│   └── ...
└── ...

```
> workspace は IBM i の source structure mirror として動作し、
> PC側に IBM i と同じ論理構造を再現する

### ファイル拡張子マッピング

| IBM i ソースファイル | ファイル種別 | 拡張子 |
|-------------------|-----------|--------|
| QRPGLESRC | RPG IV LE | `.rpgle` |
| QRPGSRC | RPG/400 | `.rpg` |
| QCLSRC | CL/400 | `.cl` |
| QCLESRC | CL LE | `.clle` |
| QDDSSRC | DDS (PF/LF) | `.dds` |
| QPFSRC | Physical File | `.pf` |
| QLFSRC | Logical File | `.lf` |
| QDSPPSRC | Display File | `.dspf` |
| QPRTSRC | Print File | `.prtf` |

---

## セキュリティ

接続情報は `.env` ファイルに定義し、Git管理対象外（.gitignoreに追加）とすることで、機密情報の漏洩を防ぐ：
- IBM i ホスト (IBMI_HOST)
- ユーザーID (IBMI_USER)
- パスワード (IBMI_PASSWORD)
- APIキー (API_KEY)

### 環境設定 (.env ファイル)

```env
IBMI_HOST=your-ibmi-hostname
IBMI_USER=your-username
IBMI_PASSWORD=your-password
API_KEY=your-secure-api-key
```

---

## セットアップ

### 必要環境

- Node.js
- npm
- VS Code
- IBM i Access ODBC Driver
- IBM i 接続権限
- PowerShell 7 推奨

## 初期セットアップ

### repository clone

```powershell
git clone https://github.com/vivian415/study.git mcp-server

cd mcp-server
```

### Node.js library install

```powershell
npm install
```

`package.json` を元に必要な Node.js library を取得し、
`node_modules` を生成する。

### 環境変数設定

`.env` を作成する。

```env
IBMI_HOST=...
IBMI_USER=...
IBMI_PASSWORD=...
API_KEY=...
```

`.env` は Git 管理対象外とし、
絶対に Git repository へ commit しない。


### PowerShell command load

```powershell
. .\scripts\profile.ps1
```

### MCPサーバー起動

```powershell
node server.js
```
サーバーは `http://localhost:3000` で起動します。


**レスポンス:**
```json
{
  "success": true,
  "message": "member saved",
  "lines": 42
}
```

---

## RPG コンパイル

RPG ソースをコンパイルしてプログラムオブジェクトを生成する。

### コマンド

```powershell
CRTRPG <targetlib> <srclib> <srcfile> <member>
```

### パラメータ

| パラメータ | 説明 |
|---|---|
| targetlib | コンパイル先ライブラリ |
| srclib | ソースライブラリ |
| srcfile | ソースファイル |
| member | コンパイル対象メンバー |

### 実行例

```powershell
crtrpg kjnmlt kjnmld qrpgsrc@1 hello
```

### 内部実行コマンド

```cl
CRTBNDRPG PGM(KJNMLT/HELLO)
           SRCFILE(KJNMLD/QRPGSRC@1)
           SRCMBR(HELLO)
```

### 用途

- 開発区画（KJNMLD）に保存したソースを検証区画（KJNMLT）へコンパイルする
- 本番区画へ影響を与えずにテストできる


---

## ワークスペース構成

```
workspace/
 ├── KJNML/           # 本番ランタイムライブラリ
 │    └── QRPGLESRC/
 │         └── TESTEMP.rpgle
 │
 ├── KJNMLD/          # 開発ソースライブラリ
 │    └── QRPGSRC@1/
 │         └── HELLO.rpgle
 │
 └── KJNMLT/          # テスト/コンパイル環境
      └── QRPGSRC@1/
```

---

## ライブラリー構成

```
KJNML   = 本番区画（本番ランタイム）
KJNMLD  = 開発区画（開発ソース）
KJNMLT  = 検証区画（テスト/コンパイル環境）
```

**開発フロー:**
1. 本番区画（KJNML）にある修正対象のソースとメンバーを開発区画（KJNMLD）にコピーする
2. コピーしたメンバーをPC側で開く
3. PC側でメンバーを修正
4. 修正内容を開発区画（KJNMLD）に保存する
5. 修正内容を検証区画（KJNMLT）にコンパイルして検証
6. 問題なければ本番区画（KJNML）にデプロイする

**メモ:**
1. IBM iの検証区画（KJNMLT）は検証に必要な環境をあらかじめ構築しておく
2. PC側（workspace）にはIBM iと同じ階層構造をつくっておく
3. 開発区画にあるソースファイルはGitにPushする
4. 開発区画（KJNMLD）にはソースのみ、検証区画（KJNMLT）はオブジェクトのみを管理する

---

## エラーハンドリング

エラー時の統一されたレスポンス形式：

```json
{
  "success": false,
  "error": "message"
}
```

## 実行フロー

```text
1. MCPサーバー起動
2. IBM i からソースメンバーを取得 → workspace に保存
3. VS Code で編集
4. 修正内容を IBM i に保存
5. コンパイル
6. プログラム実行・検証
7. 本番 source member deploy
8. 本番 object deploy
```


---

## 注意事項

- ライブラリ名、ソースファイル名、メンバー名は大文字で統一
- PC側フォルダはIBM i の物理構造を反映
- `.env` ファイルは絶対にGitにコミットしない

---

## デプロイフロー

```text
KJNML   = 本番環境
KJNMLD  = 開発ソース環境
KJNMLT  = 検証/コンパイル環境

1. 本番ソースを開発環境へコピー
2. VS Code で編集
3. SAVEMBR で IBM i に保存
4. Git commit / push
5. 検証環境へコンパイル
6. 検証環境でテスト
7. 本番 source member deploy
8. 本番 object deploy
```

### コマンド例

```powershell
cpysrc kjnml qrpgsrc@1 kjnmld

cpymbr kjnml qrpgsrc@1 hello kjnmld

codembr kjnmld qrpgsrc@1 hello

savembr kjnmld qrpgsrc@1 hello

git add .
git commit -m "Update HELLO"
git push

crtrpg kjnmlt kjnmld qrpgsrc@1 hello

callpgm kjnmlt hello

deploymbr kjnmld qrpgsrc@1 hello kjnml

deployobj hello *pgm kjnmlt kjnml
```

本番環境（KJNML）ではコンパイルを行わない。

## 本番運用ポリシー

```text
本番環境（KJNML）ではコンパイルを行わない。

KJNMLT で コンパイル・検証済み object を
DEPLOYOBJ により本番環境へ deploy する。
```

## Git運用ポリシー

```text
- workspace を Git 管理する
- IBM i source だけを正式 source にしない
- Git を変更履歴管理として利用する
```

---

## コマンド一覧

### MCPサーバー起動
```powershell
node server.js
```

### ライブラリ/オブジェクト操作
```powershell
OPENLIB

OPENOBJ <library>

OPENMBR <library> <file>

CODEMBR <library> <file> <member>

SAVEMBR <library> <file> <member>

CPYSRC <fromlib> <srcfile> <tolib>

CPYMBR <fromlib> <srcfile> <member> <tolib>

CRTRPG <targetlib> <srclib> <srcfile> <member>

CRTSQLRPG <targetlib> <srclib> <srcfile> <member>

CRTPF <targetlib> <srclib> <srcfile> <member>

CRTDSPF <targetlib> <srclib> <srcfile> <member>

CALLPGM <library> <program>

DEPLOYMBR <fromlib> <srcfile> <member> <tolib>

DEPLOYOBJ <object> <type> <fromlib> <tolib>
```

### 使用例
```powershell
cpysrc kjnml qrpgsrc@1 kjnmld

cpymbr kjnml qrpgsrc@1 hello kjnmld

codembr kjnmld qrpgsrc@1 hello

savembr kjnmld qrpgsrc@1 hello

crtrpg kjnmlt kjnmld qrpgsrc@1 hello

callpgm kjnmlt hello

deploymbr kjnmld qrpgsrc@1 hello kjnml

deployobj hello *pgm kjnmlt kjnml
```

VS Code Task Integration
目的

VS Code 上から IBM i MCP command を実行し、
Project BOB や AI coding assistant から利用可能な
IBM i AI development workflow を構築する。

VS Code Task（tasks.json）を利用することで、
IBM i の操作を VS Code workflow に統合し、
AI支援によるコーディング・修正・コンパイル運用を行う。

OPENLIB / OPENOBJ / OPENMBR / SAVEMBR / CRTRPG などの
MCP command は VS Code の Run Task から選択し、
コマンドライン経由で実行可能とした。

これにより、VS Code Task workflow を IBM BOB に適用することで、
BOB は workspace 上の IBM i source を利用した
AI coding support を行えるようになった。

IBM i の source member は MCP Server を経由して
workspace 上へ展開され、
BOB はその source を通常の VS Code file として参照・編集できる。

また、OPENMBR / SAVEMBR / CRTRPG などの command を
VS Code Task 経由で実行することで、
IBM i source の取得・保存・コンパイル workflow を
VS Code 上へ統合した。


### 構成
```text
VS Code
 ↓
tasks.json
 ↓
MCP Server
 ↓
IBM i
```

### 現段階での制限事項

> [!IMPORTANT]
> 現段階では IBM BOB / AI coding assistant は
> workspace source を対象とした coding support 用途で利用する。

MCP Server を通じて IBM i source の取得・編集・保存・コンパイルは可能であるが、
AI が IBM i システム全体を自律的に解析・操作するものではない。

現在は以下を中心とした運用を想定する。

- RPGソース編集
- FREE化
- SQL化
- コード説明
- リファクタリング
- AI支援コーディング

現段階では以下は未実装、または限定的である。

- システム全体の見える化
- 自動影響範囲分析
- AIによる自律コンパイル
- AIによる自律修正
- 完全なAIエージェント運用
- Project BOB からの直接 MCP tool call

これらは将来的な構想として段階的に実装を目指す。


## 将来構想

このMCPサーバーは、Claude や IBM watsonx Code Assistant（Bob）などのAIツールから、
安全に IBM i 資産へアクセスすることを目的としている。

### 想定アーキテクチャ

```text
Claude / Bob
    ↓
MCP Client
    ↓
本MCP Server
    ↓
IBM i
```
MCP Client は Claude Desktop や VS Code AI extension 側に存在し、
AI から MCP Server のツールを呼び出す役割を持つ。

### 今後実装予定の機能

- IBM i コマンド実行
- ソースメンバー参照
- メンバーのIFS変換
- VS Code + AI による編集
- IBM i メンバーへの保存
- Git連携
- コンパイル支援

### 実装予定コマンド

### Source Operations

- OPENLIB
- OPENOBJ
- OPENMBR
- SAVEMBR

### Compile Operations

- CRTRPG
- CRTSQLRPG

### Analysis Operations

- DSPFD
- DSPPGMREF
- DSPOBJD
- RTVMBRD
- RUNSQL

## Current Status

現在以下を実装済み：

- MCP Server 起動
- OPENLIB
- OPENOBJ
- OPENMBR
- SAVEMBR
- CPYSRC
- CPYMBR
- CRTRPG
- VS Code Task integration
- AI coding workflow

### AI編集フロー

IBM i の source member は従来の member file structure で管理されており、
VS Code や AI editor から直接扱いにくい。

そのため一度 IFS stream file へ変換し、
UTF-8 ベースの modern editor workflow へ接続する。

```text
IBM i ソースメンバー
    ↓
OPENMBR
    ↓
IFS Stream File化
    ↓
VS Code + Claude/Bob
    ↓
Git Commit
    ↓
SAVEMBR
    ↓
IBM i コンパイル
```

## AI利用時の原則

AI が生成したコードは必ず人間がレビューする。
本番 deploy 前には KJNMLT で compile / test を行う。

### 安全設計

実行可能コマンドはホワイトリスト方式で制御する。

以下のような危険コマンドは実行不可とする。

- DLTLIB
- CLRPFM
- CHGUSRPRF

### 今後の課題

- CCSID変換
- UTF-8対応
- 固定形式RPG対応
- メンバー同期
- コンパイルエラー解析

## ゴール

本プロジェクトは、
IBM i の既存資産を維持しながら、
AI支援開発とモダン開発フローを接続することを目的とする。