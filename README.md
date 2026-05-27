# IBM i MCP Server

VS CodeからMCPサーバー経由でIBM iのソースメンバーを取得・編集・保存し、モダンな開発環境で管理するシステム。

## 目的

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

## インストール

```bash
npm install
```

## MCPサーバー起動

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

1. MCPサーバー起動
2. IBM i からソースメンバーを取得 → workspace に保存
3. VS Code で編集
4. 修正内容を IBM i に保存
5. コンパイル
6. プログラム実行・検証


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
7. 本番 source deploy
8. 本番 object deploy
```

### コマンド例
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

本番環境（KJNML）では compile を行わない。

## 本番運用ポリシー

```text
本番環境（KJNML）では compile を行わない。

KJNMLT で compile・検証済み object を
DEPLOYOBJ により本番環境へ deploy する。
```

## 将来の統合予定

- IBM watsonx Code Assistant for i
- IBM Bob
- 自動ビルドパイプライン
- AI支援RPG近代化

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