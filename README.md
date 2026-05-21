# IBM i × VS Code × MCPサーバー開発プロセス仕様書

## 1. 目的
VS CodeからMCPサーバー経由でIBM iに接続し、ソースメンバーの取得・編集・保存・コンパイル・実行検証を行う。


## 補足

本手順は、IBM i の **CSCH@003 ライブラリー**を参照して作成した。

---

## 接続情報について

MCPサーバー（server.js）で使用する以下の接続情報は、ソースコードには直接記載せず、`.env`ファイルに定義し、Git管理対象外（.gitignoreに追加）とすることで、機密情報の漏洩を防ぎ、安全に管理する。

- サーバーID
- ユーザーID
- パスワード
- APIキー

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

## 3. MCPサーバー起動

```powershell
cd C:\Users\K4293\mcp-server
node server.js
```

---

## 4. ライブラリー確認
対象ライブラリー内のオブジェクト一覧を表示する。
```powershell
OPENOBJ CSCH@003
```

---

## 5. メンバー一覧
ソースファイル内のメンバー一覧を表示する。
```powershell
OPENMEN2 CSCH@003 QRPGSRC@1
```
---

## 6. メンバーを開く
指定メンバーをVS Codeで編集可能な状態にする。
```powershell
OPENMBR CSCH@003 QRPGSRC@1 TESTEMP rpg
```

---

## 7. 修正
VS Codeで修正

---
## 8. 保存

```powershell
SAVEFILE CSCH@003 QRPGSRC@1 TESTEMP rpg
```

---
## 9. コンパイル
通常RPGの場合

```powershell
CRTRPG CSCH@003 TESTEMP
```

SQLRPGの場合
```powershell
CRTSQLRPG CSCH@003 TESTEMP
```

---
## 10. 実行

```powershell
CALLPGM CSCH@003 TESTEMP
```

```text
CALL PGM(CSCH@003/TESTEMP)
```
---

## 11. 結果確認
DSPLY
5250で確認

SQLRPGの場合
```sql
SELECT MSAASYCD, MSAASYNM
FROM CSCH@003.MSSYAAF;
```
---
## 12. 作業フロー

```text
① server.js起動
② OPENOBJ
③ OPENMEN2
④ OPENMBR
⑤ 修正
⑥ SAVEFILE
⑦ コンパイル
⑧ 実行
⑨ 確認
```

---
## 13. コマンド一覧
```powershell
node server.js
```

```powershell
OPENOBJ CSCH@003
OPENMEN2 CSCH@003 QRPGSRC@1
OPENMBR CSCH@003 QRPGSRC@1 TESTEMP rpg

SAVEFILE CSCH@003 QRPGSRC@1 TESTEMP rpg

CRTRPG CSCH@003 TESTEMP
CRTSQLRPG CSCH@003 TESTEMP

CALLPGM CSCH@003 TESTEMP
```