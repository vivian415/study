# Codex と Bob の学習方式の違い（検証結果）

## 概要

IBM i MCP Serverプロジェクトにおいて、

* Codex
* IBM Project Bob

へ同一の開発ルールを学習させた結果、学習方法に大きな違いがあることが分かった。

---

## Codex

### 特徴

READMEを強く参照する。

READMEに記載された内容から、

* 開発ルール
* ライブラリー構成
* コンパイル手順
* コマンド利用方法

を推論して行動する傾向がある。

### 学習方法

```text
README
 ↓
理解
 ↓
推論
 ↓
実行
```

### 今回の結果

READMEのみでも

* KJNML = 本番
* KJNMLD = 開発
* KJNMLT = テスト

を理解し、

* CODEMBR
* SAVEMBR
* CRTRPG
* CRTSQLRPG

などを比較的自然に利用した。

### 長所

* READMEだけでも効果が高い
* 推論能力が高い
* ドキュメント中心で学習できる

### 短所

* 明示していない手順を独自解釈する場合がある

---

## Bob

### 特徴

READMEは読むが、

実際の行動は Rules と Workflow を優先する。

READMEだけでは行動が安定しない。

### 学習方法

```text
README
 ↓
Rules
 ↓
Workflow
 ↓
実行
```

### 今回の結果

READMEのみの段階では

* 独自PowerShellスクリプト作成
* 一般的な開発者視点での推測

が発生した。

その後、

.bob/rules-code

を追加し、

* IBM i Rules
* 標準運用手順

を定義した結果、

以下の手順を理解するようになった。

```text
MCP確認
 ↓
CPYMBR
 ↓
CODEMBR
 ↓
SAVEMBR
 ↓
CRTSQLRPG
 ↓
CALLPGM
 ↓
DEPLOY
```

### 長所

* 手順化された運用を忠実に守る
* プロジェクト専用エージェント化しやすい
* 標準運用を強制しやすい

### 短所

* READMEだけでは不十分
* RulesとWorkflow整備が必要
* 推論よりルールを優先する

---

## 比較

### Codex

```text
ドキュメント駆動
```

README中心

---

### Bob

```text
ルール駆動
```

Rules・Workflow中心

---

## 本プロジェクトでの結論

IBM i MCP Serverプロジェクトでは、

### Codex

READMEを中心に育成する。

### Bob

READMEに加え、

```text
.bob/rules-code
```

配下に

* 開発ルール
* 標準運用手順
* MCP運用ルール

を定義する。

これにより Bob を IBM i 専用AIエージェントとして育成できることを確認した。
