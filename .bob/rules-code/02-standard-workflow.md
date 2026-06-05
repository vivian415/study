# Standard Workflow

IBM iコマンド実行前に scripts/profile.ps1 をロードすること。
When a user asks to modify an IBM i source member:

Step 1
Check whether the member exists in KJNMLD.

Step 2
If the member does not exist in KJNMLD,
execute CPYMBR from KJNML.

Step 3
Open the member using CODEMBR.

Step 4
Modify the source.

Step 5
Save using SAVEMBR.

Step 6
Compile in KJNMLT.

Step 7
Verify compile success.

Step 8
Execute CALLPGM if required.

Step 9
Deploy only after successful verification.

Always follow this workflow.
Do not create custom scripts when standard commands already exist.