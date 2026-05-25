# IBM i × VS Code × MCPサーバー開発プロセス仕様書

## 1. 目的
VS CodeからMCPサーバー経由でIBM iに接続し、ソースメンバーの取得・編集・保存・コンパイル・実行検証を行う。このアーキテクチャは、既存のソースPF（メンバー）資産を破棄することなく、IBM i（AS/400）の開発をモダナイズ（近代化）します。

### Source Management Architecture
```text
IBM i source PF(member)
↓
ODBC
↓
MCP Server
↓
workspace(stream file)
↓
VS Code / GitHub / AI

MCP server converts IBM i source PF(member)
into stream files managed inside workspace/.

This architecture removes dependency on CPYTOSTMF
and minimizes direct IFS operations.
```
---

## 接続情報について
```text
MCPサーバー（server.js）で使用する以下の接続情報は、ソースコードには直接記載せず、`.env`ファイルに定義し、Git管理対象外（.gitignoreに追加）とすることで、機密情報の漏洩を防ぎ、安全に管理する。

- サーバーID
- ユーザーID
- パスワード
- APIキー
```
---

## 2. システム構成
VS CodeからMCPサーバー経由でIBM iに接続し、開発・実行を行う。
```text
VS Code（PowerShell）
↓
MCPサーバー（server.js）
↓
IBM i
↓
ライブラリー / ファイル / メンバー / プログラム
```
---
## 3. GitHub / 開発ディレクトリ構成

### IBM i Development Directory Structure
```text
KJNML   = Production runtime
KJNMLD  = Development source
KJNMLT  = Test / compile environment
```

### Repository Information
```text
| Item | Value |
|---|---|
| Repository | study |
| GitHub | https://github.com/vivian415/study |
| Purpose | IBM i × VS Code × MCP Server development platform |
```
### MCP-SERVER
```text
IBM i と AI を連携するための開発基盤。

MCP Server は
source PF(member) と stream file の
変換レイヤーとして機能する。

DB record型 source を、
.rpgle / .cl / .dds などの
stream file に変換し、
VS Code / GitHub / AI と連携する。
```

### Directory Structure
```text
- ibmi-tools
  - IBM i utility scripts

workspace
  - IBM i source stream files
  - Git managed source repository
  - AI development workspace

ifs-work
  - legacy CPYTOSTMF / IFS export area
  - transitional use only

- docs
  - architecture and operation documents
```

### workspace structure
```text
今回の検証環境にあわせたライブラリー名、メンバー名で記載しています。
workspace/
 ├── KJNML/
 │    └── QRPGLESRC/
 │         └── TESTEMP.rpgle
 │
 ├── KJNMLD/QRPGLESRC
 │    └── QRPGLESRC/
 │         └── TESTEMP.rpgle
 │
 └── KJNMLT/
```

### Development Policy
```text
Production members are opened from KJNML.

Modified sources are saved into KJNMLD.

Compiled test objects are generated in KJNMLT.
```
---

## 4. MCPサーバー起動

```powershell
cd C:\Users\K4293\mcp-server
node server.js
```

---

## 5. ライブラリー確認
対象ライブラリー内（今回は本番区画KJNML)のオブジェクト一覧を表示する。
```powershell
OPENOBJ KJNML
```

---

## 6. メンバー一覧
ソースファイル内のメンバー一覧を表示する。
```powershell
OPENMEN2 KJNML QRPGLESRC
```
---

## 7. メンバーを開く
指定メンバーをVS Codeで編集可能な状態にする。
```powershell
OPENMBR KJNML QRPGLESRC TESTEMP rpgle
```

---

## 8. 修正
VS Codeで修正

---
## 9. 保存

修正したMemberをKJNMLD(開発区画）に保存する。
```powershell
SAVEFILE KJNMLD QRPGLESRC TESTEMP rpgle
```

---
## 10. コンパイル

修正したMemberをKJNMLT(検証区画）にコンパイルする。
通常RPGの場合
```powershell
CRTRPG KJNMLT TESTEMP
```

SQLRPGの場合
```powershell
CRTSQLRPG KJNMLT TESTEMP
```

---
## 11. 実行

```powershell
CALLPGM KJNMLT TESTEMP
```

```powershell
CALL PGM(KJNMLT/TESTEMP)
```
---

## 12. 結果確認
DSPLY
5250で確認

StextQLRPGの場合
```sql
SELECT MSAASYCD, MSAASYNM
FROM KJNMLT.MSSYAAF;
```
---
## 13. 作業フロー

```text
① server.js起動
② OPENOBJ （本番区画のオブジェクト一覧）
③ OPENMEN2（本番区画のソースメンバー一覧）
④ OPENMBR（本番区画のメンバーをVS Codeで開く）
⑤ VS Code修正
⑥ Git commit / push
⑦ SAVEFILE（修正したメンバーを開発区画に保存）
⑧ compile（検証区画 KJNMLT に object生成）
⑨ test（KJNMLT 上で runtime validation）
⑩ deploy（KJNMLD source を production runtime KJNML へ compile/deploy）
```　

---
## 14. コマンド一覧
```powershell
node server.js
```

```powershell
OPENLIB

OPENOBJ <library>

OPENMBR <library> <file>

CODEMBR <library> <file> <member> <ext>

SAVEMBR <library> <file> <member> <ext>

CRTRPG <targetlib> <srclib> <srcfile> <member>

CRTSQLRPG <targetlib> <srclib> <srcfile> <member>

CRTPF <targetlib> <srclib> <srcfile> <member>

CRTDSPF <targetlib> <srclib> <srcfile> <member>

CALLPGM <library> <program>
```

## Future Architecture

AI
↓
OPENMBR
↓
source analysis
↓
SAVEFILE
↓
compile
↓
test
↓
deploy

Future integration targets:
- IBM watsonx Code Assistant for i
- IBM Bob
- automated build pipeline
- AI-assisted RPG modernization