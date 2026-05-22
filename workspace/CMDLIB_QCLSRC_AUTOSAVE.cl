/*-------------------------------------------------------------------*/         
/*   18.11.22      自動バックアップ処理（シェアリング用）          */         
/*                                        T.KAZUSA                   */         
/*   21.11.04       V7R4区画用バックアップ処理                     */         
/*                                        N.TANIGUCHI                */         
/*   25.05.23       NEXTB2B サブシステム停止・起動処理追加         */         
/*                                        N.TANIGUCHI                */         
/*   25.07.31       KANVAS  サブシステム停止・起動処理追加         */         
/*                                        T.KAZUSA                   */         
/*----< MAINTENANCE & UPDATE >---------------------------------------*/         
/*  DATE    | NAME |変更内容                                       */         
/*----------+------+-------------------------------------------------*/         
/* 19.01.09 | T.K  |･ｲﾒｰｼﾞｶﾀﾛｸﾞ溢れ防止対応SAVLIB,SAVのVOLを   */         
/*          |      | *MOUNTED⇒固定VOL(&TVLN)に変更              */         
/*          |      |･応答リスト追加       　　　                 */         
/*          |      | ADDRPYLE SEQNBR(1000) MSGID(CPA6798) RPY('C')   */         
/*-------------------------------------------------------------------*/         
                                                                                
                                                                                
                                                                                
                                                                                
/* ----------------------------------------------------------------- */         
             PGM                                                                
             DCLF       FILE(SAVEF)                                             
                                                                                
             DCL        VAR(&ERRCNT) TYPE(*DEC) LEN(5 0)                        
             DCL        VAR(&TAPE)   TYPE(*CHAR) LEN(10) VALUE('TAPMLB01')      
             DCL        VAR(&TAPEN)  TYPE(*CHAR) LEN(30) +                      
                                         VALUE('/QSYS.LIB/TAPMLB01.DEVD')       
                                                                                
             DCL        VAR(&MSG)    TYPE(*CHAR) LEN(132)                       
             DCL        VAR(&MSGID)  TYPE(*CHAR) LEN(7)   VALUE('OK     ')      
             DCL        VAR(&LNAME)  TYPE(*CHAR) LEN(100)                       
             DCL        VAR(&DATE)   TYPE(*CHAR) LEN(6)                         
             DCL        VAR(&TIME)   TYPE(*CHAR) LEN(6)                         
             DCL        VAR(&DATE_D) TYPE(*DEC) LEN(8 0)                        
             DCL        VAR(&DATE_E) TYPE(*CHAR) LEN(6)                         
             DCL        VAR(&TIME_E) TYPE(*CHAR) LEN(6)                         
             DCL        VAR(&DATE_E2) TYPE(*CHAR) LEN(6)                        
             DCL        VAR(&TIME_E2) TYPE(*CHAR) LEN(6)                        
             DCL        VAR(&DATE_R) TYPE(*CHAR) LEN(6)                         
             DCL        VAR(&TIME_R) TYPE(*CHAR) LEN(6)                         
                                                                                
             DCL        VAR(&LIB)    TYPE(*CHAR) LEN(10)  VALUE('CMDLIB')       
                                                                                
             DCL        VAR(&SRLNBR) TYPE(*CHAR) LEN(8)                         
             DCL        VAR(&RSLT)   TYPE(*CHAR) LEN(1)   VALUE(' ')            
             DCL        VAR(&SYS_ID) TYPE(*CHAR) LEN(2)   VALUE('D6')           
             DCL        VAR(&LABEL)  TYPE(*CHAR) LEN(17)                        
             DCL        VAR(&RTCD )  TYPE(*CHAR) LEN(2)                         
                                                                                
/*初期化*/                                                                    
             DCL        VAR(&#ERMSG) TYPE(*CHAR) LEN(30)                        
             DCL        VAR(&#MSG)   TYPE(*CHAR) LEN(132)                       
             DCL        VAR(&#MSGID) TYPE(*CHAR) LEN(7)                         
                                                                                
/*テープ情報*/                                                                
             DCL        VAR(&TVLN) TYPE(*CHAR) LEN(10)                          
             DCL        VAR(&VDATE)  TYPE(*DEC)  LEN(8 0)                       
             DCL        VAR(&YYMD)   TYPE(*DEC)  LEN(8 0)                       
                                                                                
/*処理順序番号取得*/                                                          
             DCL        VAR(&SEQNBR) TYPE(*CHAR) LEN(10)    /*順序番号  */    
             DCL        VAR(&MSG2)   TYPE(*CHAR) LEN(132)   /* ﾒｯｾｰｼﾞ     */    
             DCL        VAR(&MSGID2) TYPE(*CHAR) LEN(7)     /* ﾒｯｾｰｼﾞID   */    
             DCL        VAR(&MSGDTA2) TYPE(*CHAR) LEN(3000) /* ﾒｯｾｰｼﾞDATA */    
                                                                                
 /*日付計算パラメーター */                                                    
             DCL        VAR(&S_MON) TYPE(*DEC) LEN(3 0) VALUE(1)                
             DCL        VAR(&S_YMD) TYPE(*CHAR) LEN(1) VALUE('M')               
             DCL        VAR(&R_DATE) TYPE(*DEC) LEN(8 0)                        
             DCL        VAR(&R_FLG) TYPE(*CHAR) LEN(1)                          
                                                                                
             MONMSG     MSGID(CPF0000)                                          
                                                                                
             CHGJOB     LOG(4 00 *SECLVL) LOGCLPGM(*YES) +                      
                          INQMSGRPY(*SYSRPYL)                                   
                                                                                
/*開始メッセージ*/                                                            
             SNDUSRMSG  MSGID(CPF9897) MSGF(QCPFMSG) MSGDTA('＊　+            
                          バックアップ処理が開始しました　　＊') +            
                          MSGTYPE(*INFO) TOMSGQ(*SYSOPR)                        
                                                                                
/*データエリア初期設定*/                                                      
             RTVNETA    SYSNAME(&SRLNBR)                                        
             RTVSYSVAL  SYSVAL(QDATE) RTNVAR(&DATE)                             
             RTVSYSVAL  SYSVAL(QTIME) RTNVAR(&TIME)                             
             CHGVAR     VAR(&DATE_D) VALUE(&DATE)                               
             CHGVAR     VAR(&YYMD) VALUE(&DATE_D + 20000000)                    
                                                                                
/*NEXTB2B サブシステム停止*/                                                
             ENDSBS     SBS(NB2BSBS) OPTION(*IMMED)                             
             MONMSG     MSGID(CPF0000)                                          
             DLYJOB     DLY(120)                                                
                                                                                
/*KANVAS  サブシステム停止*/                                                
             ENDSBS     SBS(KANVAS ) OPTION(*IMMED)                             
             MONMSG     MSGID(CPF0000)                                          
             DLYJOB     DLY(60)                                                 
                                                                                
/*テープ装置の準備*/                                                          
             VRYCFG     CFGOBJ(&TAPE) CFGTYPE(*DEV) STATUS(*ON)                 
             MONMSG     MSGID(CPF2600) EXEC(DO)                                 
               RCVMSG     MSGQ(*PGMQ) MSGTYPE(*LAST) RMV(*NO) +                 
                          MSG(&MSG) MSGID(&MSGID)                               
               SNDUSRMSG  MSGID(CPF9897) MSGF(QCPFMSG) +                        
                          MSGDTA('******' *CAT &MSGID *CAT +                    
                          &MSG) MSGTYPE(*INFO) TOMSGQ(*SYSOPR)                  
               CHGVAR     VAR(&ERRCNT) VALUE(&ERRCNT + 1)                       
               CHGVAR     VAR(&TVLN) VALUE('          ')                        
               GOTO       CMDLBL(#END)                                          
             ENDDO                                                              
                                                                                
/*テープチェック */                                                           
             RTVDTAARA  DTAARA(&LIB/VOL (1 6)) RTNVAR(&TVLN)                    
                                                                                
             SELECT                                                             
               WHEN       COND(&TVLN *EQ 'TEST11') THEN(DO)                     
                 CHGVAR     VAR(&TVLN) VALUE('TEST12')                          
                 CHGDTAARA  DTAARA(&LIB/VOL (1 6)) VALUE('TEST12')              
                 GOTO       CMDLBL(#CHKTAP)                                     
               ENDDO                                                            
                                                                                
               WHEN       COND(&TVLN *EQ 'TEST12') THEN(DO)                     
                 CHGVAR     VAR(&TVLN) VALUE('TEST11')                          
                 CHGDTAARA  DTAARA(&LIB/VOL (1 6)) VALUE('TEST11')              
                 GOTO       CMDLBL(#CHKTAP)                                     
               ENDDO                                                            
                                                                                
               OTHERWISE  CMD(DO)                                               
                 CHGVAR     VAR(&TVLN) VALUE('TEST11')                          
                 CHGDTAARA  DTAARA(&LIB/VOL (1 6)) VALUE('TEST12')              
                 GOTO       CMDLBL(#CHKTAP)                                     
               ENDDO                                                            
             ENDSELECT                                                          
                                                                                
 #CHKTAP:    CHKTAP     DEV(&TAPE) VOL(&TVLN) ENDOPT(*REWIND)                   
             MONMSG     MSGID(CPF0000) EXEC(DO)                                 
               RCVMSG     MSGQ(*PGMQ) MSGTYPE(*LAST) RMV(*NO) +                 
                          MSG(&MSG) MSGID(&MSGID)                               
               SNDUSRMSG  MSGID(CPF9897) MSGF(QCPFMSG) +                        
                          MSGDTA('******' *CAT &MSGID *CAT +                    
                          &MSG) MSGTYPE(*INFO) TOMSGQ(*SYSOPR)                  
               CHGVAR     VAR(&ERRCNT) VALUE(&ERRCNT + 1)                       
               GOTO       CMDLBL(#END)                                          
             ENDDO                                                              
                                                                                
/* テープ初期化判定*/                                                         
             RTVDTAARA  DTAARA(&LIB/&TVLN *ALL) RTNVAR(&VDATE)                  
             IF         COND(&YYMD *GE &VDATE) THEN(DO)                         
/*テープ初期化処理 */                                                         
             INZTAP     DEV(&TAPE) NEWVOL(&TVLN) VOL(&TVLN) +                   
                          CHECK(*NO) DENSITY(*CTGTYPE)                          
               MONMSG     MSGID(CPF0000) EXEC(DO)                               
                 RCVMSG     MSGQ(*PGMQ) MSGTYPE(*LAST) RMV(*NO) +               
                            MSG(&MSG) MSGID(&MSGID)                             
             SNDUSRMSG  MSGID(CPF9897) MSGF(QCPFMSG) MSGDTA('******' +          
                          *CAT &MSGID *CAT &MSG) MSGTYPE(*INFO) +               
                          TOMSGQ(*SYSOPR)                                       
                 CHGVAR     VAR(&ERRCNT) VALUE(&ERRCNT + 1)                     
                 GOTO       CMDLBL(#END)                                        
               ENDDO                                                            
                                                                                
/*前回のテープ初期化日付の翌月を算出し登録*/                                  
               CALL       PGM(XXX150R) PARM(&VDATE &S_MON 'A' +                 
                          &S_YMD &R_DATE &R_FLG)                                
                                                                                
/*日付算出エラー判定 */                                                       
               IF         COND(&R_FLG *NE ' ') THEN(DO)                         
                 SNDUSRMSG  MSGID(CPF9897) MSGF(QCPFMSG) +                      
                            MSGDTA('*テープ初期化日付更新エラー*') +          
                            MSGTYPE(*INFO) TOMSGQ(*SYSOPR)                      
               ENDDO                                                            
               CHGVAR     VAR(&VDATE) VALUE(&R_DATE)                            
               CHGDTAARA  DTAARA(&LIB/&TVLN *ALL) VALUE(&VDATE)                 
             ENDDO                                                              
                                                                                
             DLYJOB     DLY(5)                                                  
                                                                                
/****************************/                                                  
/*   バックアップ処理     */                                                  
/****************************/                                                  
#LOOP:                                                                          
/*処理結果更新*/                                                              
             CALL       PGM(SAV020R) PARM('E' &SRLNBR &DATE &TIME +             
                                          &DATE_R &TIME_R +                     
                                                      &RSLT &LIBKBN &LIBNAM +   
                                                      &TVLN &SEQNBR)            
             MONMSG     MSGID(CPF0000)                                          
#START:                                                                         
             RCVF       RCDFMT(SAVER)                                           
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(#END))                  
                                                                                
/*保管対象判断　保管対象Ｆ＝’’は対象外*/                                    
             IF         COND(&LIBHKN *EQ ' ') THEN(GOTO CMDLBL(#START))         
                                                                                
/*処理対象登録*/                                                              
             CHGVAR     VAR(&RSLT) VALUE(' ')                                   
             CALL       PGM(SAV020R) PARM('S' &SRLNBR &DATE &TIME +             
                                          &DATE_R &TIME_R +                     
                                                      &RSLT &LIBKBN &LIBNAM +   
                                                      &TVLN ' ')                
             MONMSG     MSGID(CPF0000)                                          
/*ライブラリかＩＦＳ上か判断*/                                                
             IF         COND(&LIBKBN *EQ 'L') THEN(DO)                          
/*------------------*/                                                          
/*ライブラリで保管*/                                                          
/*------------------*/                                                          
  /*ライブラリ存在チェック*/                                                  
               CHKOBJ     OBJ(QSYS/&LIBNAM) OBJTYPE(*LIB)                       
               MONMSG     MSGID(CPF0000) EXEC(DO)                               
                  RCVMSG     MSGQ(*PGMQ) MSGTYPE(*LAST) RMV(*NO) +              
                               MSG(&MSG) MSGID(&MSGID)                          
                  CHGVAR     VAR(&LNAME) VALUE(&LIBNAM)                         
                  SNDUSRMSG  MSGID(CPF9897) MSGF(QCPFMSG) MSGDTA('****** +      
                            ' *CAT &MSGID *BCAT &MSG) MSGTYPE(*INFO) +          
                            TOMSGQ(*SYSOPR)                                     
                  CHGVAR     VAR(&ERRCNT) VALUE(&ERRCNT + 1)                    
                  CHGVAR     VAR(&RSLT) VALUE('1')                              
                  CHGVAR     VAR(&SEQNBR) VALUE(' ')                            
                  GOTO       CMDLBL(#LOOP)                                      
               ENDDO                                                            
                                                                                
     /*ライブラリ保管*/                                                       
               CHGVAR     VAR(&LABEL) VALUE(&SYS_ID *CAT '_' *CAT &LIBNAM)      
             SAVLIB     LIB(&LIBNAM) DEV(&TAPE) VOL(&TVLN) +                    
                          SEQNBR(*END) LABEL(&LABEL) ENDOPT(*LEAVE) +           
                          UPDHST(*NO) CLEAR(*ALL) SAVACT(*SYNCLIB)              
               MONMSG     MSGID(CPF0000) EXEC(DO)                               
                  RCVMSG     MSGQ(*PGMQ) MSGTYPE(*LAST) RMV(*NO) +              
                               MSG(&MSG) MSGID(&MSGID)                          
                  CHGVAR     VAR(&LNAME) VALUE(&LIBNAM)                         
                  SNDUSRMSG  MSGID(CPF9897) MSGF(QCPFMSG) MSGDTA('****** +      
                            ' *CAT &MSGID *BCAT &MSG) MSGTYPE(*INFO) +          
                            TOMSGQ(*SYSOPR)                                     
                  CHGVAR     VAR(&ERRCNT) VALUE(&ERRCNT + 1)                    
                  CHGVAR     VAR(&RSLT) VALUE('2')                              
                  CHGVAR     VAR(&SEQNBR) VALUE(' ')                            
                  GOTO       CMDLBL(#LOOP)                                      
               ENDDO                                                            
             ENDDO                                                              
             ELSE       CMD(DO)                                                 
/*----------------------*/                                                      
/*ＩＦＳフォルダで保管*/                                                      
/*----------------------*/                                                      
                                                                                
     /*フォルダ保管*/                                                         
             SAV        DEV(&TAPEN) OBJ((&LIBNAM)) SAVACT(*SYNC) +              
                          VOL(&TVLN) SEQNBR(*END) ENDOPT(*LEAVE) +              
                          CLEAR(*ALL)                                           
               MONMSG     MSGID(CPF0000) EXEC(DO)                               
                  RCVMSG     MSGQ(*PGMQ) MSGTYPE(*LAST) RMV(*NO) +              
                               MSG(&MSG) MSGID(&MSGID)                          
                  CHGVAR     VAR(&LNAME) VALUE(&LIBNAM)                         
                  SNDUSRMSG  MSGID(CPF9897) MSGF(QCPFMSG) MSGDTA('****** +      
                            ' *CAT &MSGID *BCAT &MSG) MSGTYPE(*INFO) +          
                            TOMSGQ(*SYSOPR)                                     
                  CHGVAR     VAR(&ERRCNT) VALUE(&ERRCNT + 1)                    
                  CHGVAR     VAR(&RSLT) VALUE('2')                              
                  CHGVAR     VAR(&SEQNBR) VALUE(' ')                            
                  GOTO       CMDLBL(#LOOP)                                      
               ENDDO                                                            
             ENDDO                                                              
                                                                                
 /*●保管時順序番号の取得*/                                                   
             RCVMSG     MSGQ(*PGMQ) MSGTYPE(*LAST) RMV(*NO) +                   
                          MSG(&MSG2) MSGDTA(&MSGDTA2) MSGID(&MSGID2)            
             CHGVAR     VAR(&SEQNBR) VALUE(' ')                                 
             IF         COND(&MSGID2 = 'CPC3701') THEN(DO)                      
               CHGVAR     VAR(&SEQNBR) VALUE(%SST(&MSGDTA2  705 10))            
             ENDDO                                                              
             IF         COND(&MSGID2 = 'CPC370C') THEN(DO)                      
               CHGVAR     VAR(&SEQNBR) VALUE(%SST(&MSGDTA2 2560 10))            
             ENDDO                                                              
                                                                                
             GOTO #LOOP                                                         
                                                                                
#END:                                                                           
             RTVSYSVAL  SYSVAL(QDATE) RTNVAR(&DATE_E)                           
             RTVSYSVAL  SYSVAL(QTIME) RTNVAR(&TIME_E)                           
                                                                                
                                                                                
             CALL       PGM(SAV010R) PARM(&SRLNBR &MSGID &DATE &TIME +          
                                               &DATE_E &TIME_E &ERRCNT &TVLN)   
                                                                                
/*テープアンロード*/                                                          
             CHKTAP     DEV(&TAPE) VOL(&TVLN) ENDOPT(*UNLOAD)                   
             MONMSG     MSGID(CPF0000)                                          
                                                                                
/*テープ装置をオフにする */                                                   
             VRYCFG     CFGOBJ(&TAPE) CFGTYPE(*DEV) STATUS(*OFF)                
             MONMSG     MSGID(CPF2600) EXEC(DO)                                 
               RCVMSG     MSGQ(*PGMQ) MSGTYPE(*LAST) RMV(*NO) +                 
                            MSG(&MSG) MSGID(&MSGID)                             
             SNDUSRMSG  MSGID(CPF9897) MSGF(QCPFMSG) +                          
                          MSGDTA('******' *CAT &MSGID *CAT +                    
                          &MSG) MSGTYPE(*INFO) TOMSGQ(*SYSOPR)                  
               CHGVAR     VAR(&ERRCNT) VALUE(&ERRCNT + 1)                       
             ENDDO                                                              
                                                                                
        /*�ＩＳＫサイズ*/                                                    
             OVRPRTF    FILE(QPDSPSTS) OUTQ(&LIB/AUTOSAVE)                      
             DSPSYSSTS  OUTPUT(*PRINT)                                          
             DLTOVR     FILE(QPDSPSTS)                                          
                                                                                
/*NEXTB2B サブシステム起動*/                                                
             STRSBS     SBSD(NB2BLIB/NB2BSBS)                                   
             MONMSG     MSGID(CPF0000)                                          
                                                                                
/*KANVAS  サブシステム起動*/                                                
             STRSBS     SBSD(KANVAS/KANVAS)                                     
             MONMSG     MSGID(CPF0000)                                          
                                                                                
/****************************/                                                  
/*  全体終了メッセージ    */                                                  
/****************************/                                                  
        /*正常終了メッセージ*/                                                
             IF         COND(&MSGID *EQ 'OK     ') THEN(DO)                     
               SNDUSRMSG  MSGID(CPF9897) MSGF(QCPFMSG) MSGDTA('＊　+          
                            正常にバックアップが終了しました　＊') +          
                            MSGTYPE(*INFO) TOMSGQ(*SYSOPR)                      
             ENDDO                                                              
             ELSE       CMD(DO)                                                 
        /*異常終了メッセージ*/                                                
               SNDUSRMSG  MSGID(CPF9897) MSGF(QCPFMSG) +                        
                            MSGDTA('＊＊＊＊　+                               
                            バックアップ処理でエラーが発生しています　+       
                            ＊＊＊＊') MSGTYPE(*INFO) TOMSGQ(*SYSOPR)         
      /******  MAI/SRCTOMAIL TO(SHERE_S7@KSCNET.CO.JP) SUBJECT('Ｓ７　+ *****/
      /******               バックアップ【★異常終了★】') +            *****/
      /******               FILE(CMDLIB/QMALSRC) FROMCCSID(5026) +        *****/
      /******               FROM(KAZUSA@KSCNET.CO.JP) +                   *****/
      /******               SERVER(SMTP.KSCNET.CO.JP)                     *****/
             ENDDO                                                              
/****************************/                                                  
/*        終了処理        */                                                  
/****************************/                                                  
/*ソート順再編成*/                                                            
             RGZPFM     FILE(SAVEF) KEYFILE(*FILE)                              
                                                                                
             RETURN                                                             
/*====================================================================*/        
/*                   【サブルーチン】                               */        
/*====================================================================*/        
/*========================================================*/                    
/*                エラーメッセージ送信                  */                    
/*========================================================*/                    
             SUBR       SUBR(#ERROR    )                                        
                                                                                
             RCVMSG     MSGQ(*PGMQ) MSGTYPE(*LAST) RMV(*NO) +                   
                          MSG(&#MSG) MSGID(&#MSGID)                             
                                                                                
             SNDUSRMSG  MSGID(CPF9897) MSGF(QCPFMSG) +                          
                          MSGDTA('(END処理)** ' *CAT &#ERMSG +                
                          *TCAT &TAPE *BCAT '** ' *CAT &#MSGID +                
                          *BCAT &#MSG) MSGTYPE(*INFO) TOMSGQ(*SYSOPR)           
                                                                                
             ENDSUBR                                                            
ENDPGM                                                                          