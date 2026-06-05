# IBM i Development Rules

## Library Roles

KJNML = Production

KJNMLD = Development

KJNMLT = Test

本プロジェクトでは IBM i のソースファイル名に @ を含む名称を使用する。

例

QRPGSRC@1
QDDSSRC@1
QPRTSRC@1

@ を含む名称は有効なオブジェクト名として扱うこと。

存在確認は推測ではなく OPENMBR または OPENOBJ を使用すること。

## Mandatory Rules

1. Never modify KJNML directly.

2. Development must be performed in KJNMLD.

3. Compile and testing must be performed in KJNMLT.

4. Use CODEMBR to open source members.

5. Use SAVEMBR after editing.

6. Select compile command based on source type.

.rpgle    -> CRTRPG

.sqlrpgle -> CRTSQLRPG

.pf        -> CRTPF

.dspf      -> CRTDSPF

7. If source member does not exist in KJNMLD, execute CPYMBR first.

8. Verify compile success before deployment.

9. Deploy source using DEPLOYMBR.

10. Deploy objects using DEPLOYOBJ.