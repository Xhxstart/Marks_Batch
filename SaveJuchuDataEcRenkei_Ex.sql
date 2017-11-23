IF EXISTS(SELECT * FROM sysobjects WHERE name='SaveJuchuDataEcRenkei_Ex')
   DROP PROCEDURE dbo.SaveJuchuDataEcRenkei_Ex
GO

CREATE PROCEDURE SaveJuchuDataEcRenkei_Ex
@KAISHA_CD  NVARCHAR(15),                                            --会社コード
@USER_ID    NVARCHAR(30),                                            --ユーザID
@FILE_PATH  NVARCHAR(200)                                            --ファイルパス
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ERR_MSG_MANDATORY_FIELD			NVARCHAR(20)	= '必須項目未設定'
	DECLARE @ERR_MSG_INCORRECT_DATA				NVARCHAR(20)	= '入力値不正'
	DECLARE @ERR_MSG_INVALID_NUMBER				NVARCHAR(20)	= '数値範囲不正'
	DECLARE @ERR_MSG_INCORRECT_CODE				NVARCHAR(20)	= 'コード不正'
	DECLARE @ERR_MSG_CANNOT_USE_CODE			NVARCHAR(20)	= '指定不可コード'
	DECLARE @ERR_MSG_NOT_EXIST_HINMOKU			NVARCHAR(20)	= '該当品目コード無'
	DECLARE @ERR_MSG_CANNOT_USE_HINMOKU			NVARCHAR(20)	= '出荷停止品目'
	DECLARE @ERR_MSG_CANNOT_USE_YOYAKU			NVARCHAR(20)	= '指定不可予約伝票'
	DECLARE @ERR_MSG_JUCHU_ZAM_KANRI_DATE		NVARCHAR(20)	= '注残なし：日付設定不正'
	DECLARE @ERR_MSG_JUCHU_ZAM_KANRI_SHUKKASAKI	NVARCHAR(20)	= '注残なし：出荷先不正'
	DECLARE @ERR_MSG_SEIKYUKIJUN_DATE			NVARCHAR(20)	= '請求基準日不正'
	DECLARE @ERR_MSG_CANNOT_ZAIKOKNARI			NVARCHAR(30)	= '預け・預り・予約・倉庫移動不正：在庫管理なし品目'
	DECLARE @ERR_MSG_AZUKE_AZUKARI_SOKO			NVARCHAR(20)	= '預かり・預け：倉庫区分不正'
	DECLARE @ERR_MSG_TUJOU_SHUKKO_SOKO			NVARCHAR(20)	= '通常出庫：倉庫区分不正'
	DECLARE @ERR_MSG_SOKO_IDO_SHUKKO_KBN		NVARCHAR(20)	= '倉庫移動：倉庫区分不正'
	DECLARE @ERR_MSG_DTL_COUNT_OVER				NVARCHAR(20)	= '受注伝票の明細件数(999件)オーバー'
	DECLARE @ERR_MSG_DIFFERENT_TUKA				NVARCHAR(20)	= '異なる取引通貨'
	DECLARE @ERR_MSG_YOSHIN_GENDO				NVARCHAR(20)	= '与信限度額オーバー'
	DECLARE @ERR_MSG_SOKO_IDO_SOKO				NVARCHAR(20)	= '移動元・移動先倉庫が同じ'
	DECLARE @ERR_MSG_SOKO_TENPO					NVARCHAR(20)	= '移動元、移動先が両方店舗'

	DECLARE @ALERT_MSG_HOLIDAY					NVARCHAR(20)	= '休日：出荷予定日'
	DECLARE @ALERT_MSG_SEIKYU					NVARCHAR(20)	= '請求締済'

	DECLARE @FLD_JUCHU_KBN_YOYAKU				NVARCHAR(20)	= '【予約伝票】'
	DECLARE @FLD_JUCHU_KBN_SOKO_IDO				NVARCHAR(20)	= '【倉庫移動】'

	DECLARE @FLD_NM_JUCHU_KBN					NVARCHAR(28)	= '(受注区分)'+ NCHAR(13) +'受注区分'
	DECLARE @FLD_NM_JUCHU_DATE					NVARCHAR(28)	= '(受注日)'+ NCHAR(13) +'受注日'
	DECLARE @FLD_NM_SHUKKO_KBN					NVARCHAR(28)	= '(出庫区分)'+ NCHAR(13) +'出庫区分'
	DECLARE @FLD_NM_TOKUISAKI_CD				NVARCHAR(28)	= '(得意先コード)'+ NCHAR(13) +'得意先コード'
	DECLARE @FLD_NM_SHUKKASAKI_CD				NVARCHAR(28)	= '(出荷先コード)'+ NCHAR(13) +'ヘッダ出荷先コード'
	DECLARE @FLD_NM_SEIKYUSAKI_CD				NVARCHAR(28)	= '(請求先コード)'+ NCHAR(13) +'請求先コード'
	DECLARE @FLD_NM_SOKO_CD						NVARCHAR(28)	= '(倉庫コード)'+ NCHAR(13) +'ヘッダ倉庫コード'
	DECLARE @FLD_NM_AZUKE_AZUKARI_IDO_SOKO_CD	NVARCHAR(28)	= '(預け／預かり／移動倉庫コード)'+ NCHAR(13) +'預け預かり移動倉庫コード'
	DECLARE @FLD_NM_HDR_SHUKKA_YOTEI_DATE		NVARCHAR(28)	= '(ヘッダ出荷予定日)'+ NCHAR(13) +'ヘッダ出荷予定日'
	DECLARE @FLD_NM_DTL_SHUKKA_YOTEI_DATE		NVARCHAR(28)	= '(明細出荷予定日)'+ NCHAR(13) +'明細出荷予定日'
	DECLARE @FLD_NM_SHITEI_NOHIN_DATE			NVARCHAR(28)	= '(ヘッダ指定納品日)'+ NCHAR(13) +'ヘッダ指定納品日'
	DECLARE @FLD_NM_SHITEI_NOHIN_JIKOKU			NVARCHAR(28)	= '(指定納品時刻)'+ NCHAR(13) +'指定納品時刻'
	DECLARE @FLD_NM_HAISOU_KBN					NVARCHAR(28)	= '(配送区分)'+ NCHAR(13) +'配送区分'
	DECLARE @FLD_NM_KESSAI_HOHO					NVARCHAR(28)	= '(決済方法)'+ NCHAR(13) +'決済方法'
	DECLARE @FLD_NM_HDR_GEDAIMACHI_FLG			NVARCHAR(28)	= '(下代待ちフラグ)'+ NCHAR(13) +'下代待ちフラグ'
	DECLARE @FLD_NM_SAMPLE_SHUKKA_FLG			NVARCHAR(28)	= '(サンプル出荷フラグ)'+ NCHAR(13) +'サンプル出荷フラグ'
	DECLARE @FLD_NM_HIKIATE_CHOSEI_FUYO_FLG		NVARCHAR(28)	= '(引当調整不用フラグ)'+ NCHAR(13) +'引当調整不用フラグ'
	DECLARE @FLD_NM_SEIKYU_KIJUN_DATE			NVARCHAR(28)	= '(請求基準日)'+ NCHAR(13) +'ヘッダ請求基準日'
	DECLARE @FLD_NM_TOKUISAKI_DENPYO_NO			NVARCHAR(28)	= '(得意先伝票NO)'+ NCHAR(13) +'得意先伝票NO'
	DECLARE @FLD_NM_TOKUISAKI_HACCHU_NO			NVARCHAR(28)	= '(得意先発注NO)'+ NCHAR(13) +'得意先発注NO'
	DECLARE @FLD_NM_BUNRUI_CD					NVARCHAR(28)	= '(分類コード)'+ NCHAR(13) +'分類コード'
	DECLARE @FLD_NM_URIBA_NM					NVARCHAR(28)	= '(売場名)'+ NCHAR(13) +'売場名'
	DECLARE @FLD_NM_TANTOSHA_NM					NVARCHAR(28)	= '(担当者名)'+ NCHAR(13) +'担当者名'
	DECLARE @FLD_NM_NAISEN_NO					NVARCHAR(28)	= '(内線番号)'+ NCHAR(13) +'内線番号'
	DECLARE @FLD_NM_TANTOSHA_CD					NVARCHAR(28)	= '(担当者コード)'+ NCHAR(13) +'担当者コード'
	DECLARE @FLD_NM_TANTO_BUSHO_CD				NVARCHAR(28)	= '(担当部署コード)'+ NCHAR(13) +'担当部署コード'
	DECLARE @FLD_NM_NOHIN_KBN					NVARCHAR(28)	= '(納品区分)'+ NCHAR(13) +'納品区分'
	DECLARE @FLD_NM_RYUTU_KAKOU_KBN				NVARCHAR(28)	= '(流通加工区分)'+ NCHAR(13) +'流通加工区分'
	DECLARE @FLD_NM_BIKO						NVARCHAR(28)	= '(ヘッダ備考)'+ NCHAR(13) +'ヘッダ備考'
	DECLARE @FLD_NM_JUCHU_COMMENT				NVARCHAR(28)	= '(受注コメント)'+ NCHAR(13) +'受注コメント'
	DECLARE @FLD_NM_SOKO_COMMENT				NVARCHAR(28)	= '(倉庫コメント)'+ NCHAR(13) +'倉庫コメント'
	DECLARE @FLD_NM_PROJECT_CD					NVARCHAR(28)	= '(プロジェクトコード)'+ NCHAR(13) +'プロジェクトコード'
	DECLARE @FLD_NM_HANBAI_AREA_CD				NVARCHAR(28)	= '(販売エリアコード)'+ NCHAR(13) +'販売エリアコード'
	DECLARE @FLD_NM_YOYAKU_KAIHO_KIGEN			NVARCHAR(28)	= '(予約解放期限)'+ NCHAR(13) +'予約解放期限'
	DECLARE @FLD_NM_HINMOKU						NVARCHAR(28)	= '(品目)'+ NCHAR(13) +'品目'
	DECLARE @FLD_NM_LOT_NUM						NVARCHAR(28)	= '(ロット数)'+ NCHAR(13) +'ロット数'
	DECLARE @FLD_NM_BARA_NUM					NVARCHAR(28)	= '(バラ数)'+ NCHAR(13) +'バラ数'
	DECLARE @FLD_NM_SUITEI_KAKUTEI_KBN			NVARCHAR(28)	= '(推定確定区分)'+ NCHAR(13) +'推定確定区分'
	DECLARE @FLD_NM_KAKERITU					NVARCHAR(28)	= '(掛率)'+ NCHAR(13) +'掛率'
	DECLARE @FLD_NM_JUCYU_TANKA					NVARCHAR(28)	= '(受注単価)'
	DECLARE @FLD_NM_HIKIATE_STATE				NVARCHAR(28)	= '(引当状態)'+ NCHAR(13) +'引当状態'
	DECLARE @FLD_NM_DTL_GEDAIMACHI_FLG			NVARCHAR(28)	= '(下代待ちフラグ)'+ NCHAR(13) +'明細下代待ちフラグ'
	DECLARE @FLD_NM_TEKIYO						NVARCHAR(28)	= '(摘要)'+ NCHAR(13) +'摘要'
	DECLARE @FLD_NM_YOYAKU_DENPYO_NO			NVARCHAR(28)	= '(予約伝票NO)'+ NCHAR(13) +'予約伝票NO'
	DECLARE @FLD_NM_YOYAKU_DENPYO_ENO			NVARCHAR(28)	= '(予約伝票枝番)'+ NCHAR(13) +'予約伝票枝番'
	DECLARE @FLD_NM_KAZEI_KBN					NVARCHAR(28)	= '(課税区分)'+ NCHAR(13) +'課税区分'
	DECLARE @FLD_NM_TORIHIKISAKI_TUKA_TANKA		NVARCHAR(28)	= '(取引先通貨単価)'+ NCHAR(13) +'取引先通貨単価'
	DECLARE @FLD_NM_RATE						NVARCHAR(28)	= '(レート)'+ NCHAR(13) +'レート'
	DECLARE @FLD_NM_DTL_BIKO					NVARCHAR(28)	= '(明細備考)'+ NCHAR(13) +'明細備考'

	--INT変数リターンコード(@RetCd)を初期値0で定義
	DECLARE @RetCd int = 0

	--単価桁数、数量桁数の定義値を取得
	DECLARE @TANKA_KETA NVARCHAR(10) 
			,@SURYO_KETA NVARCHAR(10)
			,@PGM_CD NVARCHAR(50)

	--単価桁数
	SELECT @TANKA_KETA = VALUE FROM BC_MST_SYSTEM
	WHERE KAISHA_CD = @KAISHA_CD
	AND BUNRUI_NM = 'CO'
	AND VALUE_NM = 'TANKA_KETA'

	--数量桁数
    SELECT @SURYO_KETA = VALUE FROM BC_MST_SYSTEM
    WHERE KAISHA_CD = @KAISHA_CD
    AND BUNRUI_NM = 'CO'
    AND VALUE_NM = 'SURYO_KETA'

	--B2B登録プログラムコード
    SELECT @PGM_CD = VALUE FROM BC_MST_SYSTEM
    WHERE KAISHA_CD = @KAISHA_CD
    AND BUNRUI_NM = 'HK'
    AND VALUE_NM = 'B2B_INS_PGM_CD' 

	--会社マスタの通貨コード取得
	--日本円を通貨コードに設定するとのこと
	DECLARE @TUKA_CD NVARCHAR(15) 
	SELECT @TUKA_CD = TUKA_CD
	FROM BC_MST_KAISHA_GAIKA
	WHERE KAISHA_CD = @KAISHA_CD

	--取込受注データ用一時テーブル
	CREATE TABLE #tmp
    (
		LINE_NO						DECIMAL(6) PRIMARY KEY	--(付加情報)ファイル行番号
	   ,ERROR_MSG					NVARCHAR(100)			--(付加情報)エラー内容
	   ,TMP_ID						DECIMAL(6)				--(付加情報)一時ID
	   ,GROUP_KEY					DECIMAL(6)				--(付加情報)グループキー
	   ,DENPYO_NO					NVARCHAR(12)			--(付加情報)伝票NO
	   ,DENPYO_ENO					DECIMAL(3)				--(付加情報)伝票枝番
	   ,HINMOKU_SEQ					DECIMAL(10)				--(付加情報)品目SEQ
	   ,SURYO						DECIMAL(13, 3)			--(付加情報)受注数量
	   ,JUCHU_TANKA					DECIMAL(14, 4)			--(付加情報)受注単価
	   ,TAX_RATE					DECIMAL(3, 2)			--(付加情報)税率
	   ,TAX_SITEI_KBN				NVARCHAR(5)				--(付加情報)税率指摘区分
	   ,KAKERITU_REF_KBN			NVARCHAR(5)				--(付加情報)掛率参照区分
	   ,HIKIATE_KBN					NVARCHAR(5)				--(付加情報)引当区分(明細の拡張TBL)
	   ,JUCHU_KBN					NVARCHAR(MAX)			--受注区分
	   ,JUCHU_DATE					NVARCHAR(MAX)			--受注日
	   ,SHUKKO_KBN					NVARCHAR(MAX)			--出庫区分
	   ,TOKUISAKI_CD				NVARCHAR(MAX)			--得意先コード
	   ,SHUKKASAKI_CD				NVARCHAR(MAX)			--出荷先コード
	   ,SEIKYUSAKI_CD				NVARCHAR(MAX)			--請求先コード
	   ,SOKO_CD						NVARCHAR(MAX)			--倉庫コード
	   ,AZUKE_AZUKARI_IDO_SOKO_CD	NVARCHAR(MAX)			--預け／預かり／移動倉庫コード
	   ,SHUKKA_YOTEI_DATE			NVARCHAR(MAX)			--出荷予定日
	   ,SHITEI_NOHIN_DATE			NVARCHAR(MAX)			--指定納品日
	   ,SHITEI_NOHIN_JIKOKU			NVARCHAR(MAX)			--指定納品時刻
	   ,HAISOU_KBN					NVARCHAR(MAX)			--配送区分
	   ,KESSAI_HOHO					NVARCHAR(MAX)			--決済方法
	   ,HDR_GEDAIMACHI_FLG			NVARCHAR(MAX)			--下代待ちフラグ
	   ,SAMPLE_SHUKKA_FLG			NVARCHAR(MAX)			--サンプル出荷フラグ
	   ,HIKIATE_CHOSEI_FUYO_FLG		NVARCHAR(MAX)			--引当調整不用フラグ
	   ,HDR_SEIKYU_KIJUN_DATE		NVARCHAR(MAX)			--請求基準日
	   ,TOKUISAKI_DENPYO_NO			NVARCHAR(MAX)			--得意先伝票NO
	   ,TOKUISAKI_HACCHU_NO			NVARCHAR(MAX)			--得意先発注NO
	   ,BUNRUI_CD					NVARCHAR(MAX)			--分類コード
	   ,URIBA_NM					NVARCHAR(MAX)			--売場名
	   ,TANTOSHA_NM					NVARCHAR(MAX)			--担当者名
	   ,NAISEN_NO					NVARCHAR(MAX)			--内線番号
	   ,TANTOSHA_CD					NVARCHAR(MAX)			--担当者コード
	   ,TANTO_BUSHO_CD				NVARCHAR(MAX)			--担当部署コード
	   ,NOHIN_KBN					NVARCHAR(MAX)			--納品区分
	   ,RYUTU_KAKOU_KBN				NVARCHAR(MAX)			--流通加工区分
	   ,BIKO						NVARCHAR(MAX)			--備考
	   ,JUCHU_COMMENT				NVARCHAR(MAX)			--受注コメント
	   ,SOKO_COMMENT				NVARCHAR(MAX)			--倉庫コメント
	   ,PROJECT_CD					NVARCHAR(MAX)			--プロジェクトコード
	   ,HANBAI_AREA_CD				NVARCHAR(MAX)			--販売エリアコード
	   ,YOYAKU_KAIHO_KIGEN			NVARCHAR(MAX)			--予約解放期限
	   ,HINMOKU						NVARCHAR(MAX)			--品目
	   ,LOT_NUM						NVARCHAR(MAX)			--ロット数
	   ,BARA_NUM					NVARCHAR(MAX)			--バラ数
	   ,SUITEI_KAKUTEI_KBN			NVARCHAR(MAX)			--推定確定区分
	   ,KAKERITU					NVARCHAR(MAX)			--掛率(%)
	   ,HIKIATE_STATE				NVARCHAR(MAX)			--引当状態
	   ,DTL_GEDAIMACHI_FLG			NVARCHAR(MAX)			--下代待ちフラグ
	   ,DTL_SOKO_CD					NVARCHAR(MAX)			--倉庫コード
	   ,TEKIYO						NVARCHAR(MAX)			--摘要
	   ,DTL_SHUKKASAKI_CD			NVARCHAR(MAX)			--出荷先コード
	   ,DTL_SHUKKA_YOTEI_DATE		NVARCHAR(MAX)			--出荷予定日
	   ,DTL_SHITEI_NOHIN_DATE		NVARCHAR(MAX)			--指定納品日
	   ,DTL_SEIKYU_KIJUN_DATE		NVARCHAR(MAX)			--請求基準日
	   ,YOYAKU_DENPYO_NO			NVARCHAR(MAX)			--予約伝票NO
	   ,YOYAKU_DENPYO_ENO			NVARCHAR(MAX)			--予約伝票枝番
	   ,KAZEI_KBN					NVARCHAR(MAX)			--課税区分
	   ,TORIHIKISAKI_TUKA_TANKA		NVARCHAR(MAX)			--取引先通貨単価
	   ,RATE						NVARCHAR(MAX)			--レート
	   ,DTL_BIKO					NVARCHAR(MAX)			--備考(明細)
	)

	--ヘッダ情報一時テーブル
	CREATE TABLE #tmpHdr
    (
	    TMP_ID						DECIMAL(6)				--(付加情報)一時ID
	   ,GROUP_KEY					DECIMAL(6)				--(付加情報)グループキー
	   ,DENPYO_NO					NVARCHAR(12)			--(付加情報)伝票NO
	   ,HACCHU_NO					NVARCHAR(12)			--(付加情報)発注NO(倉庫移動用)
	   ,SOKO_IDO_NO					NVARCHAR(12)			--(付加情報)倉庫移動NO(倉庫移動用)
	   ,JUCHU_KBN					NVARCHAR(MAX)			--受注区分
	   ,JUCHU_DATE					NVARCHAR(MAX)			--受注日
	   ,SHUKKO_KBN					NVARCHAR(MAX)			--出庫区分
	   ,TOKUISAKI_CD				NVARCHAR(MAX)			--得意先コード
	   ,SHUKKASAKI_CD				NVARCHAR(MAX)			--出荷先コード
	   ,SEIKYUSAKI_CD				NVARCHAR(MAX)			--請求先コード
	   ,SOKO_CD						NVARCHAR(MAX)			--倉庫コード
	   ,AZUKE_AZUKARI_IDO_SOKO_CD	NVARCHAR(MAX)			--預け／預かり／移動倉庫コード
	   ,SHUKKA_YOTEI_DATE			NVARCHAR(MAX)			--出荷予定日
	   ,SHITEI_NOHIN_DATE			NVARCHAR(MAX)			--指定納品日
	   ,SHITEI_NOHIN_JIKOKU			NVARCHAR(MAX)			--指定納品時刻
	   ,HAISOU_KBN					NVARCHAR(MAX)			--配送区分
	   ,KESSAI_HOHO					NVARCHAR(MAX)			--決済方法
	   ,HDR_GEDAIMACHI_FLG			NVARCHAR(MAX)			--下代待ちフラグ
	   ,SAMPLE_SHUKKA_FLG			NVARCHAR(MAX)			--サンプル出荷フラグ
	   ,HIKIATE_CHOSEI_FUYO_FLG		NVARCHAR(MAX)			--引当調整不用フラグ
	   ,HDR_SEIKYU_KIJUN_DATE		NVARCHAR(MAX)			--請求基準日
	   ,TOKUISAKI_DENPYO_NO			NVARCHAR(MAX)			--得意先伝票NO
	   ,TOKUISAKI_HACCHU_NO			NVARCHAR(MAX)			--得意先発注NO
	   ,BUNRUI_CD					NVARCHAR(MAX)			--分類コード
	   ,URIBA_NM					NVARCHAR(MAX)			--売場名
	   ,TANTOSHA_NM					NVARCHAR(MAX)			--担当者名
	   ,NAISEN_NO					NVARCHAR(MAX)			--内線番号
	   ,TANTOSHA_CD					NVARCHAR(MAX)			--担当者コード
	   ,TANTO_BUSHO_CD				NVARCHAR(MAX)			--担当部署コード
	   ,NOHIN_KBN					NVARCHAR(MAX)			--納品区分
	   ,RYUTU_KAKOU_KBN				NVARCHAR(MAX)			--流通加工区分
	   ,BIKO						NVARCHAR(MAX)			--備考
	   ,JUCHU_COMMENT				NVARCHAR(MAX)			--受注コメント
	   ,SOKO_COMMENT				NVARCHAR(MAX)			--倉庫コメント
	   ,PROJECT_CD					NVARCHAR(MAX)			--プロジェクトコード
	   ,HANBAI_AREA_CD				NVARCHAR(MAX)			--販売エリアコード
	   ,YOYAKU_KAIHO_KIGEN			NVARCHAR(MAX)			--予約解放期限
	   ,HINMOKU						NVARCHAR(MAX)			--品目
	   ,LOT_NUM						NVARCHAR(MAX)			--ロット数
	   ,BARA_NUM					NVARCHAR(MAX)			--バラ数
	   ,SUITEI_KAKUTEI_KBN			NVARCHAR(MAX)			--推定確定区分
	   ,KAKERITU					NVARCHAR(MAX)			--掛率(%)
	   ,HIKIATE_STATE				NVARCHAR(MAX)			--引当状態
	   ,DTL_GEDAIMACHI_FLG			NVARCHAR(MAX)			--下代待ちフラグ
	   ,DTL_SOKO_CD					NVARCHAR(MAX)			--倉庫コード
	   ,TEKIYO						NVARCHAR(MAX)			--摘要
	   ,DTL_SHUKKASAKI_CD			NVARCHAR(MAX)			--出荷先コード
	   ,DTL_SHUKKA_YOTEI_DATE		NVARCHAR(MAX)			--出荷予定日
	   ,DTL_SHITEI_NOHIN_DATE		NVARCHAR(MAX)			--指定納品日
	   ,DTL_SEIKYU_KIJUN_DATE		NVARCHAR(MAX)			--請求基準日
	)

	--一時テーブルにデータを一括挿入する
   BEGIN TRY    
        DECLARE @CMD NVARCHAR(1000)
        SET @CMD =
            'BULK INSERT #tmp FROM '''
            + @FILE_PATH +
            ''' WITH (
                FIELDTERMINATOR='','',
                DATAFILETYPE = ''widechar '',
                KEEPNULLS
            )'
        EXECUTE(@CMD)
   END TRY
   BEGIN CATCH
		SET @RetCd = 1;
		GOTO END_PROC
   END CATCH
 
   /*===============================入力情報の加工START===============================*/
   /**********************************************
    *品目SEQ設定START
    **********************************************/
	--①品目マスタ
	UPDATE #tmp
	SET HINMOKU_SEQ = HINKAN.HINMOKU_SEQ
	FROM #tmp
	INNER JOIN BC_MST_HINMOKU HIN
		ON #tmp.HINMOKU = HIN.HINMOKU_CD
		AND HIN.MUKOU_FLG = 0
		AND HIN.DEL_FLG = 0
	INNER JOIN BC_MST_HINMOKU_KANRI HINKAN
		ON HIN.KAISHA_CD = HINKAN.KAISHA_CD
		AND HIN.HINMOKU_CD = HINKAN.HINMOKU_CD
		AND HINKAN.DEL_FLG = 0
	WHERE #tmp.ERROR_MSG IS NULL
	AND HIN.KAISHA_CD = @KAISHA_CD
	AND #tmp.HINMOKU_SEQ IS NULL

	--②得意先別品目マスタ
	UPDATE #tmp
	SET HINMOKU_SEQ = HINKAN.HINMOKU_SEQ
	FROM #tmp
	INNER JOIN BC_MST_TOKUISAKI TOKUI
		ON #tmp.TOKUISAKI_CD = TOKUI.TOKUISAKI_CD
		AND TOKUI.MUKOU_FLG = 0
		AND TOKUI.DEL_FLG = 0
	LEFT JOIN BC_MST_TOKUISAKIBETU_HINMOKU TOKUI_HIN
		ON TOKUI.KAISHA_CD = TOKUI_HIN.KAISHA_CD
		AND TOKUI.TOKUISAKI_CD = TOKUI_HIN.TOKUISAKI_CD
		AND #tmp.HINMOKU = TOKUI_HIN.TOKUISAKI_SHOHIN_CD
		AND TOKUI_HIN.DEL_FLG = 0
	LEFT JOIN BC_MST_TOKUISAKIBETU_HINMOKU_EX TOKUI_HIN_EX
		ON TOKUI.KAISHA_CD = TOKUI_HIN_EX.KAISHA_CD
		AND TOKUI.TOKUISAKI_CD = TOKUI_HIN_EX.TOKUISAKI_CD
		AND #tmp.HINMOKU = TOKUI_HIN_EX.TOKUISAKI_SHOHIN_CD2
	INNER JOIN BC_MST_HINMOKU_KANRI HINKAN
		ON HINKAN.KAISHA_CD = @KAISHA_CD
		AND HINKAN.HINMOKU_SEQ = 
				CASE WHEN TOKUI_HIN.HINMOKU_SEQ IS NOT NULL
						THEN TOKUI_HIN.HINMOKU_SEQ
					 ELSE TOKUI_HIN_EX.HINMOKU_SEQ
				END
		AND HINKAN.DEL_FLG = 0
	INNER JOIN BC_MST_HINMOKU HIN
		ON HINKAN.KAISHA_CD = HIN.KAISHA_CD
		AND HINKAN.HINMOKU_CD = HIN.HINMOKU_CD
		AND HIN.MUKOU_FLG = 0
		AND HIN.DEL_FLG = 0
	WHERE #tmp.ERROR_MSG IS NULL
	AND TOKUI.KAISHA_CD = @KAISHA_CD
	AND TOKUI.TOKUISAKI_CD IS NOT NULL
	AND #tmp.HINMOKU_SEQ IS NULL

	--③得意先別品目マスタ（親得意先）
	UPDATE #tmp
	SET HINMOKU_SEQ = HINKAN.HINMOKU_SEQ
	FROM #tmp
	INNER JOIN BC_MST_TOKUISAKI TOKUI
		ON #tmp.TOKUISAKI_CD = TOKUI.TOKUISAKI_CD
		AND TOKUI.MUKOU_FLG = 0
		AND TOKUI.DEL_FLG = 0
	INNER JOIN BC_MST_TOKUISAKI_EX TOKUI_EX
		ON TOKUI.KAISHA_CD = TOKUI_EX.KAISHA_CD
		AND TOKUI.TOKUISAKI_CD = TOKUI_EX.TOKUISAKI_CD
	INNER JOIN BC_MST_TOKUISAKI OYA_TOKUI
		ON OYA_TOKUI.KAISHA_CD = TOKUI_EX.KAISHA_CD
		AND OYA_TOKUI.TOKUISAKI_CD = TOKUI_EX.OYA_TOKUISAKI_CD
		AND OYA_TOKUI.MUKOU_FLG = 0
		AND OYA_TOKUI.DEL_FLG = 0
	LEFT JOIN BC_MST_TOKUISAKIBETU_HINMOKU TOKUI_HIN
		ON OYA_TOKUI.KAISHA_CD = TOKUI_HIN.KAISHA_CD
		AND OYA_TOKUI.TOKUISAKI_CD = TOKUI_HIN.TOKUISAKI_CD
		AND #tmp.HINMOKU = TOKUI_HIN.TOKUISAKI_SHOHIN_CD
		AND TOKUI_HIN.DEL_FLG = 0
	LEFT JOIN BC_MST_TOKUISAKIBETU_HINMOKU_EX TOKUI_HIN_EX
		ON OYA_TOKUI.KAISHA_CD = TOKUI_HIN_EX.KAISHA_CD
		AND OYA_TOKUI.TOKUISAKI_CD = TOKUI_HIN_EX.TOKUISAKI_CD
		AND #tmp.HINMOKU = TOKUI_HIN_EX.TOKUISAKI_SHOHIN_CD2
	INNER JOIN BC_MST_HINMOKU_KANRI HINKAN
		ON HINKAN.KAISHA_CD = @KAISHA_CD
		AND HINKAN.HINMOKU_SEQ = 
				CASE WHEN TOKUI_HIN.HINMOKU_SEQ IS NOT NULL
						THEN TOKUI_HIN.HINMOKU_SEQ
					 ELSE TOKUI_HIN_EX.HINMOKU_SEQ
				END
		AND HINKAN.DEL_FLG = 0
	INNER JOIN BC_MST_HINMOKU HIN
		ON HINKAN.KAISHA_CD = HIN.KAISHA_CD
		AND HINKAN.HINMOKU_CD = HIN.HINMOKU_CD
		AND HIN.MUKOU_FLG = 0
		AND HIN.DEL_FLG = 0
	WHERE #tmp.ERROR_MSG IS NULL
	AND TOKUI.KAISHA_CD = @KAISHA_CD
	AND TOKUI.TOKUISAKI_CD IS NOT NULL
	AND #tmp.HINMOKU_SEQ IS NULL

	--④品目マスタJANコード
	UPDATE #tmp
	SET HINMOKU_SEQ = HINKAN.HINMOKU_SEQ
	FROM #tmp
	INNER JOIN BC_MST_HINMOKU HIN
		ON #tmp.HINMOKU = HIN.JAN_CD
		AND HIN.MUKOU_FLG = 0
		AND HIN.DEL_FLG = 0
	INNER JOIN BC_MST_HINMOKU_KANRI HINKAN
		ON HIN.KAISHA_CD = HINKAN.KAISHA_CD
		AND HIN.HINMOKU_CD = HINKAN.HINMOKU_CD
		AND HINKAN.DEL_FLG = 0
	WHERE #tmp.ERROR_MSG IS NULL
	AND HIN.KAISHA_CD = @KAISHA_CD
	AND #tmp.HINMOKU_SEQ IS NULL
	/**********************************************
    *品目SEQ設定END
    **********************************************/

	/**********************************************
    *請求先設定START
    **********************************************/
	--未設定は既定請求先
	UPDATE #tmp
	SET SEIKYUSAKI_CD = SEIKYU.SEIKYUSAKI_CD
	FROM #tmp
	INNER JOIN BC_MST_TOKUISAKI TOKUI
		ON #tmp.TOKUISAKI_CD = TOKUI.TOKUISAKI_CD
		AND TOKUI.MUKOU_FLG = 0
		AND TOKUI.DEL_FLG = 0
	INNER JOIN BC_MST_SEIKYUSAKI SEIKYU
		ON TOKUI.KAISHA_CD = SEIKYU.KAISHA_CD
		AND TOKUI.KITEI_SEIKYUSAKI_CD = SEIKYU.SEIKYUSAKI_CD
		AND SEIKYU.MUKOU_FLG = 0
		AND SEIKYU.DEL_FLG = 0
	WHERE #tmp.ERROR_MSG IS NULL
	AND TOKUI.KAISHA_CD = @KAISHA_CD
	AND #tmp.SEIKYUSAKI_CD IS NULL
	/**********************************************
    *請求先設定END
    **********************************************/

	/**********************************************
    *出荷先設定START
    **********************************************/
	--未設定は既定出荷先
	UPDATE #tmp
	SET SHUKKASAKI_CD = SHUKKA.SHUKKASAKI_CD
	FROM #tmp
	INNER JOIN BC_MST_TOKUISAKI TOKUI
		ON #tmp.TOKUISAKI_CD = TOKUI.TOKUISAKI_CD
		AND TOKUI.MUKOU_FLG = 0
		AND TOKUI.DEL_FLG = 0
	INNER JOIN BC_MST_SHUKKASAKI SHUKKA
		ON TOKUI.KAISHA_CD = SHUKKA.KAISHA_CD
		AND TOKUI.KITEI_SHUKKASAKI_CD = SHUKKA.SHUKKASAKI_CD
		AND SHUKKA.MUKOU_FLG = 0
		AND SHUKKA.DEL_FLG = 0
	WHERE #tmp.ERROR_MSG IS NULL
	AND TOKUI.KAISHA_CD = @KAISHA_CD
	AND #tmp.SHUKKASAKI_CD IS NULL
	/**********************************************
    *出荷先設定END
    **********************************************/


	/**********************************************
    *出荷先存在チェックSTART
    **********************************************/
	--出荷先コード(ヘッダ)
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_INCORRECT_CODE + @FLD_NM_SHUKKASAKI_CD
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.SHUKKASAKI_CD IS NOT NULL
    AND NOT EXISTS (SELECT * FROM BC_MST_SHUKKASAKI SHUKKA
                    WHERE SHUKKA.KAISHA_CD = @KAISHA_CD
                    AND SHUKKA.SHUKKASAKI_CD = #tmp.SHUKKASAKI_CD
					AND SHUKKA.MUKOU_FLG = 0
                    AND SHUKKA.DEL_FLG = 0
                   )
	/**********************************************
    *出荷先存在チェックEND
    **********************************************/


	/**********************************************
    *出庫区分設定START
    **********************************************/
	--未設定は【通常】を設定
	UPDATE #tmp
	SET SHUKKO_KBN = '01'
	WHERE ERROR_MSG IS NULL
	AND SHUKKO_KBN IS NULL
	/**********************************************
    *出庫区分設定END
    **********************************************/

	/**********************************************
    *明細出荷先設定START
    **********************************************/
	--未設定はヘッダの出荷先を設定
	UPDATE #tmp
	SET DTL_SHUKKASAKI_CD = SHUKKASAKI_CD
	WHERE ERROR_MSG IS NULL
	AND DTL_SHUKKASAKI_CD IS NULL
	/**********************************************
    *明細出荷先設定END
    **********************************************/

	/**********************************************
    *明細倉庫設定START
    **********************************************/
	--未設定はヘッダの倉庫を設定
	UPDATE #tmp
	SET DTL_SOKO_CD = SOKO_CD
	WHERE ERROR_MSG IS NULL
	AND DTL_SOKO_CD IS NULL
	/**********************************************
    *明細倉庫設定END
    **********************************************/

	/**********************************************
    *受注日設定START
    **********************************************/
	--未設定はシステム日付
	UPDATE #tmp
	SET JUCHU_DATE = CONVERT(DATE, SYSDATETIME())
	WHERE ERROR_MSG IS NULL
	AND JUCHU_DATE IS NULL
	/**********************************************
    *受注日設定END
    **********************************************/

	/**********************************************
    *ヘッダ出荷予定日設定START
    **********************************************/
	--未設定は基幹側で指定納品日から出荷先リードタイムより逆算
	--未設定は既定出荷先
	DECLARE @LEAD_TIME INT = 0
	DECLARE @SHITEI_NOHIN_DATE DATETIME
	DECLARE @SHUKKASAKI_CD NVARCHAR(15)
	--カーソル
	DECLARE CUR_LEAD_TIME CURSOR LOCAL FOR
	SELECT 
		SHUKKAEX.LEAD_TIME,
		#tmp.SHITEI_NOHIN_DATE,
		#tmp.SHUKKASAKI_CD
	FROM
		#tmp
	LEFT JOIN BC_MST_SHUKKASAKI_EX SHUKKAEX
		ON SHUKKAEX.KAISHA_CD = @KAISHA_CD
		AND SHUKKAEX.SHUKKASAKI_CD = #tmp.SHUKKASAKI_CD
	WHERE #tmp.ERROR_MSG IS NULL
	AND #tmp.SHUKKA_YOTEI_DATE IS NULL

	OPEN CUR_LEAD_TIME		
	FETCH NEXT FROM CUR_LEAD_TIME
		INTO @LEAD_TIME ,
			@SHITEI_NOHIN_DATE,
			@SHUKKASAKI_CD
	WHILE @@FETCH_STATUS = 0 BEGIN
			
		UPDATE #tmp	
			SET SHUKKA_YOTEI_DATE = CONVERT(VARCHAR(8),HOLIDAY_COUNT.SHUKKA_YOTEI_DATE,112)
		FROM 
			#tmp
			LEFT JOIN
			BC_MST_SHUKKASAKI_EX SHUKKAEX
			ON SHUKKAEX.KAISHA_CD = @KAISHA_CD
			AND SHUKKAEX.SHUKKASAKI_CD = #tmp.SHUKKASAKI_CD
			LEFT JOIN (
			SELECT 
			KAISHA_CD
			,MAX(DATE) AS SHUKKA_YOTEI_DATE 
			FROM 
			BC_MST_EIGYO_DATE
			WHERE 
			DATE <= DATEADD(dd, -ISNULL(@LEAD_TIME,0), @SHITEI_NOHIN_DATE) 
			AND HOLIDAY_FLG = 0
			GROUP BY KAISHA_CD
			) HOLIDAY_COUNT
			ON SHUKKAEX.KAISHA_CD = HOLIDAY_COUNT.KAISHA_CD 
			WHERE
			SHUKKAEX.KAISHA_CD = @KAISHA_CD
			AND #tmp.SHUKKASAKI_CD = @SHUKKASAKI_CD
		FETCH NEXT FROM CUR_LEAD_TIME
		INTO @LEAD_TIME ,
			@SHITEI_NOHIN_DATE,
			@SHUKKASAKI_CD
		END
	CLOSE CUR_LEAD_TIME
	DEALLOCATE CUR_LEAD_TIME
	/**********************************************
    *ヘッダ出荷予定日設定END
    **********************************************/

	/**********************************************
    *明細出荷予定日設定START
    **********************************************/
	--未設定はヘッダの出荷予定日
	UPDATE #tmp
	SET DTL_SHUKKA_YOTEI_DATE = SHUKKA_YOTEI_DATE
	WHERE ERROR_MSG IS NULL
	AND DTL_SHUKKA_YOTEI_DATE IS NULL
	/**********************************************
    *明細出荷予定日設定END
    **********************************************/

	/**********************************************
    *明細請求基準日設定START
    **********************************************/
	--未設定は明細の出荷予定日
	UPDATE #tmp
	SET DTL_SEIKYU_KIJUN_DATE = DTL_SHUKKA_YOTEI_DATE
	WHERE ERROR_MSG IS NULL
	AND DTL_SEIKYU_KIJUN_DATE IS NULL
	/**********************************************
    *明細請求基準日設定END
    **********************************************/

	/**********************************************
    *明細指定納品日設定START
    **********************************************/
	--未設定はヘッダの指定納品日
	UPDATE #tmp
	SET DTL_SHITEI_NOHIN_DATE = SHITEI_NOHIN_DATE
	WHERE ERROR_MSG IS NULL
	AND DTL_SHITEI_NOHIN_DATE IS NULL
	/**********************************************
    *明細指定納品日設定END
    **********************************************/

	/**********************************************
    *推定確定区分設定START
    **********************************************/
	--未設定かつ受注区分「予約」は【推定】他は【確定】を設定
	UPDATE #tmp
	SET SUITEI_KAKUTEI_KBN = CASE WHEN JUCHU_KBN = '02'
									THEN '01'	--推定
								   ELSE '02'	--確定
							 END
	WHERE ERROR_MSG IS NULL
	AND SUITEI_KAKUTEI_KBN IS NULL

	/**********************************************
    *推定確定区分設定START
    **********************************************/

	/**********************************************
    *引当状態設定START
    **********************************************/
	--①未設定かつ【確定】は【引当】
	UPDATE #tmp
	SET HIKIATE_STATE = '02'
	WHERE ERROR_MSG IS NULL
	AND HIKIATE_STATE IS NULL
	AND SUITEI_KAKUTEI_KBN = '02'

	--②未設定かつ【推定】は品目マスタの引当初期状態
	UPDATE #tmp
	SET HIKIATE_STATE = HIN.STD_HIKIATE_KBN
	FROM #tmp
	INNER JOIN BC_MST_HINMOKU_KANRI HINKAN
		ON HINKAN.HINMOKU_SEQ = #tmp.HINMOKU_SEQ
	INNER JOIN BC_MST_HINMOKU HIN
		ON HIN.KAISHA_CD = HINKAN.KAISHA_CD
		AND HIN.HINMOKU_CD = HINKAN.HINMOKU_CD
	WHERE #tmp.ERROR_MSG IS NULL
	AND #tmp.HIKIATE_STATE IS NULL
	AND #tmp.HINMOKU_SEQ IS NOT NULL
	AND #tmp.SUITEI_KAKUTEI_KBN = '01'
	AND HINKAN.KAISHA_CD = @KAISHA_CD
	/**********************************************
    *引当状態設定END
    **********************************************/

	/**********************************************
    *課税区分設定START
    **********************************************/
	--未設定は取引先マスタの受注消費税区分が非課税の場合、非課税
	--他は課税
	UPDATE #tmp
	SET KAZEI_KBN = CASE WHEN TORIHIKI.JUCHU_SHOHIZEI_KBN = 'M1'
							THEN '02'
						 ELSE '01'
					 END
	FROM #tmp
	INNER JOIN BC_MST_TOKUISAKI TOKUI
		ON #tmp.TOKUISAKI_CD = TOKUI.TOKUISAKI_CD
		AND TOKUI.MUKOU_FLG = 0
		AND TOKUI.DEL_FLG = 0
	INNER JOIN BC_MST_TORIHIKISAKI TORIHIKI
		ON TOKUI.KAISHA_CD = TORIHIKI.KAISHA_CD
		AND TOKUI.TOKUISAKI_CD = TORIHIKI.TORIHIKISAKI_CD
		AND TORIHIKI.MUKOU_FLG = 0
		AND TORIHIKI.DEL_FLG = 0
	WHERE #tmp.ERROR_MSG IS NULL
	AND TOKUI.KAISHA_CD = @KAISHA_CD
	AND #tmp.KAZEI_KBN IS NULL
	/**********************************************
    *課税区分設定END
    **********************************************/
	/*===============================入力情報の加工END===============================*/

	/*===============================レコード単位エラーチェックSTART===============================*/
	/**********************************************
    *必須チェックSTART
    **********************************************/
	--基本的な必須チェック
	UPDATE #tmp
	SET #tmp.ERROR_MSG = 
		CASE --受注区分未設定
			 WHEN JUCHU_KBN IS NULL
					THEN @ERR_MSG_MANDATORY_FIELD + @FLD_NM_JUCHU_KBN
			 --得意先未設定
			 WHEN TOKUISAKI_CD IS NULL
					THEN @ERR_MSG_MANDATORY_FIELD + @FLD_NM_TOKUISAKI_CD
			 --得意先伝票No未設定
			 WHEN TOKUISAKI_DENPYO_NO IS NULL
					THEN @ERR_MSG_MANDATORY_FIELD + @FLD_NM_TOKUISAKI_DENPYO_NO			
			 --請求先未設定かつ得意先に既定請求先が存在しない
			 WHEN SEIKYUSAKI_CD IS NULL
					THEN @ERR_MSG_MANDATORY_FIELD + @FLD_NM_SEIKYUSAKI_CD
			 --預け預かり移動倉庫未設定かつ、受注区分【移動】または出庫区分【預かり売上】【預け出庫】
			 WHEN AZUKE_AZUKARI_IDO_SOKO_CD IS NULL AND (JUCHU_KBN = '03' OR (JUCHU_KBN = '01' AND SHUKKO_KBN IN ('03', '06')))
					THEN @ERR_MSG_MANDATORY_FIELD + @FLD_NM_AZUKE_AZUKARI_IDO_SOKO_CD
			 --品目未設定
			 WHEN HINMOKU IS NULL
					THEN @ERR_MSG_MANDATORY_FIELD + @FLD_NM_HINMOKU
			 --品目に対する該当品目が存在しない
			 WHEN HINMOKU_SEQ IS NULL
					THEN @ERR_MSG_NOT_EXIST_HINMOKU
			 --明細の出荷先未設定かつ、受注区分【本受注・移動】
			 WHEN DTL_SHUKKASAKI_CD IS NULL AND (JUCHU_KBN ='01' OR JUCHU_KBN ='03')
					THEN @ERR_MSG_MANDATORY_FIELD + @FLD_NM_SHUKKASAKI_CD
			 --備考(明細)未設定ecbeingの行No(出荷実績連携に必要なため）
			 WHEN DTL_BIKO IS NULL
					THEN @ERR_MSG_MANDATORY_FIELD + @FLD_NM_DTL_BIKO
		END
	WHERE #tmp.ERROR_MSG IS NULL

	--条件付き必須チェック
	--①外貨対応
	--取引先が外貨の場合、取引先通貨単価は必須
	UPDATE #tmp
	SET #tmp.ERROR_MSG = CASE WHEN TORI_GAIKA.TUKA_CD <> @TUKA_CD AND TORIHIKISAKI_TUKA_TANKA IS NULL
									THEN @ERR_MSG_MANDATORY_FIELD + @FLD_NM_TORIHIKISAKI_TUKA_TANKA
						 END
	FROM #tmp
	INNER JOIN BC_MST_TOKUISAKI TOKUI
		ON #tmp.TOKUISAKI_CD = TOKUI.TOKUISAKI_CD
		AND TOKUI.MUKOU_FLG = 0
		AND TOKUI.DEL_FLG = 0
	INNER JOIN BC_MST_TORIHIKISAKI TORIHIKI
		ON TOKUI.KAISHA_CD = TORIHIKI.KAISHA_CD
		AND TOKUI.TOKUISAKI_CD = TORIHIKI.TORIHIKISAKI_CD
		AND TORIHIKI.MUKOU_FLG = 0
		AND TORIHIKI.DEL_FLG = 0
	INNER JOIN BC_MST_TORIHIKISAKI_GAIKA TORI_GAIKA
		ON TORI_GAIKA.KAISHA_CD = TORIHIKI.KAISHA_CD
		AND TORI_GAIKA.TORIHIKISAKI_CD = TORIHIKI.TORIHIKISAKI_CD
		AND TORI_GAIKA.MUKOU_FLG = 0
		AND TORI_GAIKA.DEL_FLG = 0
	WHERE #tmp.ERROR_MSG IS NULL
	AND TOKUI.KAISHA_CD = @KAISHA_CD

	--②品目関係
	UPDATE #tmp
	SET #tmp.ERROR_MSG = 
		CASE --在庫管理品の場合に、倉庫未設定
			 WHEN #tmp.DTL_SOKO_CD IS NULL AND HIN.ZAIKO_KANRI_FLG = 1
					THEN @ERR_MSG_MANDATORY_FIELD + @FLD_NM_SOKO_CD
			 --本受注かつロット数、バラ数未設定の場合に、標準入数なし
			 WHEN JUCHU_KBN ='01' AND #tmp.LOT_NUM IS NULL AND #tmp.BARA_NUM IS NULL AND HIN.STD_IRISU IS NULL
					THEN @ERR_MSG_MANDATORY_FIELD + @FLD_NM_LOT_NUM + NCHAR(13) + @FLD_NM_BARA_NUM
		END
	FROM #tmp
	INNER JOIN BC_MST_HINMOKU_KANRI HINKAN
		ON HINKAN.HINMOKU_SEQ = #tmp.HINMOKU_SEQ
	INNER JOIN BC_MST_HINMOKU HIN
		ON HIN.KAISHA_CD = HINKAN.KAISHA_CD
		AND HIN.HINMOKU_CD = HINKAN.HINMOKU_CD
	WHERE #tmp.ERROR_MSG IS NULL
	AND HINKAN.KAISHA_CD = @KAISHA_CD
	/**********************************************
    *必須チェックEND
    **********************************************/

	/**********************************************
    *取引通貨チェックSTART
    **********************************************/
	UPDATE #tmp
	SET ERROR_MSG = @ERR_MSG_DIFFERENT_TUKA + @FLD_NM_TOKUISAKI_CD + NCHAR(13) + @FLD_NM_SEIKYUSAKI_CD
	FROM #tmp tmp
	LEFT JOIN BC_MST_TORIHIKISAKI_GAIKA TOKUISAKI
		ON TOKUISAKI.KAISHA_CD = @KAISHA_CD
		AND TOKUISAKI.TORIHIKISAKI_CD = tmp.TOKUISAKI_CD
		AND TOKUISAKI.DEL_FLG = 0
	LEFT JOIN BC_MST_TORIHIKISAKI_GAIKA SEIKYUSAKI
		ON SEIKYUSAKI.KAISHA_CD = @KAISHA_CD
		AND SEIKYUSAKI.TORIHIKISAKI_CD = tmp.SEIKYUSAKI_CD
		AND SEIKYUSAKI.DEL_FLG = 0
	WHERE ERROR_MSG IS NULL
	AND TOKUISAKI.TUKA_CD <> SEIKYUSAKI.TUKA_CD

	/**********************************************
    *取引通貨チェックSTART
    **********************************************/

	/**********************************************
    *固定値チェックSTART
    **********************************************/
	--受注区分【本受注】、出庫区分【通常】であること
	UPDATE #tmp
	SET ERROR_MSG = @ERR_MSG_CANNOT_USE_CODE + @FLD_NM_JUCHU_KBN			
	WHERE ERROR_MSG IS NULL
	AND JUCHU_KBN <> '01'

	UPDATE #tmp
	SET ERROR_MSG = @ERR_MSG_CANNOT_USE_CODE + @FLD_NM_SHUKKO_KBN		
	WHERE ERROR_MSG IS NULL
	AND SHUKKO_KBN <> '01'

	--倉庫コード"000001001"であること
	UPDATE #tmp
	SET ERROR_MSG = @ERR_MSG_CANNOT_USE_CODE + @FLD_NM_SOKO_CD		
	WHERE ERROR_MSG IS NULL
	AND SOKO_CD <> '000001001'

	--推定/確定区分
	UPDATE #tmp
	SET ERROR_MSG = @ERR_MSG_CANNOT_USE_CODE + @FLD_NM_SUITEI_KAKUTEI_KBN	
	WHERE ERROR_MSG IS NULL
	AND SUITEI_KAKUTEI_KBN <> '02'

	/**********************************************
    *固定値チェックEND
    **********************************************/

	/**********************************************
    *受注区分による条件チェックSTART
    **********************************************/
	--予約伝票
	--出庫区分【通常】、推定確定区分【推定】であること
	UPDATE #tmp
	SET ERROR_MSG = 
			CASE WHEN SHUKKO_KBN <> '01'
					THEN @ERR_MSG_CANNOT_USE_CODE + @FLD_JUCHU_KBN_YOYAKU + NCHAR(13) + @FLD_NM_SHUKKO_KBN
				 WHEN SUITEI_KAKUTEI_KBN <> '01'
					THEN @ERR_MSG_CANNOT_USE_CODE + @FLD_JUCHU_KBN_YOYAKU + NCHAR(13) + @FLD_NM_SUITEI_KAKUTEI_KBN
			END
	WHERE ERROR_MSG IS NULL
	AND JUCHU_KBN = '02'
	
	--倉庫移動
	--出庫区分【倉庫移動】であること
	UPDATE #tmp
	SET ERROR_MSG = CASE WHEN SHUKKO_KBN <> '40'
							THEN @ERR_MSG_CANNOT_USE_CODE + @FLD_JUCHU_KBN_SOKO_IDO + NCHAR(13) + @FLD_NM_SHUKKO_KBN
					END
	WHERE ERROR_MSG IS NULL
	AND JUCHU_KBN = '03'
	
	--移動元と移動先倉庫が同じ場合エラー
	UPDATE #tmp
	SET ERROR_MSG = CASE WHEN SOKO_CD = AZUKE_AZUKARI_IDO_SOKO_CD
							THEN @ERR_MSG_SOKO_IDO_SOKO
					END
	WHERE ERROR_MSG IS NULL
	AND JUCHU_KBN = '03'
	
	--移動元と移動先どちらも店舗の場合エラー
	UPDATE #tmp
    SET #tmp.ERROR_MSG = 
			CASE WHEN MOTO_TOKUI_EX.TORIHIKI_KEITAI_KBN IN ('4','5') AND SAKI_TOKUI_EX.TORIHIKI_KEITAI_KBN IN ('4','5')
					THEN @ERR_MSG_SOKO_TENPO
			END
	FROM #tmp
	LEFT JOIN BC_MST_TORIHIKISAKI MOTO_TORI
		ON MOTO_TORI.TORIHIKISAKI_CD = #tmp.SOKO_CD
		AND MOTO_TORI.KAISHA_CD = @KAISHA_CD
		AND MOTO_TORI.TOKUISAKI_FLG = 1
	LEFT JOIN BC_MST_TOKUISAKI MOTO_TOKUI
		ON MOTO_TOKUI.TOKUISAKI_CD = MOTO_TORI.TORIHIKISAKI_CD
		AND MOTO_TOKUI.KAISHA_CD = MOTO_TORI.KAISHA_CD
		AND MOTO_TOKUI.MUKOU_FLG = 0
		AND MOTO_TOKUI.DEL_FLG = 0
	LEFT JOIN BC_MST_TOKUISAKI_EX MOTO_TOKUI_EX
		ON MOTO_TOKUI_EX.TOKUISAKI_CD = MOTO_TOKUI.TOKUISAKI_CD
		AND MOTO_TOKUI_EX.KAISHA_CD = MOTO_TOKUI.KAISHA_CD
		
	LEFT JOIN BC_MST_TORIHIKISAKI SAKI_TORI
		ON SAKI_TORI.TORIHIKISAKI_CD = #tmp.AZUKE_AZUKARI_IDO_SOKO_CD
		AND SAKI_TORI.KAISHA_CD = @KAISHA_CD
		AND SAKI_TORI.TOKUISAKI_FLG = 1
	LEFT JOIN BC_MST_TOKUISAKI SAKI_TOKUI
		ON SAKI_TOKUI.TOKUISAKI_CD = SAKI_TORI.TORIHIKISAKI_CD
		AND SAKI_TOKUI.KAISHA_CD = SAKI_TORI.KAISHA_CD
		AND SAKI_TOKUI.MUKOU_FLG = 0
		AND SAKI_TOKUI.DEL_FLG = 0
	LEFT JOIN BC_MST_TOKUISAKI_EX SAKI_TOKUI_EX
		ON SAKI_TOKUI_EX.TOKUISAKI_CD = SAKI_TOKUI.TOKUISAKI_CD
		AND SAKI_TOKUI_EX.KAISHA_CD = SAKI_TOKUI.KAISHA_CD
	WHERE #tmp.ERROR_MSG IS NULL
	AND #tmp.JUCHU_KBN = '03'

	
	/**********************************************
    *受注区分による条件チェックEND
    **********************************************/
	
	/**********************************************
    *預け・預かり・予約・倉庫移動・倉庫区分チェックSTART
    **********************************************/
	--①在庫管理品チェック
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_CANNOT_ZAIKOKNARI + @FLD_NM_HINMOKU
	FROM #tmp	
	WHERE #tmp.ERROR_MSG IS NULL
	AND (#tmp.SHUKKO_KBN IN ('03', '04', '06', '07')
			OR #tmp.JUCHU_KBN IN ('02', '03'))
	AND NOT EXISTS (SELECT *
	                FROM BC_MST_HINMOKU_KANRI HINKAN
				    INNER JOIN BC_MST_HINMOKU HIN
						ON HIN.KAISHA_CD = HINKAN.KAISHA_CD
						AND HIN.HINMOKU_CD = HINKAN.HINMOKU_CD
					WHERE HINKAN.KAISHA_CD = @KAISHA_CD
					AND HINKAN.HINMOKU_SEQ = #tmp.HINMOKU_SEQ
					AND HIN.ZAIKO_KANRI_FLG = 1
				   )

	--②預かり出庫、預け売上時の倉庫区分チェック
	UPDATE #tmp
    SET #tmp.ERROR_MSG = 
			CASE --預かり出庫時に、預かり倉庫が指定されていない
				 WHEN #tmp.SHUKKO_KBN = '04' AND SOKO.SOKO_KBN <> '02'
						THEN @ERR_MSG_AZUKE_AZUKARI_SOKO + @FLD_NM_SOKO_CD
				 --預け売上時に、預け倉庫が指定されていない
				 WHEN #tmp.SHUKKO_KBN = '07' AND SOKO.SOKO_KBN <> '03'
						THEN @ERR_MSG_AZUKE_AZUKARI_SOKO + @FLD_NM_SOKO_CD
			 END
	FROM #tmp
	INNER JOIN BC_MST_SOKO SOKO
		ON #tmp.DTL_SOKO_CD = SOKO.SOKO_CD
	WHERE #tmp.ERROR_MSG IS NULL
	AND SOKO.KAISHA_CD = @KAISHA_CD
	AND #tmp.SHUKKO_KBN IN ('04', '07')

	--③預かり売上、預け出庫時の【預け預かり移動倉庫】倉庫区分チェック
	UPDATE #tmp
    SET #tmp.ERROR_MSG = 
			CASE --預かり売上時に、【預け預かり移動倉庫】に預かり倉庫が指定されていない
				 WHEN #tmp.SHUKKO_KBN = '03' AND SOKO.SOKO_KBN <> '02'
						THEN @ERR_MSG_AZUKE_AZUKARI_SOKO + @FLD_NM_AZUKE_AZUKARI_IDO_SOKO_CD
				 --預け売上時に、【預け預かり移動倉庫】に預け倉庫が指定されていない
				 WHEN #tmp.SHUKKO_KBN = '06' AND SOKO.SOKO_KBN <> '03'
						THEN @ERR_MSG_AZUKE_AZUKARI_SOKO + @FLD_NM_AZUKE_AZUKARI_IDO_SOKO_CD
			 END
	FROM #tmp
	INNER JOIN BC_MST_SOKO SOKO
		ON #tmp.AZUKE_AZUKARI_IDO_SOKO_CD = SOKO.SOKO_CD
	WHERE #tmp.ERROR_MSG IS NULL
	AND SOKO.KAISHA_CD = @KAISHA_CD
	AND #tmp.SHUKKO_KBN IN ('03', '06')

	--④出庫区分が「通常」時の、倉庫区分「通常」チェック
	UPDATE #tmp
    SET #tmp.ERROR_MSG = 
			CASE WHEN SOKO.SOKO_KBN <> '01'
					THEN @ERR_MSG_TUJOU_SHUKKO_SOKO + @FLD_NM_SOKO_CD + NCHAR(13) + #tmp.DTL_SOKO_CD
			END
	FROM #tmp
	INNER JOIN BC_MST_SOKO SOKO
		ON SOKO.SOKO_CD = #tmp.DTL_SOKO_CD
	WHERE #tmp.ERROR_MSG IS NULL
	AND SOKO.KAISHA_CD = @KAISHA_CD
	AND #tmp.SHUKKO_KBN = '01'

	--⑤倉庫移動時、移動元、移動先の倉庫区分が「通常」であること
	UPDATE #tmp
    SET #tmp.ERROR_MSG = 
			CASE WHEN MOTO_SOKO.SOKO_KBN <> '01'
					THEN @ERR_MSG_SOKO_IDO_SHUKKO_KBN + @FLD_NM_SOKO_CD
			    WHEN SAKI_SOKO.SOKO_KBN <> '01'
					THEN @ERR_MSG_SOKO_IDO_SHUKKO_KBN + @FLD_NM_AZUKE_AZUKARI_IDO_SOKO_CD
			END
	FROM #tmp
	INNER JOIN BC_MST_SOKO MOTO_SOKO
		ON MOTO_SOKO.SOKO_CD = #tmp.DTL_SOKO_CD
	INNER JOIN BC_MST_SOKO SAKI_SOKO
		ON SAKI_SOKO.SOKO_CD = #tmp.AZUKE_AZUKARI_IDO_SOKO_CD
	WHERE #tmp.ERROR_MSG IS NULL
	AND MOTO_SOKO.KAISHA_CD = @KAISHA_CD
	AND SAKI_SOKO.KAISHA_CD = @KAISHA_CD
	AND #tmp.JUCHU_KBN = '03'

	/**********************************************
    *預け・預かり・倉庫移動・倉庫区分チェックEND
    **********************************************/

	/**********************************************
    *長さチェックSTART
    **********************************************/
	UPDATE #tmp
	SET #tmp.ERROR_MSG = 
		CASE --指定納品時刻
			 WHEN SHITEI_NOHIN_JIKOKU IS NOT NULL AND LEN(SHITEI_NOHIN_JIKOKU) > 20
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_SHITEI_NOHIN_JIKOKU
			 --得意先伝票番号
			 WHEN TOKUISAKI_DENPYO_NO IS NOT NULL AND LEN(TOKUISAKI_DENPYO_NO) > 20
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_TOKUISAKI_DENPYO_NO
			 --得意先発注番号
			 WHEN TOKUISAKI_HACCHU_NO IS NOT NULL AND LEN(TOKUISAKI_HACCHU_NO) > 20
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_TOKUISAKI_HACCHU_NO
			 --分類コード
			 WHEN BUNRUI_CD IS NOT NULL AND LEN(BUNRUI_CD) > 20
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_BUNRUI_CD
			 --売場名
			 WHEN URIBA_NM IS NOT NULL AND LEN(URIBA_NM) > 20
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_URIBA_NM
			 --担当者名
			 WHEN TANTOSHA_NM IS NOT NULL AND LEN(TANTOSHA_NM) > 40
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_TANTOSHA_NM
			 --内線番号
			 WHEN NAISEN_NO IS NOT NULL AND LEN(NAISEN_NO) > 20
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_NAISEN_NO
			 --備考
			 WHEN BIKO IS NOT NULL AND LEN(BIKO) > 100
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_BIKO
			 --受注コメント
			 WHEN JUCHU_COMMENT IS NOT NULL AND LEN(JUCHU_COMMENT) > 100
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_JUCHU_COMMENT
			 --倉庫向けコメント
			 WHEN SOKO_COMMENT IS NOT NULL AND LEN(SOKO_COMMENT) > 100
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_SOKO_COMMENT
			 --摘要
			 WHEN TEKIYO IS NOT NULL AND LEN(TEKIYO) > 500
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_TEKIYO
			 --備考(明細)
			 WHEN DTL_BIKO IS NOT NULL AND LEN(DTL_BIKO) > 100
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_DTL_BIKO
		END
	WHERE #tmp.ERROR_MSG IS NULL
	/**********************************************
    *長さチェックEND
    **********************************************/

	/**********************************************
    *日付チェックSTART
    **********************************************/
	UPDATE #tmp
	SET #tmp.ERROR_MSG = 
		CASE --受注日
			 WHEN ISDATE(JUCHU_DATE) != 1
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_JUCHU_DATE
			 --出荷予定日(ヘッダ)
			 WHEN ISDATE(SHUKKA_YOTEI_DATE) != 1
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_HDR_SHUKKA_YOTEI_DATE
			 --指定納品日(ヘッダ)
			 WHEN SHITEI_NOHIN_DATE IS NOT NULL AND ISDATE(SHITEI_NOHIN_DATE) != 1
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_SHITEI_NOHIN_DATE
			 --請求基準日(ヘッダ)
			 WHEN HDR_SEIKYU_KIJUN_DATE IS NOT NULL AND ISDATE(HDR_SEIKYU_KIJUN_DATE) != 1
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_SEIKYU_KIJUN_DATE
			 --予約解放期限
			 WHEN YOYAKU_KAIHO_KIGEN IS NOT NULL AND ISDATE(YOYAKU_KAIHO_KIGEN) != 1
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_YOYAKU_KAIHO_KIGEN
			 --出荷予定日(明細)
			 WHEN ISDATE(DTL_SHUKKA_YOTEI_DATE) != 1
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_DTL_SHUKKA_YOTEI_DATE
			 --指定納品日(明細)
			 WHEN DTL_SHITEI_NOHIN_DATE IS NOT NULL AND ISDATE(DTL_SHITEI_NOHIN_DATE) != 1
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_SHITEI_NOHIN_DATE
			 --請求基準日(明細)
			 WHEN DTL_SEIKYU_KIJUN_DATE IS NOT NULL AND ISDATE(DTL_SEIKYU_KIJUN_DATE) != 1
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_SEIKYU_KIJUN_DATE
		END
	WHERE #tmp.ERROR_MSG IS NULL

    --受注日<=出荷予定日チェック
    UPDATE #tmp
	SET #tmp.ERROR_MSG = 
			CASE WHEN DATEDIFF(DD, #tmp.JUCHU_DATE, #tmp.SHUKKA_YOTEI_DATE) < 0
						THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_JUCHU_DATE + NCHAR(13) + '＞' + @FLD_NM_HDR_SHUKKA_YOTEI_DATE
				 WHEN DATEDIFF(DD, #tmp.JUCHU_DATE, #tmp.DTL_SHUKKA_YOTEI_DATE) < 0
						THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_JUCHU_DATE + NCHAR(13) + '＞' + @FLD_NM_DTL_SHUKKA_YOTEI_DATE
			 END
	WHERE #tmp.ERROR_MSG IS NULL
	/**********************************************
    *日付チェックEND
    **********************************************/

	/**********************************************
    *数値チェックSTART
    **********************************************/
	UPDATE #tmp
	SET #tmp.ERROR_MSG = 
		CASE --ロット数
			 WHEN LOT_NUM IS NOT NULL AND isnumeric(LOT_NUM) != 1
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_LOT_NUM
			 --バラ数
			 WHEN BARA_NUM IS NOT NULL AND isnumeric(BARA_NUM) != 1
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_BARA_NUM
			 --掛率(%):サンプルの場合、チェック対象外
			 WHEN SAMPLE_SHUKKA_FLG = 0 AND KAKERITU IS NOT NULL AND isnumeric(KAKERITU) != 1
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_KAKERITU
			 --取引先通貨単価:サンプルの場合、チェック対象外
			 WHEN SAMPLE_SHUKKA_FLG = 0 AND TORIHIKISAKI_TUKA_TANKA IS NOT NULL AND isnumeric(TORIHIKISAKI_TUKA_TANKA) != 1 
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_TORIHIKISAKI_TUKA_TANKA
			 --レート
			 WHEN RATE IS NOT NULL AND isnumeric(RATE) != 1
					THEN @ERR_MSG_INCORRECT_DATA + @FLD_NM_RATE
		END
	WHERE #tmp.ERROR_MSG IS NULL
	/**********************************************
    *数値チェックEND
    **********************************************/

	/**********************************************
    *数値範囲チェックSTART
    **********************************************/
	UPDATE #tmp
	SET #tmp.ERROR_MSG = 
		CASE --ロット数
			 WHEN (CONVERT(float,LOT_NUM) < 0 
         			OR (@SURYO_KETA='3' AND 9999.999< CONVERT(float,LOT_NUM))
         			OR (@SURYO_KETA='2' AND 9999.99< CONVERT(float,LOT_NUM))
         			OR (@SURYO_KETA='1' AND 9999.9< CONVERT(float,LOT_NUM))
         			OR (@SURYO_KETA='0' AND 9999< CONVERT(float,LOT_NUM)))
						THEN @ERR_MSG_INVALID_NUMBER + @FLD_NM_LOT_NUM
			 --バラ数
			 WHEN (CONVERT(float,BARA_NUM) < 0 
         			OR (@SURYO_KETA='3' AND 9999.999< CONVERT(float,BARA_NUM))
         			OR (@SURYO_KETA='2' AND 9999.99< CONVERT(float,BARA_NUM))
         			OR (@SURYO_KETA='1' AND 9999.9< CONVERT(float,BARA_NUM))
         			OR (@SURYO_KETA='0' AND 999999< CONVERT(float,BARA_NUM)))
						THEN @ERR_MSG_INVALID_NUMBER + @FLD_NM_BARA_NUM
			 --掛率(%)
			 WHEN (CONVERT(float,KAKERITU) < 0
					OR (99.9<CONVERT(float, KAKERITU)))
						THEN @ERR_MSG_INVALID_NUMBER + @FLD_NM_KAKERITU
			 --取引先通貨単価(金額のマイナス登録は問題なし)
			 WHEN (9999999999.999 < CONVERT(float,TORIHIKISAKI_TUKA_TANKA))
						THEN @ERR_MSG_INVALID_NUMBER + @FLD_NM_TORIHIKISAKI_TUKA_TANKA
			 --レート
			 WHEN (CONVERT(float,RATE) < 0
					OR (99999.999<CONVERT(float, RATE)))
						THEN @ERR_MSG_INVALID_NUMBER + @FLD_NM_RATE
		END
	WHERE #tmp.ERROR_MSG IS NULL
	/**********************************************
    *数値範囲チェックEND
    **********************************************/

	/**********************************************
    *マスタコード値チェックSTART
    **********************************************/
	--得意先コード
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_INCORRECT_CODE + @FLD_NM_TOKUISAKI_CD
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.TOKUISAKI_CD IS NOT NULL
    AND NOT EXISTS (SELECT * FROM BC_MST_TOKUISAKI TOKUI
                    WHERE TOKUI.KAISHA_CD = @KAISHA_CD
                    AND TOKUI.TOKUISAKI_CD = #tmp.TOKUISAKI_CD
					AND TOKUI.MUKOU_FLG = 0
                    AND TOKUI.DEL_FLG = 0
                   )

	
	--請求先コード
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_INCORRECT_CODE + @FLD_NM_SEIKYUSAKI_CD
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.SEIKYUSAKI_CD IS NOT NULL
    AND NOT EXISTS (SELECT * FROM BC_MST_SEIKYUSAKI SEIKYU
                    WHERE SEIKYU.KAISHA_CD = @KAISHA_CD
                    AND SEIKYU.SEIKYUSAKI_CD = #tmp.SEIKYUSAKI_CD
					AND SEIKYU.MUKOU_FLG = 0
                    AND SEIKYU.DEL_FLG = 0
                   )

	--倉庫コード(ヘッダ)
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_INCORRECT_CODE + @FLD_NM_SOKO_CD
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.SOKO_CD IS NOT NULL
    AND NOT EXISTS (SELECT * FROM BC_MST_SOKO SOKO
                    WHERE SOKO.KAISHA_CD = @KAISHA_CD
                    AND SOKO.SOKO_CD = #tmp.SOKO_CD
					AND SOKO.MUKOU_FLG = 0
                    AND SOKO.DEL_FLG = 0
                   )

	--預け／預かり／移動倉庫コード
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_INCORRECT_CODE + @FLD_NM_AZUKE_AZUKARI_IDO_SOKO_CD
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.AZUKE_AZUKARI_IDO_SOKO_CD IS NOT NULL
    AND NOT EXISTS (SELECT * FROM BC_MST_SOKO SOKO
                    WHERE SOKO.KAISHA_CD = @KAISHA_CD
                    AND SOKO.SOKO_CD = #tmp.AZUKE_AZUKARI_IDO_SOKO_CD
					AND SOKO.MUKOU_FLG = 0
                    AND SOKO.DEL_FLG = 0
				   )

	--担当者コード
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_INCORRECT_CODE + @FLD_NM_TANTOSHA_CD
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.TANTOSHA_CD IS NOT NULL
    AND NOT EXISTS (SELECT * FROM BC_MST_SHAIN SHAIN
                    WHERE SHAIN.KAISHA_CD = @KAISHA_CD
                    AND SHAIN.SHAIN_CD = #tmp.TANTOSHA_CD
					AND SHAIN.MUKOU_FLG = 0
                    AND SHAIN.DEL_FLG = 0
				   )

	--部署コード
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_INCORRECT_CODE + @FLD_NM_TANTO_BUSHO_CD
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.TANTO_BUSHO_CD IS NOT NULL
    AND NOT EXISTS (SELECT * FROM BC_MST_BUSHO BUSHO
                    WHERE BUSHO.KAISHA_CD = @KAISHA_CD
                    AND BUSHO.BUSHO_CD = #tmp.TANTO_BUSHO_CD
					AND BUSHO.MUKOU_FLG = 0
                    AND BUSHO.DEL_FLG = 0
				   )

	--プロジェクトコード
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_INCORRECT_CODE + @FLD_NM_PROJECT_CD
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.PROJECT_CD IS NOT NULL
    AND NOT EXISTS (SELECT * FROM BC_MST_PROJECT PROJECT
                    WHERE PROJECT.KAISHA_CD = @KAISHA_CD
                    AND PROJECT.PROJECT_CD = #tmp.PROJECT_CD
					AND PROJECT.MUKOU_FLG = 0
                    AND PROJECT.DEL_FLG = 0
				   )

	--販売エリアコード
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_INCORRECT_CODE + @FLD_NM_HANBAI_AREA_CD
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.HANBAI_AREA_CD IS NOT NULL
    AND NOT EXISTS (SELECT * FROM BC_MST_HANBAI_AREA AREA
                    WHERE AREA.KAISHA_CD = @KAISHA_CD
                    AND AREA.HANBAI_AREA_CD = #tmp.HANBAI_AREA_CD
                    AND AREA.DEL_FLG = 0
				   )

	--倉庫コード(明細)
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_INCORRECT_CODE + @FLD_NM_SOKO_CD
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.DTL_SOKO_CD IS NOT NULL
    AND NOT EXISTS (SELECT * FROM BC_MST_SOKO SOKO
                    WHERE SOKO.KAISHA_CD = @KAISHA_CD
                    AND SOKO.SOKO_CD = #tmp.DTL_SOKO_CD
					AND SOKO.MUKOU_FLG = 0
                    AND SOKO.DEL_FLG = 0
                   )

	--出荷先コード(明細)
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_INCORRECT_CODE + @FLD_NM_SHUKKASAKI_CD
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.DTL_SHUKKASAKI_CD IS NOT NULL
    AND NOT EXISTS (SELECT * FROM BC_MST_SHUKKASAKI SHUKKA
                    WHERE SHUKKA.KAISHA_CD = @KAISHA_CD
                    AND SHUKKA.SHUKKASAKI_CD = #tmp.DTL_SHUKKASAKI_CD
					AND SHUKKA.MUKOU_FLG = 0
                    AND SHUKKA.DEL_FLG = 0
                   )
	/**********************************************
    *マスタコード値チェックEND
    **********************************************/

	/**********************************************
    *コードマスタコード値チェックSTART
    **********************************************/
	--受注区分
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_INCORRECT_CODE + @FLD_NM_JUCHU_KBN
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.JUCHU_KBN IS NOT NULL
    AND NOT EXISTS (SELECT * FROM BC_MST_CODE_KAISHA_BETU CODE
                    WHERE CODE.KAISHA_CD = @KAISHA_CD
					AND CODE.CD_SECTION = 'M00005'
                    AND CODE.CD_KEY = #tmp.JUCHU_KBN
                    AND CODE.DEL_FLG = 0
                   )

	--出庫区分
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_INCORRECT_CODE + @FLD_NM_SHUKKO_KBN
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.SHUKKO_KBN IS NOT NULL
    AND NOT EXISTS (SELECT * FROM BC_MST_CODE_KAISHA_BETU CODE
                    WHERE CODE.KAISHA_CD = @KAISHA_CD
					AND CODE.CD_SECTION = '000004'
                    AND CODE.CD_KEY = #tmp.SHUKKO_KBN
					AND CODE.CD_KEY <> '02'	--直送はエラー
					AND CODE.CD_KEY <> '05'	--返品はエラー
                    AND CODE.DEL_FLG = 0
                   )

	--配送区分
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_INCORRECT_CODE + @FLD_NM_HAISOU_KBN
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.HAISOU_KBN IS NOT NULL
    AND NOT EXISTS (SELECT * FROM BC_MST_CODE_KAISHA_BETU CODE
                    WHERE CODE.KAISHA_CD = @KAISHA_CD
					AND CODE.CD_SECTION = 'M00003'
                    AND CODE.CD_KEY = #tmp.HAISOU_KBN
                    AND CODE.DEL_FLG = 0
                   )

	--決済方法
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_INCORRECT_CODE + @FLD_NM_KESSAI_HOHO
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.KESSAI_HOHO IS NOT NULL
    AND NOT EXISTS (SELECT * FROM BC_MST_CODE_KAISHA_BETU CODE
                    WHERE CODE.KAISHA_CD = @KAISHA_CD
					AND CODE.CD_SECTION = 'M00004'
                    AND CODE.CD_KEY = #tmp.KESSAI_HOHO
                    AND CODE.DEL_FLG = 0
                   )

	--納品区分
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_INCORRECT_CODE + @FLD_NM_NOHIN_KBN
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.NOHIN_KBN IS NOT NULL
    AND NOT EXISTS (SELECT * FROM BC_MST_CODE_KAISHA_BETU CODE
                    WHERE CODE.KAISHA_CD = @KAISHA_CD
					AND CODE.CD_SECTION = 'M00006'
                    AND CODE.CD_KEY = #tmp.NOHIN_KBN
                    AND CODE.DEL_FLG = 0
                   )

	--流通加工区分
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_INCORRECT_CODE + @FLD_NM_RYUTU_KAKOU_KBN
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.RYUTU_KAKOU_KBN IS NOT NULL
    AND NOT EXISTS (SELECT * FROM BC_MST_CODE_KAISHA_BETU CODE
                    WHERE CODE.KAISHA_CD = @KAISHA_CD
					AND CODE.CD_SECTION = 'M00007'
                    AND CODE.CD_KEY = #tmp.RYUTU_KAKOU_KBN
                    AND CODE.DEL_FLG = 0
                   )

	--推定確定区分
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_INCORRECT_CODE + @FLD_NM_SUITEI_KAKUTEI_KBN
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.SUITEI_KAKUTEI_KBN IS NOT NULL
    AND NOT EXISTS (SELECT * FROM BC_MST_CODE_KAISHA_BETU CODE
                    WHERE CODE.KAISHA_CD = @KAISHA_CD
					AND CODE.CD_SECTION = '000003'
                    AND CODE.CD_KEY = #tmp.SUITEI_KAKUTEI_KBN
                    AND CODE.DEL_FLG = 0
                   )

	--引当状態
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_INCORRECT_CODE + @FLD_NM_HIKIATE_STATE
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.HIKIATE_STATE IS NOT NULL
    AND NOT EXISTS (SELECT * FROM BC_MST_CODE_KAISHA_BETU CODE
                    WHERE CODE.KAISHA_CD = @KAISHA_CD
					AND CODE.CD_SECTION = '000005'
                    AND CODE.CD_KEY = #tmp.HIKIATE_STATE
					AND CODE.CD_KEY NOT IN ('04', '05')	--発注、不足時発注はエラー
                    AND CODE.DEL_FLG = 0
                   )
	/**********************************************
    *コードマスタコード値チェックEND
    **********************************************/

	/**********************************************
    *引当状態チェックSTART
    **********************************************/
	--預かり売上、預け出庫の場合、引当状態は「引当」であること
	--移動の場合「未」「引当」であること
	--予約伝票の場合、引当状態は「未」「引当」「一括引当」であること
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_CANNOT_USE_CODE + @FLD_NM_HIKIATE_STATE
	WHERE #tmp.ERROR_MSG IS NULL
	AND ((#tmp.SHUKKO_KBN IN ('03', '06') AND #tmp.HIKIATE_STATE <> '02')
			OR (#tmp.JUCHU_KBN = '03' AND #tmp.HIKIATE_STATE NOT IN ('01', '02'))
			OR (#tmp.JUCHU_KBN ='02' AND #tmp.HIKIATE_STATE NOT IN ('01', '02', '03')))

	--引当状態「未」「一括引当」の場合、推定確定区分が「推定」であること
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_CANNOT_USE_CODE + @FLD_NM_HIKIATE_STATE + NCHAR(13) + @FLD_NM_SUITEI_KAKUTEI_KBN
	WHERE #tmp.ERROR_MSG IS NULL
	AND #tmp.HIKIATE_STATE IN ('01', '03')
	AND #tmp.SUITEI_KAKUTEI_KBN <> '01'
	/**********************************************
    *引当状態チェックEND
    **********************************************/

	/**********************************************
    *課税区分チェックSTART
    **********************************************/
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_INCORRECT_CODE + @FLD_NM_KAZEI_KBN
	WHERE #tmp.ERROR_MSG IS NULL
	AND #tmp.KAZEI_KBN IS NOT NULL
	AND NOT EXISTS (SELECT CD_KEY
					--課税非課税の他、税率指定を考慮
	                FROM (SELECT CD_KEY
						  FROM BC_MST_CODE_KAISHA_BETU
						  WHERE KAISHA_CD = @KAISHA_CD
						  AND CD_SECTION = '000051' --課税区分
		 				  AND SUB_KEY = 0 --0固定
						  AND DEL_FLG = 0
						  UNION ALL 
						  SELECT DISTINCT '9' + RIGHT('00' + CAST(CAST((TAX_RATE * 100)AS tinyint) AS nvarchar),2) AS CD_KEY --先頭に9を付加
						  FROM BC_MST_TAX MTAX
						  WHERE MTAX.KAISHA_CD = @KAISHA_CD
						  AND DATEDIFF(dd, (SELECT VALUE
											FROM BC_MST_SYSTEM
											WHERE KAISHA_CD = @KAISHA_CD
		    								AND BUNRUI_NM = 'CO'
											AND VALUE_NM = 'TAX_SITEI_START_DATE')
									   ,MTAX.START_DATE) > 0
						  AND MTAX.DEL_FLG = 0
						 ) TAX_CD   
					 WHERE TAX_CD.CD_KEY = #tmp.KAZEI_KBN
					)
	/**********************************************
    *課税区分チェックEND
    **********************************************/

	/**********************************************
    *予約引当時の整合性チェックSTART
    **********************************************/
	UPDATE #tmp
	SET ERROR_MSG = 
			CASE --伝票が削除または取消されているOR予約伝票ではないOR存在しない
				 WHEN JHDR_Y.CANCEL_FLG = 1 OR JHDR_Y.DEL_FLG = 1 OR JHDR_EX_Y.JUCHU_KBN <> '02' OR JDTL_Y.DEL_FLG = 1
						OR JDTL_Y.JUCHU_NO IS NULL OR JDTL_Y.JUCHU_ENO IS NULL
						THEN @ERR_MSG_CANNOT_USE_YOYAKU
				 --予約の出荷予定日 > 受注の出荷予定日
				 WHEN DATEDIFF(DAY, JDTL_Y.SHUKKA_YOTEI_DATE, #tmp.DTL_SHUKKA_YOTEI_DATE) < 0
						THEN @ERR_MSG_CANNOT_USE_YOYAKU + @FLD_NM_DTL_SHUKKA_YOTEI_DATE
				 --品目SEQが異なる
				 WHEN #tmp.HINMOKU_SEQ <> JDTL_Y.HINMOKU_SEQ
						THEN @ERR_MSG_CANNOT_USE_YOYAKU + @FLD_NM_HINMOKU
			END
	FROM #tmp
	LEFT JOIN HK_TBL_JUCHU_HDR JHDR_Y
		ON JHDR_Y.KAISHA_CD = @KAISHA_CD
		AND #tmp.YOYAKU_DENPYO_NO = JHDR_Y.JUCHU_NO
	LEFT JOIN HK_TBL_JUCHU_HDR_EX JHDR_EX_Y
		ON JHDR_EX_Y.KAISHA_CD = JHDR_Y.KAISHA_CD
		AND JHDR_EX_Y.JUCHU_NO = JHDR_Y.JUCHU_NO
	LEFT JOIN HK_TBL_JUCHU_DTL JDTL_Y
		ON JDTL_Y.KAISHA_CD = JHDR_Y.KAISHA_CD
		AND JDTL_Y.JUCHU_NO = JHDR_Y.JUCHU_NO
		AND JDTL_Y.JUCHU_ENO = #tmp.YOYAKU_DENPYO_ENO
	WHERE #tmp.ERROR_MSG IS NULL
	AND #tmp.JUCHU_KBN IN ('01', '03')
	AND #tmp.YOYAKU_DENPYO_NO IS NOT NULL
	AND #tmp.YOYAKU_DENPYO_ENO IS NOT NULL
	/**********************************************
    *予約引当時の整合性チェックEND
    **********************************************/
	/*===============================レコード単位エラーチェックEND===============================*/

	/*===============================レコードを伝票単位に纏めるSTART===============================*/
	--ヘッダが一致するものに対し仮IDを付与
	--連続して出現しないものを区別するため、行番号からヘッダでグルーピングしたパーティション行番号を引く
	UPDATE #tmp
	SET TMP_ID = tmp2.TMP_ID
	FROM (SELECT (LINE_NO - ROW_NUMBER() OVER(PARTITION BY DENPYO_NO
														  ,JUCHU_KBN
														  ,JUCHU_DATE
														  ,SHUKKO_KBN
														  ,TOKUISAKI_CD
														  ,SHUKKASAKI_CD
														  ,SEIKYUSAKI_CD
														  ,SOKO_CD
														  ,AZUKE_AZUKARI_IDO_SOKO_CD
														  ,SHUKKA_YOTEI_DATE
														  ,SHITEI_NOHIN_DATE
														  ,SHITEI_NOHIN_JIKOKU
														  ,HAISOU_KBN
														  ,KESSAI_HOHO
														  ,HDR_GEDAIMACHI_FLG
														  ,SAMPLE_SHUKKA_FLG
														  ,HIKIATE_CHOSEI_FUYO_FLG
														  ,HDR_SEIKYU_KIJUN_DATE
														  ,TOKUISAKI_DENPYO_NO
														  ,TOKUISAKI_HACCHU_NO
														  ,BUNRUI_CD
														  ,URIBA_NM
														  ,TANTOSHA_NM
														  ,NAISEN_NO
														  ,TANTOSHA_CD
														  ,TANTO_BUSHO_CD
														  ,NOHIN_KBN
														  ,RYUTU_KAKOU_KBN
														  ,BIKO
														  ,JUCHU_COMMENT
														  ,SOKO_COMMENT
														  ,PROJECT_CD
														  ,HANBAI_AREA_CD
														  ,YOYAKU_KAIHO_KIGEN
														  ,HINMOKU					
														  ,LOT_NUM					
														  ,BARA_NUM				
														  ,SUITEI_KAKUTEI_KBN		
														  ,KAKERITU				
														  ,HIKIATE_STATE			
														  ,DTL_GEDAIMACHI_FLG		
														  ,DTL_SOKO_CD				
														  ,TEKIYO					
														  ,DTL_SHUKKASAKI_CD		
														  ,DTL_SHUKKA_YOTEI_DATE	
														  ,DTL_SHITEI_NOHIN_DATE	
														  ,DTL_SEIKYU_KIJUN_DATE	
														  ORDER BY LINE_NO)
				 ) AS TMP_ID
				 ,LINE_NO
		  FROM #tmp
		 ) AS tmp2
	WHERE #tmp.LINE_NO = tmp2.LINE_NO

	--#tmpHdrにInsert
	--TMP_IDとヘッダ情報でグルーピングし、GROUP_KEYに行番号を設定
	INSERT INTO #tmpHdr
	(TMP_ID
	,GROUP_KEY
	,DENPYO_NO
	,HACCHU_NO
	,SOKO_IDO_NO
	,JUCHU_KBN
	,JUCHU_DATE
	,SHUKKO_KBN
	,TOKUISAKI_CD
	,SHUKKASAKI_CD
	,SEIKYUSAKI_CD
	,SOKO_CD
	,AZUKE_AZUKARI_IDO_SOKO_CD
	,SHUKKA_YOTEI_DATE
	,SHITEI_NOHIN_DATE
	,SHITEI_NOHIN_JIKOKU
	,HAISOU_KBN
	,KESSAI_HOHO
	,HDR_GEDAIMACHI_FLG
	,SAMPLE_SHUKKA_FLG
	,HIKIATE_CHOSEI_FUYO_FLG
	,HDR_SEIKYU_KIJUN_DATE
	,TOKUISAKI_DENPYO_NO
	,TOKUISAKI_HACCHU_NO
	,BUNRUI_CD
	,URIBA_NM
	,TANTOSHA_NM
	,NAISEN_NO
	,TANTOSHA_CD
	,TANTO_BUSHO_CD
	,NOHIN_KBN
	,RYUTU_KAKOU_KBN
	,BIKO
	,JUCHU_COMMENT
	,SOKO_COMMENT
	,PROJECT_CD
	,HANBAI_AREA_CD
	,YOYAKU_KAIHO_KIGEN
	,HINMOKU					
	,LOT_NUM					
	,BARA_NUM				
	,SUITEI_KAKUTEI_KBN		
	,KAKERITU				
	,HIKIATE_STATE			
	,DTL_GEDAIMACHI_FLG		
	,DTL_SOKO_CD				
	,TEKIYO					
	,DTL_SHUKKASAKI_CD		
	,DTL_SHUKKA_YOTEI_DATE	
	,DTL_SHITEI_NOHIN_DATE	
	,DTL_SEIKYU_KIJUN_DATE	
	)
	SELECT TMP_ID
		   ,ROW_NUMBER() OVER(ORDER BY TMP_ID)
		   ,DENPYO_NO
		   ,NULL		--発注NO
		   ,NULL		--倉庫移動NO
		   ,JUCHU_KBN
		   ,JUCHU_DATE
		   ,SHUKKO_KBN
		   ,TOKUISAKI_CD
		   ,SHUKKASAKI_CD
		   ,SEIKYUSAKI_CD
		   ,SOKO_CD
		   ,AZUKE_AZUKARI_IDO_SOKO_CD
		   ,SHUKKA_YOTEI_DATE
		   ,SHITEI_NOHIN_DATE
		   ,SHITEI_NOHIN_JIKOKU
		   ,HAISOU_KBN
		   ,KESSAI_HOHO
		   ,HDR_GEDAIMACHI_FLG
		   ,SAMPLE_SHUKKA_FLG
		   ,HIKIATE_CHOSEI_FUYO_FLG
		   ,HDR_SEIKYU_KIJUN_DATE
		   ,TOKUISAKI_DENPYO_NO
		   ,TOKUISAKI_HACCHU_NO
		   ,BUNRUI_CD
		   ,URIBA_NM
		   ,TANTOSHA_NM
		   ,NAISEN_NO
		   ,TANTOSHA_CD
		   ,TANTO_BUSHO_CD
		   ,NOHIN_KBN
		   ,RYUTU_KAKOU_KBN
		   ,BIKO
		   ,JUCHU_COMMENT
		   ,SOKO_COMMENT
		   ,PROJECT_CD
		   ,HANBAI_AREA_CD
		   ,YOYAKU_KAIHO_KIGEN
		   ,HINMOKU					
		   ,LOT_NUM					
		   ,BARA_NUM				
		   ,SUITEI_KAKUTEI_KBN		
		   ,KAKERITU				
		   ,HIKIATE_STATE			
		   ,DTL_GEDAIMACHI_FLG		
		   ,DTL_SOKO_CD				
		   ,TEKIYO					
		   ,DTL_SHUKKASAKI_CD		
		   ,DTL_SHUKKA_YOTEI_DATE	
		   ,DTL_SHITEI_NOHIN_DATE	
		   ,DTL_SEIKYU_KIJUN_DATE	
	FROM #tmp
	GROUP BY TMP_ID
			,DENPYO_NO
			,JUCHU_KBN
			,JUCHU_DATE
			,SHUKKO_KBN
			,TOKUISAKI_CD
			,SHUKKASAKI_CD
			,SEIKYUSAKI_CD
			,SOKO_CD
			,AZUKE_AZUKARI_IDO_SOKO_CD
			,SHUKKA_YOTEI_DATE
			,SHITEI_NOHIN_DATE
			,SHITEI_NOHIN_JIKOKU
			,HAISOU_KBN
			,KESSAI_HOHO
			,HDR_GEDAIMACHI_FLG
			,SAMPLE_SHUKKA_FLG
			,HIKIATE_CHOSEI_FUYO_FLG
			,HDR_SEIKYU_KIJUN_DATE
			,TOKUISAKI_DENPYO_NO
			,TOKUISAKI_HACCHU_NO
			,BUNRUI_CD
			,URIBA_NM
			,TANTOSHA_NM
			,NAISEN_NO
			,TANTOSHA_CD
			,TANTO_BUSHO_CD
			,NOHIN_KBN
			,RYUTU_KAKOU_KBN
			,BIKO
			,JUCHU_COMMENT
			,SOKO_COMMENT
			,PROJECT_CD
			,HANBAI_AREA_CD
			,YOYAKU_KAIHO_KIGEN
			,HINMOKU					
			,LOT_NUM					
			,BARA_NUM				
			,SUITEI_KAKUTEI_KBN		
			,KAKERITU				
			,HIKIATE_STATE			
			,DTL_GEDAIMACHI_FLG		
			,DTL_SOKO_CD				
			,TEKIYO					
			,DTL_SHUKKASAKI_CD		
			,DTL_SHUKKA_YOTEI_DATE	
			,DTL_SHITEI_NOHIN_DATE	
			,DTL_SEIKYU_KIJUN_DATE	
	--#tmpHdrのGROUP_KEYを#tmpのGROUP_KEYに設定
	UPDATE #tmp
	SET GROUP_KEY = #tmpHdr.GROUP_KEY
	FROM #tmpHdr
	WHERE #tmp.TMP_ID = #tmpHdr.TMP_ID
	AND ISNULL(#tmp.DENPYO_NO, '') = ISNULL(#tmpHdr.DENPYO_NO, '')
	AND ISNULL(#tmp.JUCHU_KBN, '') = ISNULL(#tmpHdr.JUCHU_KBN, '')
	AND ISNULL(#tmp.JUCHU_DATE, '') = ISNULL(#tmpHdr.JUCHU_DATE, '')
	AND ISNULL(#tmp.SHUKKO_KBN, '') = ISNULL(#tmpHdr.SHUKKO_KBN, '')
	AND ISNULL(#tmp.TOKUISAKI_CD, '') = ISNULL(#tmpHdr.TOKUISAKI_CD, '')
	AND ISNULL(#tmp.SHUKKASAKI_CD, '') = ISNULL(#tmpHdr.SHUKKASAKI_CD, '')
	AND ISNULL(#tmp.SEIKYUSAKI_CD, '') = ISNULL(#tmpHdr.SEIKYUSAKI_CD, '')
	AND ISNULL(#tmp.SOKO_CD, '') = ISNULL(#tmpHdr.SOKO_CD, '')
	AND ISNULL(#tmp.AZUKE_AZUKARI_IDO_SOKO_CD, '') = ISNULL(#tmpHdr.AZUKE_AZUKARI_IDO_SOKO_CD, '')
	AND ISNULL(#tmp.SHUKKA_YOTEI_DATE, '') = ISNULL(#tmpHdr.SHUKKA_YOTEI_DATE, '')
	AND ISNULL(#tmp.SHITEI_NOHIN_DATE, '') = ISNULL(#tmpHdr.SHITEI_NOHIN_DATE, '')
	AND ISNULL(#tmp.SHITEI_NOHIN_JIKOKU, '') = ISNULL(#tmpHdr.SHITEI_NOHIN_JIKOKU, '')
	AND ISNULL(#tmp.HAISOU_KBN, '') = ISNULL(#tmpHdr.HAISOU_KBN, '')
	AND ISNULL(#tmp.KESSAI_HOHO, '') = ISNULL(#tmpHdr.KESSAI_HOHO, '')
	AND ISNULL(#tmp.HDR_GEDAIMACHI_FLG, '') = ISNULL(#tmpHdr.HDR_GEDAIMACHI_FLG, '')
	AND ISNULL(#tmp.SAMPLE_SHUKKA_FLG, '') = ISNULL(#tmpHdr.SAMPLE_SHUKKA_FLG, '')
	AND ISNULL(#tmp.HIKIATE_CHOSEI_FUYO_FLG, '') = ISNULL(#tmpHdr.HIKIATE_CHOSEI_FUYO_FLG, '')
	AND ISNULL(#tmp.HDR_SEIKYU_KIJUN_DATE, '') = ISNULL(#tmpHdr.HDR_SEIKYU_KIJUN_DATE, '')
	AND ISNULL(#tmp.TOKUISAKI_DENPYO_NO, '') = ISNULL(#tmpHdr.TOKUISAKI_DENPYO_NO, '')
	AND ISNULL(#tmp.TOKUISAKI_HACCHU_NO, '') = ISNULL(#tmpHdr.TOKUISAKI_HACCHU_NO, '')
	AND ISNULL(#tmp.BUNRUI_CD, '') = ISNULL(#tmpHdr.BUNRUI_CD, '')
	AND ISNULL(#tmp.URIBA_NM, '') = ISNULL(#tmpHdr.URIBA_NM, '')
	AND ISNULL(#tmp.TANTOSHA_NM, '') = ISNULL(#tmpHdr.TANTOSHA_NM, '')
	AND ISNULL(#tmp.NAISEN_NO, '') = ISNULL(#tmpHdr.NAISEN_NO, '')
	AND ISNULL(#tmp.TANTOSHA_CD, '') = ISNULL(#tmpHdr.TANTOSHA_CD, '')
	AND ISNULL(#tmp.TANTO_BUSHO_CD, '') = ISNULL(#tmpHdr.TANTO_BUSHO_CD, '')
	AND ISNULL(#tmp.NOHIN_KBN, '') = ISNULL(#tmpHdr.NOHIN_KBN, '')
	AND ISNULL(#tmp.RYUTU_KAKOU_KBN, '') = ISNULL(#tmpHdr.RYUTU_KAKOU_KBN, '')
	AND ISNULL(#tmp.BIKO, '') = ISNULL(#tmpHdr.BIKO, '')
	AND ISNULL(#tmp.JUCHU_COMMENT, '') = ISNULL(#tmpHdr.JUCHU_COMMENT, '')
	AND ISNULL(#tmp.SOKO_COMMENT, '') = ISNULL(#tmpHdr.SOKO_COMMENT, '')
	AND ISNULL(#tmp.PROJECT_CD, '') = ISNULL(#tmpHdr.PROJECT_CD, '')
	AND ISNULL(#tmp.HANBAI_AREA_CD, '') = ISNULL(#tmpHdr.HANBAI_AREA_CD, '')
	AND ISNULL(#tmp.YOYAKU_KAIHO_KIGEN, '') = ISNULL(#tmpHdr.YOYAKU_KAIHO_KIGEN, '')
	AND ISNULL(#tmp.HINMOKU, '') = ISNULL(#tmpHdr.HINMOKU, '')
	AND ISNULL(#tmp.LOT_NUM, '') = ISNULL(#tmpHdr.LOT_NUM, '')
	AND ISNULL(#tmp.BARA_NUM, '') = ISNULL(#tmpHdr.BARA_NUM, '')
	AND ISNULL(#tmp.SUITEI_KAKUTEI_KBN, '') = ISNULL(#tmpHdr.SUITEI_KAKUTEI_KBN, '')
	AND ISNULL(#tmp.KAKERITU, '') = ISNULL(#tmpHdr.KAKERITU, '')
	AND ISNULL(#tmp.HIKIATE_STATE, '') = ISNULL(#tmpHdr.HIKIATE_STATE, '')
	AND ISNULL(#tmp.DTL_GEDAIMACHI_FLG, '') = ISNULL(#tmpHdr.DTL_GEDAIMACHI_FLG, '')
	AND ISNULL(#tmp.DTL_SOKO_CD, '') = ISNULL(#tmpHdr.DTL_SOKO_CD, '')
	AND ISNULL(#tmp.TEKIYO, '') = ISNULL(#tmpHdr.TEKIYO, '')
	AND ISNULL(#tmp.DTL_SHUKKASAKI_CD, '') = ISNULL(#tmpHdr.DTL_SHUKKASAKI_CD, '')
	AND ISNULL(#tmp.DTL_SHUKKA_YOTEI_DATE, '') = ISNULL(#tmpHdr.DTL_SHUKKA_YOTEI_DATE, '')
	AND ISNULL(#tmp.DTL_SHITEI_NOHIN_DATE, '') = ISNULL(#tmpHdr.DTL_SHITEI_NOHIN_DATE, '')
	AND ISNULL(#tmp.DTL_SEIKYU_KIJUN_DATE, '') = ISNULL(#tmpHdr.DTL_SEIKYU_KIJUN_DATE, '')	

	--※GROUP_KEYが同一のものが一つの伝票の単位
	/*===============================レコードを伝票単位に纏めるEND===============================*/

	/*===============================伝票単位のエラーチェックSTART===============================*/
	/**********************************************
    *注残なし条件チェックSTART
    **********************************************/
	--①出荷予定日(明細)チェック
	--出荷予定日が異なる場合エラー
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_JUCHU_ZAM_KANRI_DATE + @FLD_NM_DTL_SHUKKA_YOTEI_DATE
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.JUCHU_KBN IN ('01', '03')
    AND EXISTS (SELECT *
				FROM (SELECT T.LINE_NO
							,T.GROUP_KEY
							,T.DTL_SHUKKA_YOTEI_DATE
				      FROM #tmp T
					  INNER JOIN BC_MST_TOKUISAKI_EX TOKUI
						ON T.TOKUISAKI_CD = TOKUI.TOKUISAKI_CD
						AND TOKUI.JUCHU_ZAN_KANRI_FLG = 0
					  WHERE T.ERROR_MSG IS NULL
					  AND TOKUI.KAISHA_CD = @KAISHA_CD
					  ) AS tmp2
                WHERE tmp2.GROUP_KEY = #tmp.GROUP_KEY
                AND tmp2.DTL_SHUKKA_YOTEI_DATE <> #tmp.DTL_SHUKKA_YOTEI_DATE
                AND tmp2.LINE_NO < #tmp.LINE_NO
			   )

	--②指定納品日(明細)チェック
	--指定納品日(明細)が異なる場合エラー
	--指定納品日は必須項目ではないので、チェック時null変換実施
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_JUCHU_ZAM_KANRI_DATE + @FLD_NM_SHITEI_NOHIN_DATE
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.JUCHU_KBN IN ('01', '03')
    AND EXISTS (SELECT *
				FROM (SELECT T.LINE_NO
							,T.GROUP_KEY
							,T.DTL_SHITEI_NOHIN_DATE
				      FROM #tmp T
					  INNER JOIN BC_MST_TOKUISAKI_EX TOKUI
						ON T.TOKUISAKI_CD = TOKUI.TOKUISAKI_CD
						AND TOKUI.JUCHU_ZAN_KANRI_FLG = 0
					  WHERE T.ERROR_MSG IS NULL
					  AND TOKUI.KAISHA_CD = @KAISHA_CD
					 ) AS tmp2
                WHERE tmp2.GROUP_KEY = #tmp.GROUP_KEY
                AND  ISNULL(tmp2.DTL_SHITEI_NOHIN_DATE, '') <> ISNULL(#tmp.DTL_SHITEI_NOHIN_DATE, '')
                AND tmp2.LINE_NO < #tmp.LINE_NO
			   )

	--③請求基準(明細)チェック
	--請求基準日(明細)が異なる場合エラー
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_JUCHU_ZAM_KANRI_DATE + @FLD_NM_SEIKYU_KIJUN_DATE
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.JUCHU_KBN IN ('01', '03')
    AND EXISTS (SELECT *
				FROM (SELECT T.LINE_NO
							,T.GROUP_KEY
							,T.DTL_SEIKYU_KIJUN_DATE
				      FROM #tmp T
					  INNER JOIN BC_MST_TOKUISAKI_EX TOKUI
						ON T.TOKUISAKI_CD = TOKUI.TOKUISAKI_CD
						AND TOKUI.JUCHU_ZAN_KANRI_FLG = 0
					  WHERE T.ERROR_MSG IS NULL
					  AND TOKUI.KAISHA_CD = @KAISHA_CD
					 ) AS tmp2
                WHERE tmp2.GROUP_KEY = #tmp.GROUP_KEY
                AND  tmp2.DTL_SEIKYU_KIJUN_DATE <> #tmp.DTL_SEIKYU_KIJUN_DATE
                AND tmp2.LINE_NO < #tmp.LINE_NO
			   )

	--④出荷先(明細)が異なる場合エラー
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_JUCHU_ZAM_KANRI_SHUKKASAKI
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.JUCHU_KBN IN ('01', '03')
    AND EXISTS (SELECT *
				FROM (SELECT T.LINE_NO
							,T.GROUP_KEY
							,T.DTL_SHUKKASAKI_CD
				      FROM #tmp T
					  INNER JOIN BC_MST_TOKUISAKI_EX TOKUI
						ON T.TOKUISAKI_CD = TOKUI.TOKUISAKI_CD
						AND TOKUI.JUCHU_ZAN_KANRI_FLG = 0
					  WHERE T.ERROR_MSG IS NULL
					  AND TOKUI.KAISHA_CD = @KAISHA_CD
					 ) AS tmp2
                WHERE tmp2.GROUP_KEY = #tmp.GROUP_KEY
                AND  tmp2.DTL_SHUKKASAKI_CD <> #tmp.DTL_SHUKKASAKI_CD
                AND tmp2.LINE_NO < #tmp.LINE_NO
			   )
	/**********************************************
    *注残なし条件チェックEND
    **********************************************/

	/**********************************************
    *出荷先・出荷予定日と請求基準日のチェックSTART
    **********************************************/
	--出荷先・出荷予定日が同一の場合、請求基準日も同一であること
	UPDATE #tmp
    SET #tmp.ERROR_MSG = @ERR_MSG_SEIKYUKIJUN_DATE
    FROM #tmp
    WHERE #tmp.ERROR_MSG IS NULL
    AND #tmp.JUCHU_KBN = '01'
    AND EXISTS (SELECT *
				FROM #tmp tmp2
                WHERE tmp2.GROUP_KEY = #tmp.GROUP_KEY
				AND tmp2.ERROR_MSG IS NULL
                AND tmp2.DTL_SHUKKASAKI_CD = #tmp.DTL_SHUKKASAKI_CD
				AND tmp2.DTL_SHUKKA_YOTEI_DATE = #tmp.DTL_SHUKKA_YOTEI_DATE
				AND tmp2.DTL_SEIKYU_KIJUN_DATE <> #tmp.DTL_SEIKYU_KIJUN_DATE
                AND tmp2.LINE_NO < #tmp.LINE_NO
			   )
	/**********************************************
    *出荷先・出荷予定日と請求基準日のチェックSTART
    **********************************************/
	--明細の登録件数チェック(1伝票に対し999件まで)
	UPDATE #tmp
	SET #tmp.ERROR_MSG = @ERR_MSG_DTL_COUNT_OVER + '：' 
						+ '行番号' + CONVERT(NVARCHAR, tmpCnt.MIN_LINE) + '～' + '行番号' + CONVERT(NVARCHAR, tmpCnt.MAX_LINE)
	FROM #tmp
	INNER JOIN (SELECT #tmp.GROUP_KEY
					  ,MIN(#tmp.LINE_NO) AS MIN_LINE
					  ,MAX(#tmp.LINE_NO) AS MAX_LINE
	            FROM #tmp
			    GROUP BY #tmp.GROUP_KEY
			    HAVING COUNT(*) > 999
			  ) tmpCnt
		ON #tmp.GROUP_KEY = tmpCnt.GROUP_KEY
		AND #tmp.LINE_NO = tmpCnt.MIN_LINE
	WHERE #tmp.ERROR_MSG IS NULL

	/*===============================伝票単位のエラーチェックEND===============================*/

	/*===============================数量引当START===============================*/
	CREATE TABLE #tmpHikiate
    (KBN					INT
	,TOKUISAKI_CD			NVARCHAR(15)
	,PARENT_TOKUISAKI_CD	NVARCHAR(15)
	,SOKO_CD				NVARCHAR(15)
	,HINMOKU_SEQ			DECIMAL(10)
	,YOYAKU_JUCHU_NO		NVARCHAR(15)
	,YOYAKU_JUCHU_ENO		DECIMAL(3)
	,SHUKKA_YOTEI_DATE		DATETIME
	,NYUKA_YOTEI_NO			NVARCHAR(16)
	,NYUKA_YOTEI_DATE		DATETIME
	,ZAIKO_SEQ				DECIMAL(10)
	,ZAIKO_TOKUISAKI		NVARCHAR(15)
	,SHUKKA_KANO_DATE		DATETIME
	,SURYO					DECIMAL(13, 3)
	)

	--数量引当用の変数設定
	DECLARE @LINE_NO			DECIMAL(6)
		   ,@JUCHU_KBN			NVARCHAR(2)
		   ,@TOKUISAKI_CD		NVARCHAR(15)
		   ,@SOKO_CD			NVARCHAR(15)
		   ,@HINMOKU_SEQ		DECIMAL(10)
		   ,@SHUKKA_YOTEI_DATE	DATETIME
		   ,@YOYAKU_DENPYO_NO	NVARCHAR(15)
		   ,@YOYAKU_DENPYO_ENO	DECIMAL(3)
		   ,@SHUKKO_KBN			NVARCHAR(2)

	/*********************************************************************************
	*引当可能数の詳細情報を取得
	*出荷予定は数量を引当る場合に考慮するので、引当可能数詳細情報を取得する際は考慮しない
	**********************************************************************************/
	DECLARE HIKIATE_CUR CURSOR FOR
	SELECT DISTINCT 
		   TOKUISAKI_CD
		  ,DTL_SOKO_CD
		  ,HINMOKU_SEQ
		  ,YOYAKU_DENPYO_NO
		  ,YOYAKU_DENPYO_ENO
	FROM #tmp
	
	OPEN HIKIATE_CUR
	FETCH NEXT FROM HIKIATE_CUR
	INTO @TOKUISAKI_CD
		,@SOKO_CD
		,@HINMOKU_SEQ
		,@YOYAKU_DENPYO_NO
		,@YOYAKU_DENPYO_ENO
	WHILE @@FETCH_STATUS = 0
	BEGIN
		
		INSERT INTO #tmpHikiate
		EXEC GetHikiateKanoSuryoDetail_Ex
		@KAISHA_CD
		,@TOKUISAKI_CD
		,@SOKO_CD
		,@HINMOKU_SEQ
		,NULL
		,@YOYAKU_DENPYO_NO
		,@YOYAKU_DENPYO_ENO

		FETCH NEXT FROM HIKIATE_CUR
		INTO @TOKUISAKI_CD
			,@SOKO_CD
			,@HINMOKU_SEQ	
			,@YOYAKU_DENPYO_NO
			,@YOYAKU_DENPYO_ENO	
	END

	CLOSE HIKIATE_CUR
	DEALLOCATE HIKIATE_CUR

	--変数の初期化
	SET @TOKUISAKI_CD = NULL
	SET @SOKO_CD = NULL
	SET @HINMOKU_SEQ = NULL
	
	/*************************************************
	*引当状態が「未」「一括引当」の数量引当
	*推定登録のため、出荷予定は作成しない
	*引当可能数は考慮しない。受注数量=注文数とする。
	**************************************************/
	UPDATE #tmp
	SET SURYO = CASE WHEN ERROR_MSG IS NULL
							THEN (CONVERT(DECIMAL(13, 3),ISNULL(LOT_NUM, '0')) * ISNULL(HIN.STD_IRISU, 0)) + CONVERT(DECIMAL(13, 3),ISNULL(BARA_NUM, '0'))
					 ELSE 0--エラー行は0とする
				END
	FROM #tmp
	LEFT JOIN BC_MST_HINMOKU_KANRI HINKAN
		ON HINKAN.HINMOKU_SEQ = #tmp.HINMOKU_SEQ
	LEFT JOIN BC_MST_HINMOKU HIN
		ON HIN.KAISHA_CD = HINKAN.KAISHA_CD
		AND HIN.HINMOKU_CD = HINKAN.HINMOKU_CD
	WHERE HIKIATE_STATE IN ('01', '03') 
	AND HINKAN.KAISHA_CD = @KAISHA_CD

	/************************************************************************************
	*引当状態が「引当」の数量引当
	*注文数以下の最大の引当可能数分引当を実施する。引当対象が存在しない場合、0を設定
	*エラー無行に対してのみ引当処理を実施
	*注文日次順で引当を行い、不足した場合は、ロット単位で確保できる数まで引当。
	*在庫管理外品は引当数を注文数とする
	*************************************************************************************/
	--出荷予定作成用TBL
	CREATE TABLE #tmpShukkaYotei
    (LINE_NO				DECIMAL(6)
	,SURYO					DECIMAL(13, 3)
	,HINMOKU_SEQ			DECIMAL(10)
	,ZAIKO_SEQ				DECIMAL(10)
	,NYUKA_YOTEI_NO			NVARCHAR(16)
	,YOYAKU_JUCHU_NO		NVARCHAR(15)
	,YOYAKU_JUCHU_ENO		DECIMAL(3)
	)

	DECLARE @cnt int

	--エラー行の取得
	SELECT
		@cnt = count(*)
	FROM #tmp
	WHERE ERROR_MSG IS NOT NULL

	--エラー行が一つでもあれば、引当処理と与信チェックは行わない。
	IF(@cnt = 0)
	BEGIN

	DECLARE @SURYO					DECIMAL(13,3)	--受注数
	DECLARE @IS_ZAIKO_KANRI			TINYINT			--在庫管理フラグ

	DECLARE @CHUMON_SURYO			DECIMAL(13,3)	--注文数
	DECLARE @IRI_SURYO				DECIMAL(13,3)	--入り数
	DECLARE @MAX_HIKIATE_SURYO		DECIMAL(13,3)	--最大引当可能数

	--引当処理用の変数
	DECLARE @HIKIATE_KBN			INT				--引当区分
	DECLARE @HIKIATE_SURYO			DECIMAL(13,3)	--引当可能数
	DECLARE @ZAIKO_SEQ				DECIMAL(10)		--在庫SEQ
	DECLARE @NYUKA_YOTEI_NO			NVARCHAR(16)	--入荷予定NO
	DECLARE @YOYAKU_JUCHU_NO		NVARCHAR(12)	--予約伝票NO
	DECLARE @YOYAKU_JUCHU_ENO		DECIMAL(3)		--予約枝番
	DECLARE @HIKIATE_ZAN_SURYO		DECIMAL(13,3)	--引当残数

	DECLARE tmp_CUR CURSOR FOR
	SELECT LINE_NO
		  ,JUCHU_KBN
		  ,TOKUISAKI_CD
		  ,#tmp.HINMOKU_SEQ
		  ,DTL_SOKO_CD
		  ,CONVERT(DATETIME, SHUKKA_YOTEI_DATE)
		  ,YOYAKU_DENPYO_NO
		  ,CONVERT(DECIMAL, YOYAKU_DENPYO_ENO)
		  ,SHUKKO_KBN
	FROM #tmp
	WHERE HIKIATE_STATE = '02'	--引当のみ引当可能数を考慮
	  AND ERROR_MSG IS NULL
	ORDER BY JUCHU_DATE
			,DTL_SHUKKA_YOTEI_DATE
			,JUCHU_KBN
			,LINE_NO
			
	OPEN tmp_CUR
	FETCH NEXT FROM tmp_CUR
	INTO @LINE_NO
		,@JUCHU_KBN
		,@TOKUISAKI_CD
		,@HINMOKU_SEQ
		,@SOKO_CD
		,@SHUKKA_YOTEI_DATE
		,@YOYAKU_DENPYO_NO
		,@YOYAKU_DENPYO_ENO
		,@SHUKKO_KBN
	WHILE @@FETCH_STATUS = 0
	BEGIN
	
		SELECT @IS_ZAIKO_KANRI = HIN.ZAIKO_KANRI_FLG
		FROM BC_MST_HINMOKU_KANRI HINKAN
		LEFT JOIN BC_MST_HINMOKU HIN
			ON HINKAN.KAISHA_CD =HIN.KAISHA_CD
			AND HINKAN.HINMOKU_CD = HIN.HINMOKU_CD
		WHERE HINKAN.KAISHA_CD = @KAISHA_CD
		AND HINKAN.HINMOKU_SEQ = @HINMOKU_SEQ

		--注文数を取得
		SELECT @CHUMON_SURYO = (CONVERT(DECIMAL(13, 3),ISNULL(#tmp.LOT_NUM, '0')) * ISNULL(HIN.STD_IRISU, 0)) + CONVERT(DECIMAL(13, 3),ISNULL(BARA_NUM, '0')),
				@IRI_SURYO = HIN.STD_IRISU
		FROM #tmp
		LEFT JOIN BC_MST_HINMOKU_KANRI HINKAN
			ON HINKAN.HINMOKU_SEQ = #tmp.HINMOKU_SEQ
		LEFT JOIN BC_MST_HINMOKU HIN
			ON HIN.KAISHA_CD = HINKAN.KAISHA_CD
			AND HIN.HINMOKU_CD = HINKAN.HINMOKU_CD
		WHERE LINE_NO = @LINE_NO
		AND #tmp.HINMOKU_SEQ = @HINMOKU_SEQ
		
		IF (@IS_ZAIKO_KANRI = 1)
		BEGIN
			--在庫管理品
			--引当数(注文数以下の最大まで引当)を求める

			--最大引当可能数を取得
			SELECT @MAX_HIKIATE_SURYO = SUM(ISNULL(HIKIATE.SURYO, 0))
			FROM #tmpHikiate HIKIATE
			WHERE SOKO_CD = @SOKO_CD
			AND HINMOKU_SEQ = @HINMOKU_SEQ
			AND TOKUISAKI_CD = @TOKUISAKI_CD
			--預かり出庫04、預け売上07は在庫の得意先が一致すること
			--他は在庫の得意先は条件にしていしない
			AND ((@SHUKKO_KBN IN ('04', '07') AND ZAIKO_TOKUISAKI = @TOKUISAKI_CD)
					OR (@SHUKKO_KBN NOT IN ('04', '07') AND ZAIKO_TOKUISAKI IS NULL)
				)
			AND ((KBN = 1 AND(DATEDIFF(dd, HIKIATE.SHUKKA_YOTEI_DATE, @SHUKKA_YOTEI_DATE) >= 0))		--予約
					OR (KBN = 2 AND(DATEDIFF(dd, HIKIATE.SHUKKA_YOTEI_DATE, @SHUKKA_YOTEI_DATE) >= 0))	--親予約
					 OR (KBN = 3 AND(DATEDIFF(dd, HIKIATE.SHUKKA_KANO_DATE, @SHUKKA_YOTEI_DATE) <= 0))	--在庫
					 OR (KBN = 5 AND(DATEDIFF(dd, HIKIATE.SHUKKA_YOTEI_DATE, @SHUKKA_YOTEI_DATE) >= 0))	--予約全量
				)
			--予約在庫からの引当のみ
			AND ((@JUCHU_KBN = '01' AND @YOYAKU_DENPYO_NO IS NULL AND KBN IN (1, 2, 3))--予約未指定
				 OR
				 (@JUCHU_KBN = '01' AND @YOYAKU_DENPYO_NO IS NOT NULL AND KBN = 5)		--予約指定
				 OR 
				 (@JUCHU_KBN = '02' AND KBN = 3)
				 OR 
				 (@JUCHU_KBN = '03' AND KBN IN (1, 2, 3)) --移動は予約、在庫から引当
				 )
			--予約伝票指定の場合、対象の予約のみ引当る。このとき、得意先コードは無視する
			AND ((@YOYAKU_DENPYO_NO IS NULL AND TOKUISAKI_CD = @TOKUISAKI_CD)
					OR (HIKIATE.YOYAKU_JUCHU_NO = @YOYAKU_DENPYO_NO AND HIKIATE.YOYAKU_JUCHU_ENO = @YOYAKU_DENPYO_ENO))
			--数量が存在するもののみ
			AND SURYO > 0

			--最大引当可能数と注文数を比較
			IF(@MAX_HIKIATE_SURYO > @CHUMON_SURYO)
			BEGIN
				--引当数が潤沢に存在するので注文数をセット			
				SET @SURYO = @CHUMON_SURYO
			END
			ELSE
			BEGIN
				IF @IRI_SURYO IS NULL OR @IRI_SURYO = 0 BEGIN
				SET @CHUMON_SURYO = @MAX_HIKIATE_SURYO
				--注文数を満たさない、かつロット数がないため最大引当数をセット
				SET @SURYO = @MAX_HIKIATE_SURYO
				END
				ELSE BEGIN 
				SET @CHUMON_SURYO = @MAX_HIKIATE_SURYO - 1
				--注文数を満たさない、かつロット単位で確保できるため、最大引当数-1をセット
				SET @SURYO = @MAX_HIKIATE_SURYO -1
				END
			END
		
		END
				

		--#tmpShukkaYoteiに登録
		IF (ISNULL(@SURYO, 0) > 0)
		BEGIN
			--引当残数に数量をセット
			SET @HIKIATE_ZAN_SURYO = @SURYO

			--受注数に達するまで引当をループする
			DECLARE hikiateCUR CURSOR FOR
			SELECT KBN
				  ,ISNULL(HIKIATE.SURYO, 0)
				  ,HIKIATE.ZAIKO_SEQ
				  ,HIKIATE.NYUKA_YOTEI_NO
				  ,HIKIATE.YOYAKU_JUCHU_NO
				  ,HIKIATE.YOYAKU_JUCHU_ENO
			FROM #tmpHikiate HIKIATE
			WHERE SOKO_CD = @SOKO_CD
			AND HINMOKU_SEQ = @HINMOKU_SEQ
			AND TOKUISAKI_CD = @TOKUISAKI_CD
			--預かり出庫04、預け売上07は在庫の得意先が一致すること
			--他は在庫の得意先は条件にしていしない
			AND ((@SHUKKO_KBN IN ('04', '07') AND ZAIKO_TOKUISAKI = @TOKUISAKI_CD)
					OR (@SHUKKO_KBN NOT IN ('04', '07') AND ZAIKO_TOKUISAKI IS NULL)
				)
			AND ((KBN = 1 AND(DATEDIFF(dd, HIKIATE.SHUKKA_YOTEI_DATE, @SHUKKA_YOTEI_DATE) >= 0))
					OR (KBN = 2 AND(DATEDIFF(dd, HIKIATE.SHUKKA_YOTEI_DATE, @SHUKKA_YOTEI_DATE) >= 0))
					 OR (KBN = 3 AND(DATEDIFF(dd, HIKIATE.SHUKKA_KANO_DATE, @SHUKKA_YOTEI_DATE) <= 0))
					 OR (KBN = 5 AND(DATEDIFF(dd, HIKIATE.SHUKKA_YOTEI_DATE, @SHUKKA_YOTEI_DATE) >= 0))
				)
			AND ((@JUCHU_KBN = '01' AND @YOYAKU_DENPYO_NO IS NULL AND KBN IN (1, 2, 3))
				 OR
				 (@JUCHU_KBN = '01' AND @YOYAKU_DENPYO_NO IS NOT NULL AND KBN = 5)
				 OR 
				 (@JUCHU_KBN = '02' AND KBN = 3)
				 OR 
				 (@JUCHU_KBN = '03' AND KBN IN (1, 2, 3)) --移動は予約、在庫から引当
				 )
			AND ((@YOYAKU_DENPYO_NO IS NULL AND TOKUISAKI_CD = @TOKUISAKI_CD)
					OR (HIKIATE.KBN = 5 AND HIKIATE.YOYAKU_JUCHU_NO = @YOYAKU_DENPYO_NO AND HIKIATE.YOYAKU_JUCHU_ENO = @YOYAKU_DENPYO_ENO))
			AND SURYO > 0
			ORDER BY KBN				--昇順(予約＞親予約>在庫の順)
					,SHUKKA_YOTEI_DATE	--昇順

			OPEN hikiateCUR
			FETCH NEXT FROM hikiateCUR
			INTO @HIKIATE_KBN 
				,@HIKIATE_SURYO
				,@ZAIKO_SEQ
				,@NYUKA_YOTEI_NO
				,@YOYAKU_JUCHU_NO
				,@YOYAKU_JUCHU_ENO
			--ループ可能かつ引当残数が存在する間繰り返し
			WHILE (@@FETCH_STATUS = 0 AND @HIKIATE_ZAN_SURYO > 0)
			BEGIN
				IF(@HIKIATE_SURYO >= @HIKIATE_ZAN_SURYO)
				BEGIN
					--引当可能数が引当残数より大きい
					--引当可能数量に残数を設定
					SET @HIKIATE_SURYO = @HIKIATE_ZAN_SURYO
					--引当残数を0設定
					SET @HIKIATE_ZAN_SURYO = 0
				END
				ELSE
				BEGIN
					--引当残数から引当数を引く
					SET @HIKIATE_ZAN_SURYO = @HIKIATE_ZAN_SURYO - @HIKIATE_SURYO
				END

				--#tmpHikiateの数量を更新する
				--数量から引当数を引く
				--親得意先の予約引当を考慮し、得意先は条件に含めない
				UPDATE #tmpHikiate
				SET SURYO = SURYO - @HIKIATE_SURYO
				FROM #tmpHikiate hikiate
				WHERE (@ZAIKO_SEQ IS NULL OR hikiate.ZAIKO_SEQ = @ZAIKO_SEQ)
				  AND (@NYUKA_YOTEI_NO IS NULL OR hikiate.NYUKA_YOTEI_NO = @NYUKA_YOTEI_NO)
				  AND (@YOYAKU_JUCHU_NO IS NULL OR hikiate.YOYAKU_JUCHU_NO = @YOYAKU_JUCHU_NO)
				  AND (@YOYAKU_JUCHU_ENO IS NULL OR hikiate.YOYAKU_JUCHU_ENO = @YOYAKU_JUCHU_ENO)

				--出荷予定作成用の一時テーブルに引当情報を格納
				INSERT INTO #tmpShukkaYotei
				(LINE_NO
				,SURYO
				,HINMOKU_SEQ
				,ZAIKO_SEQ
				,NYUKA_YOTEI_NO
				,YOYAKU_JUCHU_NO
				,YOYAKU_JUCHU_ENO
				)
				SELECT @LINE_NO
					  ,@HIKIATE_SURYO
					  ,@HINMOKU_SEQ
					  ,@ZAIKO_SEQ
					  ,@NYUKA_YOTEI_NO
					  ,@YOYAKU_JUCHU_NO
					  ,@YOYAKU_JUCHU_ENO

				--引当区分を設定する
				--01:予約引当
				--02:在＋予引当
				--03:在庫引当
				--最初が在庫引当の場合、予約は存在しない
				UPDATE #tmp
				SET HIKIATE_KBN = CASE WHEN (HIKIATE_KBN IS NULL OR HIKIATE_KBN = '')
											THEN CASE @HIKIATE_KBN
													WHEN 1 THEN '01'	--予約
													WHEN 2 THEN '01'	--親予約
													WHEN 3 THEN '03'	--在庫
													WHEN 5 THEN '01'	--予約指定引当
												  END
									   WHEN HIKIATE_KBN = '01' AND @HIKIATE_KBN = 3
												THEN '02'
								   ELSE HIKIATE_KBN
								  END
				WHERE LINE_NO = @LINE_NO

				--予約引当の場合、予約伝票の数量・金額を更新する
				IF (@HIKIATE_KBN IN (1,2,5))
				BEGIN
					--受注明細
					UPDATE HK_TBL_JUCHU_DTL
					SET SURYO = SURYO - @HIKIATE_SURYO
					   ,KINGAKU = dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD, HDR.TOKUISAKI_CD, DTL.TANKA * (DTL.SURYO - @HIKIATE_SURYO), 1, 0)	--金額
					   ,SHOHIZEI=dbo.CO_FUNC_HASU_SHORI((DTL.TANKA * (DTL.SURYO - @HIKIATE_SURYO)) * DTL.TAX_RATE, TORI.JUCHU_SHOHIZEI_HASU_KBN, 0)		--消費税
					   ,UPD_TM = SYSDATETIME()
					   ,UPD_PGM_CD = @PGM_CD
					   ,UPD_SHAIN_CD = @USER_ID
					FROM HK_TBL_JUCHU_DTL DTL
					LEFT JOIN HK_TBL_JUCHU_HDR HDR
						ON HDR.KAISHA_CD = DTL.KAISHA_CD
						AND HDR.JUCHU_NO = DTL.JUCHU_NO
					LEFT JOIN BC_MST_TORIHIKISAKI TORI
						ON TORI.KAISHA_CD = HDR.KAISHA_CD
						AND TORI.TORIHIKISAKI_CD = HDR.TOKUISAKI_CD
					WHERE DTL.KAISHA_CD = @KAISHA_CD
					AND DTL.JUCHU_NO = @YOYAKU_JUCHU_NO
					AND DTL.JUCHU_ENO = @YOYAKU_JUCHU_ENO

					--受注明細外貨
					UPDATE HK_TBL_JUCHU_DTL_GAIKA
					SET TUKA_KINGAKU = dbo.CO_FUNC_HASU_SHORI_EX(DTL_GAIKA.TUKA_TANKA * DTL.SURYO ,'01' ,TUKA.DECIMAL_LENGTH)
					   ,UPD_TM = SYSDATETIME()
					   ,UPD_PGM_CD = @PGM_CD
					   ,UPD_SHAIN_CD = @USER_ID
					FROM HK_TBL_JUCHU_DTL_GAIKA DTL_GAIKA
					LEFT JOIN HK_TBL_JUCHU_DTL DTL
						ON DTL.KAISHA_CD = DTL_GAIKA.KAISHA_CD
						AND DTL.JUCHU_NO = DTL_GAIKA.JUCHU_NO
						AND DTL.JUCHU_ENO = DTL_GAIKA.JUCHU_ENO
					LEFT JOIN HK_TBL_JUCHU_HDR_GAIKA HDR_GAIKA
						ON HDR_GAIKA.KAISHA_CD = DTL.KAISHA_CD
						AND HDR_GAIKA.JUCHU_NO = DTL.JUCHU_NO
					LEFT JOIN BC_MST_TUKA TUKA
						ON TUKA.KAISHA_CD = HDR_GAIKA.KAISHA_CD
						AND TUKA.TUKA_CD = HDR_GAIKA.TUKA_CD
						AND TUKA.DEL_FLG = 0
						AND TUKA.MUKOU_FLG = 0
					WHERE DTL_GAIKA.KAISHA_CD = @KAISHA_CD
					AND DTL_GAIKA.JUCHU_NO = @YOYAKU_JUCHU_NO
					AND DTL_GAIKA.JUCHU_ENO = @YOYAKU_JUCHU_ENO

					--出荷予定
					UPDATE HK_TBL_SHUKKA_YOTEI
					SET SURYO = SY.SURYO - @HIKIATE_SURYO
					   ,KINGAKU = dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD, HDR.TOKUISAKI_CD, DTL.TANKA * (SY.SURYO - @HIKIATE_SURYO), 1, 0)	--金額
					   ,JISSEKI_KINGAKU = dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD, HDR.TOKUISAKI_CD, DTL.TANKA * (SY.SURYO - @HIKIATE_SURYO), 1, 0)	--実績金額
					   ,SHOHIZEI=dbo.CO_FUNC_HASU_SHORI((DTL.TANKA * (SY.SURYO - @HIKIATE_SURYO)) * SY.TAX_RATE, TORI.JUCHU_SHOHIZEI_HASU_KBN, 0)		--消費税
					   ,JISSEKI_SHOHIZEI=dbo.CO_FUNC_HASU_SHORI((DTL.TANKA * (SY.SURYO - @HIKIATE_SURYO)) * SY.TAX_RATE, TORI.JUCHU_SHOHIZEI_HASU_KBN, 0)		--実績消費税
					   ,UPD_TM = SYSDATETIME()
					   ,UPD_PGM_CD = @PGM_CD
					   ,UPD_SHAIN_CD = @USER_ID
					FROM HK_TBL_SHUKKA_YOTEI SY
					LEFT JOIN HK_TBL_JUCHU_DTL DTL
						ON DTL.KAISHA_CD = SY.KAISHA_CD
						AND DTL.JUCHU_NO = SY.JUCHU_NO
						AND DTL.JUCHU_ENO = SY.JUCHU_ENO
					LEFT JOIN HK_TBL_JUCHU_HDR HDR
						ON HDR.KAISHA_CD = DTL.KAISHA_CD
						AND HDR.JUCHU_NO = DTL.JUCHU_NO
					LEFT JOIN BC_MST_TORIHIKISAKI TORI
						ON TORI.KAISHA_CD = HDR.KAISHA_CD
						AND TORI.TORIHIKISAKI_CD = HDR.TOKUISAKI_CD
					WHERE SY.KAISHA_CD = @KAISHA_CD
					AND SY.JUCHU_NO = @YOYAKU_JUCHU_NO
					AND SY.JUCHU_ENO = @YOYAKU_JUCHU_ENO
					AND SY.DEL_FLG = 0

					--出荷予定外貨
					UPDATE HK_TBL_SHUKKA_YOTEI_GAIKA
					SET TUKA_KINGAKU = dbo.CO_FUNC_HASU_SHORI_EX(DTL_GAIKA.TUKA_TANKA * SY.SURYO ,'01' ,TUKA.DECIMAL_LENGTH)
					   ,JISSEKI_TUKA_KINGAKU = dbo.CO_FUNC_HASU_SHORI_EX(DTL_GAIKA.TUKA_TANKA * SY.SURYO ,'01' ,TUKA.DECIMAL_LENGTH)
					   ,UPD_TM = SYSDATETIME()
					   ,UPD_PGM_CD = @PGM_CD
					   ,UPD_SHAIN_CD = @USER_ID
					FROM HK_TBL_SHUKKA_YOTEI_GAIKA SY_GAIKA
					INNER JOIN HK_TBL_SHUKKA_YOTEI SY
						ON SY.KAISHA_CD = SY_GAIKA.KAISHA_CD
						AND SY.SHUKKA_YOTEI_NO = SY_GAIKA.SHUKKA_YOTEI_NO
					LEFT JOIN HK_TBL_JUCHU_DTL_GAIKA DTL_GAIKA
						ON DTL_GAIKA.KAISHA_CD = SY.KAISHA_CD
						AND DTL_GAIKA.JUCHU_NO = SY.JUCHU_NO
						AND DTL_GAIKA.JUCHU_ENO = SY.JUCHU_ENO
					LEFT JOIN HK_TBL_JUCHU_HDR_GAIKA HDR_GAIKA
						ON HDR_GAIKA.KAISHA_CD = DTL_GAIKA.KAISHA_CD
						AND HDR_GAIKA.JUCHU_NO = DTL_GAIKA.JUCHU_NO
					LEFT JOIN BC_MST_TUKA TUKA
						ON TUKA.KAISHA_CD = HDR_GAIKA.KAISHA_CD
						AND TUKA.TUKA_CD = HDR_GAIKA.TUKA_CD
						AND TUKA.DEL_FLG = 0
						AND TUKA.MUKOU_FLG = 0
					WHERE SY.KAISHA_CD = @KAISHA_CD
					AND SY.JUCHU_NO = @YOYAKU_JUCHU_NO
					AND SY.JUCHU_ENO = @YOYAKU_JUCHU_ENO
					AND SY.DEL_FLG = 0

				END

				FETCH NEXT FROM hikiateCUR
				INTO @HIKIATE_KBN
					,@HIKIATE_SURYO
					,@ZAIKO_SEQ
					,@NYUKA_YOTEI_NO
					,@YOYAKU_JUCHU_NO
					,@YOYAKU_JUCHU_ENO
			END

			CLOSE hikiateCUR
			DEALLOCATE hikiateCUR
		END
		ELSE
		BEGIN
			--引当数が存在しない、または、在庫管理外の場合
			IF (@IS_ZAIKO_KANRI = 1)
			BEGIN
				--在庫管理品
				SET @SURYO = 0
			END
			ELSE
			BEGIN
				--在庫管理外品
				SET @SURYO = @CHUMON_SURYO
			END
			
			INSERT INTO #tmpShukkaYotei
			(LINE_NO
			,SURYO
			,HINMOKU_SEQ
			,ZAIKO_SEQ
			,NYUKA_YOTEI_NO
			,YOYAKU_JUCHU_NO
			,YOYAKU_JUCHU_ENO
			)
			SELECT @LINE_NO
				  ,@SURYO
				  ,@HINMOKU_SEQ
				  ,NULL
				  ,NULL
				  ,NULL
				  ,NULL

			--在庫管理外は「NULL」、数量0は「未引当」
			UPDATE #tmp
			SET HIKIATE_KBN = 
			CASE WHEN @IS_ZAIKO_KANRI = 1 THEN '00'	--未引当
			ELSE NULL
			END
			WHERE LINE_NO = @LINE_NO
		END
		
		--数量をセット
		UPDATE #tmp
		SET SURYO = @SURYO
		WHERE LINE_NO = @LINE_NO

		FETCH NEXT FROM tmp_CUR
		INTO @LINE_NO
			,@JUCHU_KBN
			,@TOKUISAKI_CD
			,@HINMOKU_SEQ
			,@SOKO_CD
			,@SHUKKA_YOTEI_DATE
			,@YOYAKU_DENPYO_NO
			,@YOYAKU_DENPYO_ENO
			,@SHUKKO_KBN

		--初期化
		SET @SURYO = NULL
		SET @IS_ZAIKO_KANRI = NULL
	END

	CLOSE tmp_CUR
	DEALLOCATE tmp_CUR

	/*===============================数量引当END===============================*/

	/*===============================数量引当後チェックSTART===============================*/
	/*===============================数量引当後チェックEND===============================*/

	/*===============================与信限度額チェックSTART===============================*/
	--チェックを行うために金額関係を求める
	UPDATE #tmp
	SET TAX_SITEI_KBN = CASE WHEN TORI_GAIKA.TUKA_CD = @TUKA_CD	--税率指定区分
								THEN #tmp.KAZEI_KBN
							--外貨は非課税固定
							ELSE '02'
							END
		,JUCHU_TANKA =  CASE WHEN #tmp.SAMPLE_SHUKKA_FLG = '1'
									--サンプル出荷
									THEN 0
						ELSE CASE WHEN TORI_GAIKA.TUKA_CD = @TUKA_CD
									THEN CASE --掛率が設定されている場合」
												WHEN KAKERITU IS NOT NULL
													THEN dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD, #tmp.TOKUISAKI_CD, (CONVERT(DECIMAL(5, 2),KAKERITU) * TANKA.SOTOZEI_TANKA) / 100, 0, 0)
												--掛率未設定だが、取引先通貨単価が設定されている場合
												WHEN TORIHIKISAKI_TUKA_TANKA IS NOT NULL
													--円貨の場合、レートは1となる
													THEN dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD, #tmp.TOKUISAKI_CD, TORIHIKISAKI_TUKA_TANKA, 0, 0)
												--得意先別単価が設定されている場合
												WHEN TOKUI_TANKA.SOTOZEI_TANKA IS NOT NULL
													THEN dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD, #tmp.TOKUISAKI_CD, TOKUI_TANKA.SOTOZEI_TANKA, 0, 0)
												--得意先別掛率が設定されている場合
												WHEN TOKUI_TANKA.KAKERITSU IS NOT NULL
													THEN dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD, #tmp.TOKUISAKI_CD, TOKUI_TANKA.KAKERITSU * TANKA.SOTOZEI_TANKA, 0, 0)
												--親得意先の得意先別単価が設定されている場合
												WHEN OYA_TOKUI_TANKA.SOTOZEI_TANKA IS NOT NULL
													THEN dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD, #tmp.TOKUISAKI_CD, OYA_TOKUI_TANKA.SOTOZEI_TANKA, 0, 0)
												--親得意先別掛率が設定されている場合
												WHEN OYA_TOKUI_TANKA.KAKERITSU IS NOT NULL
													THEN dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD, #tmp.TOKUISAKI_CD, OYA_TOKUI_TANKA.KAKERITSU * TANKA.SOTOZEI_TANKA, 0, 0)
												--品目掛率設定かつ国内海外区分が国内かつ取引形態区分が店舗(外税)店舗(内税)でない
												WHEN HIN_EX.HINMOKU_KAKERITU IS NOT NULL AND TORIHIKI_EX.KOKUNAI_KAIGAI_KBN = '01'
														AND TOKUI_EX.TORIHIKI_KEITAI_KBN NOT IN ('4', '5')
													THEN dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD, #tmp.TOKUISAKI_CD, HIN_EX.HINMOKU_KAKERITU * TANKA.SOTOZEI_TANKA, 0, 0)
												--得意先マスタの得意先別掛率が設定されている場合
												WHEN TOKUI_EX.KAKERITSU IS NOT NULL
													THEN dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD, #tmp.TOKUISAKI_CD, TOKUI_EX.KAKERITSU  * TANKA.SOTOZEI_TANKA, 0, 0)
												--上記に属さない場合、品目単価
												ELSE dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD, #tmp.TOKUISAKI_CD, TANKA.SOTOZEI_TANKA, 0, 0)
											END
								--外貨の場合、取引先通貨単価 *レート
								ELSE dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD, #tmp.TOKUISAKI_CD, CONVERT(DECIMAL(13, 3), TORIHIKISAKI_TUKA_TANKA) * ISNULL(CONVERT(DECIMAL(8, 3),#tmp.RATE), RATE.RATE), 0, 1)
							END
						END
		,KAKERITU = CASE WHEN #tmp.SAMPLE_SHUKKA_FLG = '1'
									--サンプル出荷
									THEN 0
					ELSE CASE WHEN TORI_GAIKA.TUKA_CD = @TUKA_CD
								THEN CASE --掛率が設定されている場合」
											WHEN KAKERITU IS NOT NULL
												THEN CONVERT(DECIMAL(5, 2),KAKERITU) / 100
											--掛率未設定だが、取引先通貨単価が設定されている場合
											WHEN TORIHIKISAKI_TUKA_TANKA IS NOT NULL
												--円貨の場合、レートは1となる
												THEN --取引先通貨単価 > 品目単価の場合、掛率は未設定
														CASE WHEN CONVERT(DECIMAL(14, 4), TORIHIKISAKI_TUKA_TANKA) >= TANKA.SOTOZEI_TANKA OR TANKA.SOTOZEI_TANKA = 0
																	THEN NULL
															--(受注単価/上代単価(外税単価):小数第2位を四捨五入
															ELSE [dbo].[CO_FUNC_HASU_SHORI](CONVERT(DECIMAL(4, 3), (CONVERT(DECIMAL(14, 4), TORIHIKISAKI_TUKA_TANKA) / TANKA.SOTOZEI_TANKA)), '01', 3)
														END
											--得意先別単価が設定されている場合
											WHEN TOKUI_TANKA.SOTOZEI_TANKA IS NOT NULL
												THEN NULL
											--得意先別掛率が設定されている場合
											WHEN TOKUI_TANKA.KAKERITSU IS NOT NULL
												THEN TOKUI_TANKA.KAKERITSU
											--親得意先の得意先別単価が設定されている場合
											WHEN OYA_TOKUI_TANKA.SOTOZEI_TANKA IS NOT NULL
												THEN NULL
											--親得意先別掛率が設定されている場合
											WHEN OYA_TOKUI_TANKA.KAKERITSU IS NOT NULL
												THEN OYA_TOKUI_TANKA.KAKERITSU
											--品目掛率設定かつ国内海外区分が国内かつ取引形態区分が店舗(外税)店舗(内税)でない
											WHEN HIN_EX.HINMOKU_KAKERITU IS NOT NULL AND TORIHIKI_EX.KOKUNAI_KAIGAI_KBN = '01'
													AND TOKUI_EX.TORIHIKI_KEITAI_KBN NOT IN ('4', '5')
												THEN HIN_EX.HINMOKU_KAKERITU
											--得意先マスタの得意先別掛率が設定されている場合
											WHEN TOKUI_EX.KAKERITSU IS NOT NULL
												THEN TOKUI_EX.KAKERITSU
											--上記に属さない場合、掛率未設定
											ELSE NULL
										END
							--外貨の場合、掛率未設定
							ELSE NULL
						END
					END
		,KAKERITU_REF_KBN = CASE WHEN #tmp.KAKERITU_REF_KBN IS NOT NULL 
									THEN #tmp.KAKERITU_REF_KBN
							ELSE CASE WHEN #tmp.SAMPLE_SHUKKA_FLG = '1'
									--サンプル出荷
									THEN NULL
							ELSE CASE WHEN TORI_GAIKA.TUKA_CD = @TUKA_CD
											THEN CASE --掛率が設定されている場合」
														WHEN KAKERITU IS NOT NULL
															THEN NULL
														--掛率未設定だが、取引先通貨単価が設定されている場合
														WHEN TORIHIKISAKI_TUKA_TANKA IS NOT NULL
															THEN NULL
														--得意先別単価が設定されている場合
														WHEN TOKUI_TANKA.SOTOZEI_TANKA IS NOT NULL
															THEN '01'
														--得意先別掛率が設定されている場合
														WHEN TOKUI_TANKA.KAKERITSU IS NOT NULL
															THEN '01'
														--親得意先の得意先別単価が設定されている場合
														WHEN OYA_TOKUI_TANKA.SOTOZEI_TANKA IS NOT NULL
															THEN '02'
														--親得意先別掛率が設定されている場合
														WHEN OYA_TOKUI_TANKA.KAKERITSU IS NOT NULL
															THEN '02'
														--品目掛率設定かつ国内海外区分が国内かつ取引形態区分が店舗(外税)店舗(内税)でない
														WHEN HIN_EX.HINMOKU_KAKERITU IS NOT NULL AND TORIHIKI_EX.KOKUNAI_KAIGAI_KBN = '01'
																AND TOKUI_EX.TORIHIKI_KEITAI_KBN NOT IN ('4', '5')
															THEN '03'
														--得意先マスタの得意先別掛率が設定されている場合
														WHEN TOKUI_EX.KAKERITSU IS NOT NULL
															THEN '04'
														--上記に属さない場合、掛率未設定
														ELSE NULL
													END
										--外貨の場合、掛率未設定
										ELSE NULL
									END
								END
							END
	FROM #tmp
	LEFT JOIN BC_MST_TANKA TANKA 
		ON TANKA.KAISHA_CD = @KAISHA_CD
		AND TANKA.HINMOKU_SEQ = #tmp.HINMOKU_SEQ
		AND DATEDIFF(DAY, START_DATE, DTL_SHUKKA_YOTEI_DATE) >= 0
		AND DATEDIFF(DAY, END_DATE, DTL_SHUKKA_YOTEI_DATE) <= 0
	LEFT JOIN BC_MST_TORIHIKISAKI_GAIKA TORI_GAIKA
		ON TORI_GAIKA.KAISHA_CD = @KAISHA_CD
		AND TORI_GAIKA.TORIHIKISAKI_CD = #tmp.TOKUISAKI_CD
	LEFT JOIN BC_MST_RATE RATE
		ON RATE.KAISHA_CD = TORI_GAIKA.KAISHA_CD
		AND RATE.BEFORE_TUKA_CD = TORI_GAIKA.TUKA_CD
		AND RATE.RATETYPE_CD = TORI_GAIKA.RATETYPE_CD
		AND DATEDIFF(DAY, RATE.START_DATE, DTL_SHUKKA_YOTEI_DATE) >= 0
		AND DATEDIFF(DAY, RATE.END_DATE, DTL_SHUKKA_YOTEI_DATE) <= 0
		AND RATE.DEL_FLG = 0
	LEFT JOIN BC_MST_TOKUISAKIBETU_TANKA TOKUI_TANKA
		ON TOKUI_TANKA.KAISHA_CD = @KAISHA_CD
		AND TOKUI_TANKA.TOKUISAKI_CD = #tmp.TOKUISAKI_CD
		AND TOKUI_TANKA.HINMOKU_SEQ = #tmp.HINMOKU_SEQ
		AND DATEDIFF(DAY, TOKUI_TANKA.START_DATE, DTL_SHUKKA_YOTEI_DATE) >= 0
		AND DATEDIFF(DAY, TOKUI_TANKA.END_DATE, DTL_SHUKKA_YOTEI_DATE) <= 0
		AND TOKUI_TANKA.DEL_FLG = 0
		AND TOKUI_TANKA.MUKOU_FLG = 0
	LEFT JOIN BC_MST_TORIHIKISAKI_EX TORIHIKI_EX
		ON TORIHIKI_EX.KAISHA_CD = @KAISHA_CD
		AND TORIHIKI_EX.TORIHIKISAKI_CD = #tmp.TOKUISAKI_CD
	LEFT JOIN BC_MST_TOKUISAKI_EX TOKUI_EX
		ON TOKUI_EX.KAISHA_CD = @KAISHA_CD
		AND TOKUI_EX.TOKUISAKI_CD = #tmp.TOKUISAKI_CD
	LEFT JOIN BC_MST_TOKUISAKIBETU_TANKA OYA_TOKUI_TANKA
		ON OYA_TOKUI_TANKA.KAISHA_CD = @KAISHA_CD
		AND OYA_TOKUI_TANKA.TOKUISAKI_CD = TOKUI_EX.OYA_TOKUISAKI_CD
		AND OYA_TOKUI_TANKA.HINMOKU_SEQ = #tmp.HINMOKU_SEQ
		AND DATEDIFF(DAY, OYA_TOKUI_TANKA.START_DATE, DTL_SHUKKA_YOTEI_DATE) >= 0
		AND DATEDIFF(DAY, OYA_TOKUI_TANKA.END_DATE, DTL_SHUKKA_YOTEI_DATE) <= 0
		AND OYA_TOKUI_TANKA.DEL_FLG = 0
		AND OYA_TOKUI_TANKA.MUKOU_FLG = 0
	LEFT JOIN BC_MST_HINMOKU_KANRI HINKAN
		ON HINKAN.KAISHA_CD = @KAISHA_CD
		AND HINKAN.HINMOKU_SEQ = #tmp.HINMOKU_SEQ
	LEFT JOIN BC_MST_HINMOKU HIN
		ON HIN.KAISHA_CD = HINKAN.KAISHA_CD
		AND HIN.HINMOKU_CD = HINKAN.HINMOKU_CD
	LEFT JOIN BC_MST_HINMOKU_EX HIN_EX
		ON HIN_EX.KAISHA_CD = HINKAN.KAISHA_CD
		AND HIN_EX.HINMOKU_CD = HINKAN.HINMOKU_CD
	LEFT JOIN BC_MST_TUKA TUKA
		ON TORI_GAIKA.KAISHA_CD = TUKA.KAISHA_CD
		AND TORI_GAIKA.TUKA_CD = TUKA.TUKA_CD
		AND TUKA.DEL_FLG = 0
		AND TUKA.MUKOU_FLG = 0

	UPDATE #tmp
	SET KAZEI_KBN = CASE WHEN TORI_GAIKA.TUKA_CD = @TUKA_CD		--課税区分
							--円貨の場合
							THEN CASE WHEN #tmp.KAZEI_KBN = '02'
											THEN '02'
									ELSE '01'
									END
							--外貨は非課税固定
							ELSE '02'
					END
		,TAX_RATE = CASE WHEN TORI_GAIKA.TUKA_CD = @TUKA_CD
								--円貨の場合
								THEN dbo.CO_FUNC_GET_TAXRATE(@KAISHA_CD, TAX_SITEI_KBN, HIN.TAX_KBN_CD, DTL_SHUKKA_YOTEI_DATE)
							--外貨は非課税
							ELSE 0.00
					END
		--取引先通貨単価が円貨の場合の考慮
		,TORIHIKISAKI_TUKA_TANKA = CASE WHEN TORI_GAIKA.TUKA_CD = @TUKA_CD
												THEN JUCHU_TANKA
										--外貨の場合は四捨五入固定
										ELSE dbo.CO_FUNC_HASU_SHORI_EX(TORIHIKISAKI_TUKA_TANKA, '01', TUKA.DECIMAL_LENGTH)
									END
		--レートの円貨の考慮
		,RATE = CASE WHEN TORI_GAIKA.TUKA_CD = @TUKA_CD
						THEN '1'
						ELSE ISNULL(#tmp.RATE, RATE.RATE)
					END
	FROM #tmp
	LEFT JOIN BC_MST_TORIHIKISAKI_GAIKA TORI_GAIKA
		ON TORI_GAIKA.KAISHA_CD = @KAISHA_CD
		AND TORI_GAIKA.TORIHIKISAKI_CD = #tmp.TOKUISAKI_CD
	LEFT JOIN BC_MST_RATE RATE
		ON RATE.KAISHA_CD = TORI_GAIKA.KAISHA_CD
		AND RATE.BEFORE_TUKA_CD = TORI_GAIKA.TUKA_CD
		AND RATE.RATETYPE_CD = TORI_GAIKA.RATETYPE_CD
		AND DATEDIFF(DAY, RATE.START_DATE, DTL_SHUKKA_YOTEI_DATE) >= 0
		AND DATEDIFF(DAY, RATE.END_DATE, DTL_SHUKKA_YOTEI_DATE) <= 0
		AND RATE.DEL_FLG = 0
	LEFT JOIN BC_MST_HINMOKU_KANRI HINKAN
		ON HINKAN.KAISHA_CD = @KAISHA_CD
		AND HINKAN.HINMOKU_SEQ = #tmp.HINMOKU_SEQ
	LEFT JOIN BC_MST_HINMOKU HIN
		ON HIN.KAISHA_CD = HINKAN.KAISHA_CD
		AND HIN.HINMOKU_CD = HINKAN.HINMOKU_CD
	LEFT JOIN BC_MST_TUKA TUKA
		ON TORI_GAIKA.KAISHA_CD = TUKA.KAISHA_CD
		AND TORI_GAIKA.TUKA_CD = TUKA.TUKA_CD
		AND TUKA.DEL_FLG = 0
		AND TUKA.MUKOU_FLG = 0

	--チェック
	--請求先単位に与信限度チェックを実施
	DECLARE @SEIKYUSAKI_CD NVARCHAR(15)
		   ,@YOSHIN_TAISHO_KINGAKU DECIMAL
		   ,@YOSHIN_GENDO_GAKU DECIMAL(18)
		   ,@YOSHIN_GENDO_ZANDAKA DECIMAL(18)

	DECLARE yoshinCUR CURSOR FOR
	SELECT DISTINCT SEIKYUSAKI_CD
	FROM #tmp
	WHERE ERROR_MSG IS NULL
	AND JUCHU_KBN = '01'

	OPEN yoshinCUR
	FETCH NEXT FROM yoshinCUR
	INTO @SEIKYUSAKI_CD
	WHILE @@FETCH_STATUS = 0
	BEGIN
		
		--与信限度対象金額の取得
		SELECT @YOSHIN_TAISHO_KINGAKU = dbo.HK_FUNC_GET_YOSHIN_TAISHO_KINGAKU(@KAISHA_CD, @SEIKYUSAKI_CD)

		--@YOSHIN_TAISHO_KINGAKUがNULLの場合、与信限度額が未設定
		IF (@YOSHIN_TAISHO_KINGAKU IS NOT NULL)
		BEGIN
			--与信限度額の取得
			SELECT @YOSHIN_GENDO_GAKU
					= CASE WHEN SEIKYU.YOSHIN_GRP_CD IS NULL
							THEN SEIKYU.YOSHIN_GENDOGAKU	--請求先の与信限度額
						   ELSE YOSHI_G.YOSHIN_GENDOGAKU	--与信グループの与信限度額
					  END
			FROM BC_MST_SEIKYUSAKI SEIKYU
			LEFT JOIN BC_MST_YOSHIN_GRP YOSHI_G
				ON YOSHI_G.KAISHA_CD = SEIKYU.KAISHA_CD
				AND YOSHI_G.YOSHIN_GRP_CD = SEIKYU.YOSHIN_GRP_CD
				AND YOSHI_G.DEL_FLG = 0
			WHERE SEIKYU.SEIKYUSAKI_CD = @SEIKYUSAKI_CD

			--与信限度残高＝与信限度額-与信対象金額
			SET @YOSHIN_GENDO_ZANDAKA = @YOSHIN_GENDO_GAKU - @YOSHIN_TAISHO_KINGAKU

			--与信限度額残高がプラスの場合、今回登録分の金額を考慮する
			IF(@YOSHIN_GENDO_ZANDAKA >= 0)
			BEGIN
				--今回登録による限度残高を求める。
				--@YOSHIN_GENDO_ZANDAKA-((請求先に該当する受注金額＋消費税)の合計)を求める
				SELECT @YOSHIN_GENDO_ZANDAKA
						= @YOSHIN_GENDO_ZANDAKA - 
						  SUM(CASE WHEN #tmp.SHUKKO_KBN IN ('04', '06')
										THEN 0
									ELSE (dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD, #tmp.TOKUISAKI_CD, JUCHU_TANKA * SURYO, 1, 0)	--金額
										  + dbo.CO_FUNC_HASU_SHORI((JUCHU_TANKA * SURYO) * TAX_RATE, TORI.JUCHU_SHOHIZEI_HASU_KBN, 0)	--消費税
										 )
							  END
						     )
				FROM #tmp
				LEFT JOIN BC_MST_TORIHIKISAKI TORI
					ON TORI.KAISHA_CD = @KAISHA_CD
					AND TORI.TORIHIKISAKI_CD = #tmp.TOKUISAKI_CD
				WHERE SEIKYUSAKI_CD = @SEIKYUSAKI_CD
				AND JUCHU_KBN = '01'	--本受注の金額が対象
			END
			
			IF(@YOSHIN_GENDO_ZANDAKA < 0)
			BEGIN
				UPDATE #tmp
				SET ERROR_MSG = @ERR_MSG_YOSHIN_GENDO + @SEIKYUSAKI_CD
				WHERE SEIKYUSAKI_CD = @SEIKYUSAKI_CD
			END
		END

		--初期化
		SET @YOSHIN_TAISHO_KINGAKU = NULL
		SET @YOSHIN_GENDO_GAKU = NULL
		SET @YOSHIN_GENDO_ZANDAKA = NULL

		FETCH NEXT FROM yoshinCUR
		INTO @SEIKYUSAKI_CD
	END

	CLOSE yoshinCUR
	DEALLOCATE yoshinCUR

	END

	/*===============================与信限度額チェックEND===============================*/

	--エラー行
	DECLARE @ERR_CNT INT
    --エラー行を変数@ERR_CNTに設定する
    SELECT @ERR_CNT = COUNT(*)
    FROM #tmp
	WHERE ERROR_MSG IS NOT NULL

	IF (@ERR_CNT > 0)
	BEGIN
		--エラーあり
		SELECT @RetCd
		
		--エラー情報取得
		SELECT LINE_NO				AS 行番号
	   ,ERROR_MSG					AS エラー情報
	   ,JUCHU_KBN					AS 受注区分
	   ,JUCHU_DATE					AS 受注日
	   ,SHUKKO_KBN					AS 出庫区分
	   ,TOKUISAKI_CD				AS 得意先コード
	   ,SHUKKASAKI_CD				AS ヘッダ出荷先コード
	   ,SEIKYUSAKI_CD				AS 請求先コード
	   ,SOKO_CD						AS ヘッダ倉庫コード
	   ,AZUKE_AZUKARI_IDO_SOKO_CD	AS 預け預かり移動倉庫コード
	   ,SHUKKA_YOTEI_DATE			AS ヘッダ出荷予定日
	   ,SHITEI_NOHIN_DATE			AS ヘッダ指定納品日
	   ,SHITEI_NOHIN_JIKOKU			AS 指定納品時刻
	   ,HAISOU_KBN					AS 配送区分
	   ,KESSAI_HOHO					AS 決済方法
	   ,HDR_GEDAIMACHI_FLG			AS 下代待ちフラグ
	   ,SAMPLE_SHUKKA_FLG			AS サンプル出荷フラグ
	   ,HIKIATE_CHOSEI_FUYO_FLG		AS 引当調整不用フラグ
	   ,HDR_SEIKYU_KIJUN_DATE		AS ヘッダ請求基準日
	   ,TOKUISAKI_DENPYO_NO			AS 得意先伝票NO
	   ,TOKUISAKI_HACCHU_NO			AS 得意先発注NO
	   ,BUNRUI_CD					AS 分類コード
	   ,URIBA_NM					AS 売場名
	   ,TANTOSHA_NM					AS 担当者名
	   ,NAISEN_NO					AS 内線番号
	   ,TANTOSHA_CD					AS 担当者コード
	   ,TANTO_BUSHO_CD				AS 担当部署コード
	   ,NOHIN_KBN					AS 納品区分
	   ,RYUTU_KAKOU_KBN				AS 流通加工区分
	   ,BIKO						AS ヘッダ備考
	   ,JUCHU_COMMENT				AS 受注コメント
	   ,SOKO_COMMENT				AS 倉庫コメント
	   ,PROJECT_CD					AS プロジェクトコード
	   ,HANBAI_AREA_CD				AS 販売エリアコード
	   ,YOYAKU_KAIHO_KIGEN			AS 予約解放期限
	   ,HINMOKU						AS 品目
	   ,LOT_NUM						AS ロット数
	   ,BARA_NUM					AS バラ数
	   ,SUITEI_KAKUTEI_KBN			AS 推定確定区分
	   ,KAKERITU					AS 掛率
	   ,HIKIATE_STATE				AS 引当状態
	   ,DTL_GEDAIMACHI_FLG			AS 明細下代待ちフラグ
	   ,DTL_SOKO_CD					AS 明細倉庫コード
	   ,TEKIYO						AS 摘要
	   ,DTL_SHUKKASAKI_CD			AS 明細出荷先コード
	   ,DTL_SHUKKA_YOTEI_DATE		AS 明細出荷予定日
	   ,DTL_SHITEI_NOHIN_DATE		AS 明細指定納品日
	   ,DTL_SEIKYU_KIJUN_DATE		AS 明細請求基準日
	   ,YOYAKU_DENPYO_NO			AS 予約伝票NO
	   ,YOYAKU_DENPYO_ENO			AS 予約伝票枝番
	   ,KAZEI_KBN					AS 課税区分
	   ,TORIHIKISAKI_TUKA_TANKA		AS 取引先通貨単価
	   ,RATE						AS レート
	   ,DTL_BIKO					AS 明細備考
	 
		FROM #tmp	
		WHERE 	ERROR_MSG IS NOT NULL
		ORDER BY LINE_NO

		--エラー行アリの場合、警告情報は取得しない。
		--警告なし(空レコード)として返す
		SELECT 0
		WHERE 1 = 0

		--エラー行アリの場合、登録伝票FROM、TOは(空レコード)として返す
		SELECT 0
		WHERE 1 = 0
	END
	ELSE
	BEGIN
		--エラーなし
		/*===============================受注番号採番処理START===============================*/
		--受注番号の採番を実行する
		DECLARE @INS_CNT	INT
		DECLARE @KETA		DECIMAL(2,0)
		DECLARE @GET_NO_S	DECIMAL(10,0) 
		DECLARE @GET_NO_E	DECIMAL(10,0)
		DECLARE @RET_STATUS INT

		--採番数を取得
		SELECT @INS_CNT = COUNT(*)
		FROM #tmpHdr

		--ストアドプロシージャー「GET_NEXT_SAIBAN_TIMEOUT_ON」を呼出し、番号を取得する
		EXEC @RET_STATUS = GET_NEXT_SAIBAN_TIMEOUT_ON @KAISHA_CD
											,'HKJC'
											,'@NONPREFIX@'
											,@INS_CNT
											,@USER_ID
											,@PGM_CD
											,@KETA OUTPUT
											,@GET_NO_S OUTPUT
											,@GET_NO_E OUTPUT
			
		--戻り値が0以外の場合は採番失敗
		IF(@RET_STATUS <> 0)
		BEGIN
			--変数リターンコードに2を設定し
			SET @RetCd = 2
			--終了処理にジャンプ
			GOTO END_PROC
		END
			
		--#tmpHdrに伝票番号を設定する
		--伝票番号：RIGHT(@KETA数分0埋め + @GET_NO_S(採番開始番号) + #tmpHdr行番号 - 1), @KETA)
		UPDATE #tmpHdr
		SET DENPYO_NO = #tmpHdrNo.DENPYO_NO
		FROM #tmpHdr
		INNER JOIN (SELECT GROUP_KEY
							,RIGHT(REPLICATE('0', @KETA)  + CONVERT(NVARCHAR, (@GET_NO_S + ROW_NUMBER() OVER (ORDER BY GROUP_KEY) -1)) , @KETA) AS DENPYO_NO
					FROM #tmpHdr
					) #tmpHdrNo
			ON #tmpHdr.GROUP_KEY = #tmpHdrNo.GROUP_KEY

		--変数の初期化
		SET @INS_CNT = NULL
		SET @KETA = NULL
		SET @GET_NO_S = NULL 
		SET @GET_NO_E = NULL
		SET @RET_STATUS = NULL		

		--#tmpに伝票番号を設定する
		UPDATE #tmp
		SET DENPYO_NO = #tmpHdr.DENPYO_NO
		FROM #tmp
		INNER JOIN #tmpHdr
			ON #tmp.GROUP_KEY = #tmpHdr.GROUP_KEY

		--#tmpに受注枝番を設定する
		UPDATE #tmp
		SET DENPYO_ENO = T_ENO.ENO
		FROM #tmp
		INNER JOIN (SELECT LINE_NO
					      ,ROW_NUMBER() OVER(PARTITION BY #tmp.GROUP_KEY ORDER BY #tmp.LINE_NO) AS ENO
					FROM #tmp
				   ) T_ENO
			ON #tmp.LINE_NO = T_ENO.LINE_NO
		/*===============================受注番号採番処理END===============================*/

		/*===============================登録処理START===============================*/
		
		--現在日時を変数に設定
		DECLARE @NOW DATETIME = GETDATE()

		--受注ヘッダ
		INSERT INTO HK_TBL_JUCHU_HDR
		(KAISHA_CD
		,JUCHU_NO
		,KAKUTEI_KBN
		,WF_SHONIN_STATUS
		,JUCHU_DATE
		,TOKUISAKI_CD
		,TOKUISAKI_TANTOSHA_NM
		,TANTO_BUSHO_CD
		,TANTOSHA_CD
		,PROJECT_CD
		,HAMBAI_AREA_CD
		,TEKIYO
		,SHUKKASAKI_CD
		,SEIKYUSAKI_CD
		,KAISHU_HOHO_PATTERN
		,SEIKYU_DATE
		,SHUKKA_YOTEI_DATE
		,SHUKKO_KBN
		,UCHIZEI_SOTOZEI_KBN
		,SHOHIZEI_KBN
		,HENPIN_MOTO_SHIRE_NO
		,HENKYAKU_KIGEN
		,CHOKUSO_HACCHU_NO
		,HDR_JIDO_BUNNO_FLG
		,CANCEL_FLG
		,CANCEL_RIYU
		,CANCEL_TM
		,EDI_FLG
		,EDI_TORIHIKI_NO
		,EDI_TORIKOMI_FLG
		,EDI_TORIHIKI_CANCEL_FLG
		,EDI_SEND_STATUS
		,EDI_TORIHIKI_RIREKI_SEQ
		,DEL_FLG
		,INS_TM
		,INS_SHAIN_CD
		,INS_PGM_CD
		,UPD_TM
		,UPD_SHAIN_CD
		,UPD_PGM_CD
		)
		SELECT @KAISHA_CD						--会社コード
			  ,HDR.DENPYO_NO					--伝票番号
			  ,NULL								--確定区分
			  ,'01'								--WF承認状態：未申請
			  ,CONVERT(DATE, HDR.JUCHU_DATE)	--受注日
			  ,HDR.TOKUISAKI_CD					--得意先コード
			  ,HDR.TANTOSHA_NM					--得意先担当者名
			  ,ISNULL(HDR.TANTO_BUSHO_CD, TOKUI.KITEI_TANTO_BUSHO_CD)	--担当部署コード
			  ,ISNULL(HDR.TANTOSHA_CD, TOKUI.KITEI_TANTOSHA_CD)			--担当者コード
			  ,HDR.PROJECT_CD					--プロジェクトコード
			  ,HDR.HANBAI_AREA_CD				--販売エリアコード
			  ,CASE WHEN HDR.JUCHU_KBN = '03'	--摘要
						THEN '倉庫移動'
					ELSE NULL
			   END
			  ,HDR.SHUKKASAKI_CD				--出荷先コード
			  ,HDR.SEIKYUSAKI_CD				--請求先コード
			  ,SEIKYU_HOHO.KAISHU_HOHO_PATTERN	--回収方法パターン
			  ,CASE WHEN HDR.JUCHU_KBN = '01'	--請求日
						THEN CASE --都度の場合
								  WHEN SEIKYU_HOHO.SEIKYU_TYPE = '99'
										THEN --請求基準日がNULLの場合、出荷予定日
											 CONVERT(DATE,ISNULL(HDR.HDR_SEIKYU_KIJUN_DATE, HDR.SHUKKA_YOTEI_DATE))
										--都度でない場合
										ELSE NULL
							 END
					ELSE NULL
			   END
			  ,CONVERT(DATE, HDR.SHUKKA_YOTEI_DATE)	--出荷予定日
			  ,HDR.SHUKKO_KBN					--出庫区分
			  ,'01'								--内税外税区分：外税固定
			  ,TORIHIKI.JUCHU_SHOHIZEI_KBN		--受注消費税区分：取引先の受注消費税区分
			  ,NULL								--返品元仕入NO
			  ,NULL								--返却期限
			  ,NULL								--直送発注NO
			  ,0								--自動分納フラグ：「しない」固定(使用しない
			  ,0								--取消フラグ
			  ,NULL								--取消理由
			  ,NULL								--取消日時
			  ,0								--EDIフラグ
			  ,NULL								--EDI取引番号
			  ,0								--EDI取込フラグ
			  ,0								--EDI取引キャンセルフラグ
			  ,0								--EDI送信状態
			  ,NULL								--EDI取引履歴シーケンス番号
			  ,0								--削除フラグ
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
		FROM #tmpHdr HDR
		LEFT JOIN BC_MST_KAISHU_HOHO SEIKYU_HOHO
			ON SEIKYU_HOHO.KAISHA_CD = @KAISHA_CD
			AND SEIKYU_HOHO.SEIKYUSAKI_CD = HDR.SEIKYUSAKI_CD
			AND SEIKYU_HOHO.KAISHU_HOHO_FLG = 1	--優先回収方法
		LEFT JOIN BC_MST_TORIHIKISAKI TORIHIKI
			ON TORIHIKI.KAISHA_CD = @KAISHA_CD
			AND TORIHIKI.TORIHIKISAKI_CD = HDR.TOKUISAKI_CD
		LEFT JOIN BC_MST_TOKUISAKI TOKUI
			ON TOKUI.KAISHA_CD = @KAISHA_CD
			AND TOKUI.TOKUISAKI_CD = HDR.TOKUISAKI_CD

		--受注ヘッダ外貨
		INSERT INTO HK_TBL_JUCHU_HDR_GAIKA
		(KAISHA_CD
		,JUCHU_NO
		,TUKA_CD
		,DEL_FLG
		,INS_TM
		,INS_SHAIN_CD
		,INS_PGM_CD
		,UPD_TM
		,UPD_SHAIN_CD
		,UPD_PGM_CD
		)
		SELECT @KAISHA_CD
			  ,HDR.DENPYO_NO
			  ,TORIHIKI.TUKA_CD
			  ,0
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
		FROM  #tmpHdr HDR
		LEFT JOIN BC_MST_TORIHIKISAKI_GAIKA TORIHIKI
			ON TORIHIKI.KAISHA_CD = @KAISHA_CD
			AND TORIHIKI.TORIHIKISAKI_CD = HDR.TOKUISAKI_CD

		--受注ヘッダ拡張
		INSERT INTO HK_TBL_JUCHU_HDR_EX
		(KAISHA_CD
		,JUCHU_NO
		,JUCHU_KBN
		,YOYAKU_KAIHO_KIGEN
		,TOKUISAKI_DENPYO_NO
		,TOKUISAKI_HACCHU_NO
		,SEIKYU_KIJUN_DATE
		,SOKO_CD
		,NOHIN_KBN
		,SHITEI_NOHIN_DATE
		,SHITEI_NOHIN_JIKOKU
		,HAISO_KBN
		,KESSAI_HOHO
		,RYUTU_KAKO_KBN
		,URIBA_NM
		,NAISEN_NO
		,HIKIATE_CHOSEI_FUYO_FLG
		,GEDAI_MACHI_FLG
		,SAMPLE_SYUKKA_FLG
		,BUNRUI_CD
		,JUCHU_COMMENT
		,SOKO_COMMENT
		,BIKO
		,INS_TM
		,INS_SHAIN_CD
		,INS_PGM_CD
		,UPD_TM
		,UPD_SHAIN_CD
		,UPD_PGM_CD
		)
		SELECT @KAISHA_CD
			  ,HDR.DENPYO_NO
			  ,HDR.JUCHU_KBN
			  ,CASE WHEN JUCHU_KBN = '02'	--予約解放期限
							THEN DATEADD(DAY, 14, CONVERT(DATE, HDR.SHUKKA_YOTEI_DATE))
					ELSE NULL
			   END
			  ,HDR.TOKUISAKI_DENPYO_NO
			  ,HDR.TOKUISAKI_HACCHU_NO
			  --請求基準日がNULLの場合、出荷予定日
			  ,CONVERT(DATE, ISNULL(HDR_SEIKYU_KIJUN_DATE, SHUKKA_YOTEI_DATE))
			  ,HDR.SOKO_CD
			  --納品区分がNULLの場合、出荷先の納品区分
			  ,CASE 
			  WHEN ISNULL(HDR.NOHIN_KBN, SHUKKA.NOHIN_KBN) IS NULL THEN '99'
			  ELSE ISNULL(HDR.NOHIN_KBN, SHUKKA.NOHIN_KBN)
			  END 
			  ,CONVERT(DATE, HDR.SHITEI_NOHIN_DATE)
			  ,HDR.SHITEI_NOHIN_JIKOKU
			  --配送区分がNULLの場合、出荷先の配送区分
			  ,ISNULL(HDR.HAISOU_KBN, SHUKKA.HAISO_KBN)
			  ,KESSAI_HOHO
			  --流通加工区分がNULLの場合、得意先の先流通加工区分
			  ,ISNULL(HDR.RYUTU_KAKOU_KBN, TOKUISAKI.NOHINSHO_RYUTU_KAKO_KBN)
			  ,HDR.URIBA_NM
			  ,HDR.NAISEN_NO
			  ,ISNULL(HDR.HIKIATE_CHOSEI_FUYO_FLG, 0)
			  ,ISNULL(HDR.HDR_GEDAIMACHI_FLG, 0)
			  ,ISNULL(HDR.SAMPLE_SHUKKA_FLG, 0)
			  ,HDR.BUNRUI_CD
			  ,HDR.JUCHU_COMMENT
			  ,HDR.SOKO_COMMENT
			  ,HDR.BIKO
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
		FROM #tmpHdr HDR
		LEFT JOIN BC_MST_SHUKKASAKI_EX SHUKKA
			ON SHUKKA.KAISHA_CD = @KAISHA_CD
			AND SHUKKA.SHUKKASAKI_CD = HDR.SHUKKASAKI_CD
		LEFT JOIN BC_MST_TOKUISAKI_EX TOKUISAKI
			ON TOKUISAKI.KAISHA_CD = @KAISHA_CD
			AND TOKUISAKI.TOKUISAKI_CD = HDR.TOKUISAKI_CD

		--受注伝票明細
		INSERT INTO HK_TBL_JUCHU_DTL
		(KAISHA_CD
		,JUCHU_NO
		,JUCHU_ENO
		,URIAGE_KBN
		,SHUKKO_KBN
		,HIKIATE_KBN
		,KAKUTEI_KBN
		,HINMOKU_SEQ
		,SHUKKASAKI_CD
		,LOT
		,SOKO_CD
		,AZUKARI_SOKO_CD
		,AZUKE_SOKO_CD
		,SHOHIN_LOT
		,NYUKA_YOTEI_NO
		,SHUKKA_YOTEI_DATE
		,NOHIN_YOTEI_DATE
		,KENSHU_YOTEI_DATE
		,IRISU
		,HAKOSU
		,NISUGATA_RENBAN
		,SURYO
		,TANI_GENKA
		,GENKA
		,TANKA
		,STD_TANKA
		,TANKA_KAKERITSU
		,KINGAKU
		,SHOHIZEI
		,TAX_RATE
		,KAZEI_KBN
		,KEIJO_STD_KBN
		,TEKIYO
		,BIKO
		,SHOKUTI_HINMOKU_NM
		,EDI_KEPPIN_FLG
		,GTIN_KBN_CD
		,TOKUISAKI_SHOHIN_CD
		,EDI_JUCHU_SURYO
		,TAX_SITEI_KBN
		,SET_NYUKA_YOTEI_SEQ
		,JIDO_BUNNO_FLG
		,TANI_GENKA_FLG
		,DEL_FLG
		,INS_TM
		,INS_SHAIN_CD
		,INS_PGM_CD
		,UPD_TM
		,UPD_SHAIN_CD
		,UPD_PGM_CD
		)
		SELECT @KAISHA_CD			--会社コード
			  ,DENPYO_NO			--伝票番号
			  ,DENPYO_ENO			--枝番
			  ,NULL					--売上区分
			  ,#tmp.SHUKKO_KBN			--出庫区分
			  ,HIKIATE_STATE		--引当状態
			  ,CASE WHEN ISNULL(DTL_GEDAIMACHI_FLG, ISNULL(HDR_GEDAIMACHI_FLG, 0)) = '1'		--推定確定区分
							--下代待ちは推定
							THEN '01'
					ELSE SUITEI_KAKUTEI_KBN
			   END
			  ,#tmp.HINMOKU_SEQ		--品目SEQ
			  ,DTL_SHUKKASAKI_CD	--出荷先コード
			  ,NULL					--ロット
			  ,DTL_SOKO_CD			--倉庫コード
			  --預かり売上の場合のみ設定
			  ,CASE WHEN #tmp.SHUKKO_KBN = '03'	--預かり倉庫コード
							THEN AZUKE_AZUKARI_IDO_SOKO_CD
					ELSE NULL
			   END
			  --預け出庫の場合のみ設定
			  ,CASE WHEN #tmp.SHUKKO_KBN = '06'	--預け倉庫コード
							THEN AZUKE_AZUKARI_IDO_SOKO_CD
					ELSE NULL
			   END
			  ,NULL						--商品ロット
			  ,NULL						--入荷予定NO
			  ,CONVERT(DATE, DTL_SHUKKA_YOTEI_DATE)	--出荷予定日
			  ,CONVERT(DATE, DTL_SHITEI_NOHIN_DATE)	--納品予定日
			  ,NULL						--検収予定日
			  ,HINMOKU.STD_IRISU		--入数(品目標準入数)
			  ,NULL						--箱数
			  ,NULL						--似姿連番
			  ,SURYO					--数量
			  ,NULL						--単位原価
			  ,NULL						--原価
			  --預かり出庫、預け出庫は単価0
			  ,CASE WHEN #tmp.SHUKKO_KBN IN ('04', '06')
							THEN 0
					ELSE JUCHU_TANKA
			   END
			  ,TANKA.SOTOZEI_TANKA		--標準単価
			  ,KAKERITU					--掛率
			  --預かり出庫、預け出庫は金額0
			  ,CASE WHEN #tmp.SHUKKO_KBN IN ('04', '06')
							THEN 0
					ELSE dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD, #tmp.TOKUISAKI_CD, JUCHU_TANKA * SURYO, 1, 0)
			   END
			  --預かり出庫、預け出庫は消費税0
			  ,CASE WHEN #tmp.SHUKKO_KBN IN ('04', '06')
							THEN 0
					ELSE dbo.CO_FUNC_HASU_SHORI((JUCHU_TANKA * SURYO) * TAX_RATE, TORI.JUCHU_SHOHIZEI_HASU_KBN, 0)
			   END
			  ,TAX_RATE					--税率
			  ,#tmp.KAZEI_KBN				--課税区分
			  ,'01'						--計上基準区分：出荷基準固定
			  ,TEKIYO					--摘要
			  ,DTL_BIKO					--備考
			  ,NULL						--諸口品目名
			  ,0						--EDI検品フラグ
			  ,'999'					--GTIN区分コード：画面の初期値
			  ,NULL						--得意先商品コード
			  ,0						--EDI受注数量
			  ,TAX_SITEI_KBN			--税率指定区分
			  ,NULL						--セット入荷予定SEQ
			  ,0						--自動分納フラグ
			  ,0						--単位原価フラグ
			  ,0						--削除フラグ
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
		FROM #tmp
		LEFT JOIN BC_MST_TANKA TANKA 
			ON TANKA.KAISHA_CD = @KAISHA_CD
			AND TANKA.HINMOKU_SEQ = #tmp.HINMOKU_SEQ
			AND DATEDIFF(DAY, START_DATE, DTL_SHUKKA_YOTEI_DATE) >= 0
			AND DATEDIFF(DAY, END_DATE, DTL_SHUKKA_YOTEI_DATE) <= 0
		LEFT JOIN BC_MST_TORIHIKISAKI TORI
			ON TORI.KAISHA_CD = @KAISHA_CD
			AND TORI.TORIHIKISAKI_CD = #tmp.TOKUISAKI_CD
		LEFT JOIN BC_MST_HINMOKU_KANRI HINKAN
			ON HINKAN.KAISHA_CD = @KAISHA_CD
			AND HINKAN.HINMOKU_SEQ = #tmp.HINMOKU_SEQ
		LEFT JOIN BC_MST_HINMOKU HINMOKU
			ON HINMOKU.KAISHA_CD = HINKAN.KAISHA_CD
			AND HINMOKU.HINMOKU_CD = HINKAN.HINMOKU_CD

		--受注伝票明細外貨
		INSERT INTO HK_TBL_JUCHU_DTL_GAIKA
		(KAISHA_CD
		,JUCHU_NO
		,JUCHU_ENO
		,RATETYPE_CD
		,RATE
		,TUKA_TANKA
		,TUKA_KINGAKU
		,DEL_FLG
		,INS_TM
		,INS_SHAIN_CD
		,INS_PGM_CD
		,UPD_TM
		,UPD_SHAIN_CD
		,UPD_PGM_CD
		)
		SELECT @KAISHA_CD
			  ,DENPYO_NO
			  ,DENPYO_ENO
			  ,TORI_GAIKA.RATETYPE_CD
			  ,#tmp.RATE
			   --預かり出庫、預け出庫は単価0
			  ,CASE WHEN #tmp.SHUKKO_KBN IN ('04', '06')
							THEN 0
					ELSE CONVERT(DECIMAL(14,4), #tmp.TORIHIKISAKI_TUKA_TANKA)
			   END
			   --預かり出庫、預け出庫は金額0
			  ,CASE WHEN #tmp.SHUKKO_KBN IN ('04', '06')
							THEN 0
					ELSE dbo.CO_FUNC_HASU_SHORI_EX(#tmp.TORIHIKISAKI_TUKA_TANKA * SURYO ,'01' ,TUKA.DECIMAL_LENGTH)
			   END
			  ,0
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
		FROM #tmp
		LEFT JOIN BC_MST_TORIHIKISAKI_GAIKA TORI_GAIKA
			ON TORI_GAIKA.KAISHA_CD = @KAISHA_CD
			AND TORI_GAIKA.TORIHIKISAKI_CD = #tmp.TOKUISAKI_CD
		LEFT JOIN BC_MST_TUKA TUKA
			ON TORI_GAIKA.KAISHA_CD = TUKA.KAISHA_CD
			AND TORI_GAIKA.TUKA_CD = TUKA.TUKA_CD
			AND TUKA.DEL_FLG = 0
			AND TUKA.MUKOU_FLG = 0

		--受注伝票明細拡張
		INSERT INTO HK_TBL_JUCHU_DTL_EX
		(KAISHA_CD
		,JUCHU_NO
		,JUCHU_ENO
		,YOYAKU_DENPYO_NO
		,YOYAKU_DENPYO_ENO
		,SEIKYU_KIJUN_DATE
		,CHUMONSU
		,CHUMON_KINGAKU
		,CHUMON_LOT_NUM
		,CHUMON_BARA_NUM
		,KAKERITU_REF_KBN
		,HIKIATE_KBN
		,KANRYO_KBN
		,IDO_SAKI_SOKO_CD
		,JAN_SEAL_EXPORT_FLG
		,GEDAI_MACHI_FLG
		,INS_TM
		,INS_SHAIN_CD
		,INS_PGM_CD
		,UPD_TM
		,UPD_SHAIN_CD
		,UPD_PGM_CD
		)
		SELECT @KAISHA_CD
			  ,DENPYO_NO
			  ,DENPYO_ENO
			  ,CASE WHEN JUCHU_KBN IN ('01', '03')	--予約伝票NO
						THEN #tmp.YOYAKU_DENPYO_NO
					ELSE NULL
			   END
			  ,CASE WHEN JUCHU_KBN IN ('01', '03')	--予約伝票枝番
						THEN #tmp.YOYAKU_DENPYO_ENO
					ELSE NULL
			   END
			  ,CONVERT(DATE, DTL_SEIKYU_KIJUN_DATE)
			  ,(CONVERT(DECIMAL, ISNULL(LOT_NUM, 0)) * ISNULL(HIN.STD_IRISU, 0)) + CONVERT(DECIMAL, ISNULL(BARA_NUM, 0))
			   --預かり出庫、預け出庫は注文金額0
			  ,CASE WHEN #tmp.SHUKKO_KBN IN ('04', '06')
							THEN 0
					WHEN  TORI_GAIKA.TUKA_CD = @TUKA_CD
					        THEN dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD
												,#tmp.TOKUISAKI_CD 
												,(((CONVERT(DECIMAL, ISNULL(LOT_NUM, 0)) * ISNULL(HIN.STD_IRISU, 0)) + CONVERT(DECIMAL, ISNULL(BARA_NUM, 0))) * JUCHU_TANKA)	 --注文金額=注文数*単価
												,1
												,0)
					ELSE
							--外貨の場合
							dbo.CO_FUNC_HASU_SHORI_EX(#tmp.TORIHIKISAKI_TUKA_TANKA * ((CONVERT(DECIMAL, ISNULL(LOT_NUM, 0)) * ISNULL(HIN.STD_IRISU, 0)) + CONVERT(DECIMAL, ISNULL(BARA_NUM, 0))) ,'01' ,TUKA.DECIMAL_LENGTH)
			   END 
			  ,LOT_NUM
			  ,BARA_NUM
			  ,KAKERITU_REF_KBN --掛率参照区分
			  ,HIKIATE_KBN		--引当区分
			  ,'01' --完了区分:【未出荷】固定
			  ,CASE WHEN JUCHU_KBN = '03'		--移動先倉庫コード
						THEN AZUKE_AZUKARI_IDO_SOKO_CD
					ELSE NULL
			   END
			  ,NULL	--JANシール出力フラグ
			  ,0	--下代待ちフラグ
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
		FROM #tmp
		LEFT JOIN BC_MST_HINMOKU_KANRI HINKAN
			ON HINKAN.KAISHA_CD = @KAISHA_CD
			AND HINKAN.HINMOKU_SEQ = #tmp.HINMOKU_SEQ
		LEFT JOIN BC_MST_HINMOKU HIN
			ON HIN.KAISHA_CD = HINKAN.KAISHA_CD
			AND HIN.HINMOKU_CD = HINKAN.HINMOKU_CD
		LEFT JOIN BC_MST_TORIHIKISAKI_GAIKA TORI_GAIKA
			ON TORI_GAIKA.KAISHA_CD = @KAISHA_CD
			AND TORI_GAIKA.TORIHIKISAKI_CD = #tmp.TOKUISAKI_CD
		LEFT JOIN BC_MST_TUKA TUKA
			ON TORI_GAIKA.KAISHA_CD = TUKA.KAISHA_CD
			AND TORI_GAIKA.TUKA_CD = TUKA.TUKA_CD
			AND TUKA.DEL_FLG = 0
			AND TUKA.MUKOU_FLG = 0
		
		--出荷予定
		INSERT INTO HK_TBL_SHUKKA_YOTEI
		(KAISHA_CD
		,SHUKKA_YOTEI_NO
		,JUCHU_NO
		,JUCHU_ENO
		,SHUKKO_KBN
		,WF_SHONIN_STATUS
		,NYUKA_YOTEI_NO
		,ZAIKO_SEQ
		,HINMOKU_SEQ
		,SHOHIN_LOT
		,SHUKKA_YOTEI_DATE
		,NOHIN_YOTEI_DATE
		,KENSHU_YOTEI_DATE
		,SHUKKASAKI_CD
		,JISSEKI_SURYO
		,SURYO
		,SHUKKO_SURYO
		,GOUKAKU_SURYO
		,FUGOUKAKU_SURYO
		,FUGOUKAKU_KBN
		,TEKIYO
		,KENPIN_STATUS
		,KAKUNIN_MOSIOKURI
		,KANRYO_FLG
		,KENPIN_DATE
		,SHUKKO_DATE
		,NOHIN_DATE
		,KENSHU_DATE
		,IRISU
		,HAKOSU
		,NISUGATA_RENBAN
		,SHISAN_KEIJO_END_DATE
		,JISSEKI_KINGAKU
		,KINGAKU
		,JISSEKI_SHOHIZEI
		,SHOHIZEI
		,TAX_RATE
		,SHUKKA_SHIJI_NO
		,TAISHOGAI_FLG
		,KEIJO_STD_KBN
		,URIAGE_NO
		,URIAGE_DTL_KEY
		,BUNNO_MOTO_NO
		,EDI_SEND_STATUS
		,BUNNO_FLG
		,MEMO
		,DEL_FLG
		,INS_TM
		,INS_SHAIN_CD
		,INS_PGM_CD
		,UPD_TM
		,UPD_SHAIN_CD
		,UPD_PGM_CD
		)
		SELECT @KAISHA_CD
			  --伝票番号 + 0埋め4桁の連番
			  ,DENPYO_NO + RIGHT('0000' + CONVERT(NVARCHAR, ROW_NUMBER() OVER(PARTITION BY #tmp.GROUP_KEY ORDER BY #tmp.LINE_NO)), 4)	--出荷予定NO
			  ,DENPYO_NO				--受注NO
			  ,DENPYO_ENO				--受注枝番
			  ,#tmp.SHUKKO_KBN			--出庫区分
			  ,'01'						--WF承認状態
			  ,CASE WHEN JUCHU_KBN IN ('01', '03') 	--入荷予定NO
						THEN shukka.NYUKA_YOTEI_NO
					ELSE NULL
			   END
			  ,shukka.ZAIKO_SEQ			--在庫SEQ
			  ,shukka.HINMOKU_SEQ		--品目SEQ
			  ,NULL						--商品ロット
			  ,CONVERT(DATE, DTL_SHUKKA_YOTEI_DATE)	--出荷予定日
			  ,CONVERT(DATE, DTL_SHITEI_NOHIN_DATE)	--納品予定日
			  ,NULL						--検収予定日
			  ,DTL_SHUKKASAKI_CD		--出荷先コード
			  ,CASE WHEN HIN.ZAIKO_KANRI_FLG = 1	--実績数量
						THEN NULL
					ELSE shukka.SURYO
			   END
			  ,shukka.SURYO				--数量
			  ,NULL						--出庫数量
			  ,NULL						--合格数量
			  ,NULL						--不合格数量
			  ,NULL						--不合格区分
			  ,NULL						--摘要
			  ,NULL						--検品ステータス
			  ,NULL						--確認申送
			  ,0						--完了フラグ
			  ,CONVERT(DATE, DTL_SHITEI_NOHIN_DATE)	--検品日
			  ,NULL						--出庫日
			  ,CONVERT(DATE, DTL_SHITEI_NOHIN_DATE)	--納品日
			  ,NULL						--検収日
			  ,HIN.STD_IRISU			--入数(品目の標準入数)
			  ,NULL						--箱数
			  ,NULL						--似姿連番
			  ,CONVERT(DATE, DTL_SHITEI_NOHIN_DATE)	--資産計上終了日
			  --預かり出庫、預け出庫は実績金額0
			  ,CASE WHEN #tmp.SHUKKO_KBN IN ('04', '06')
							THEN 0
					ELSE dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD, #tmp.TOKUISAKI_CD, shukka.SURYO * #tmp.JUCHU_TANKA, 1, 0)
			   END
			  --預かり出庫、預け出庫は金額0
			  ,CASE WHEN #tmp.SHUKKO_KBN IN ('04', '06')
							THEN 0
					ELSE dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD, #tmp.TOKUISAKI_CD, shukka.SURYO * #tmp.JUCHU_TANKA, 1, 0)	--金額
			   END
			  --預かり出庫、預け出庫は実績消費税0
			  ,CASE WHEN #tmp.SHUKKO_KBN IN ('04', '06')
							THEN 0
					ELSE dbo.CO_FUNC_HASU_SHORI(shukka.SURYO * #tmp.JUCHU_TANKA * TAX_RATE, TORI.JUCHU_SHOHIZEI_HASU_KBN, 0)	--実績消費税
			   END
			  --預かり出庫、預け出庫は消費税0
			  ,CASE WHEN #tmp.SHUKKO_KBN IN ('04', '06')
							THEN 0
					ELSE dbo.CO_FUNC_HASU_SHORI(shukka.SURYO * #tmp.JUCHU_TANKA * TAX_RATE, TORI.JUCHU_SHOHIZEI_HASU_KBN, 0)	--消費税
			   END
			  ,TAX_RATE					--税率
			  ,NULL						--出荷指示NO
			  ,CASE WHEN HIN.ZAIKO_KANRI_FLG = 1	--対象外フラグ
						THEN 0
					ELSE 1
			   END
			   ,'01'					--計上基準区分(出荷基準)
			   ,NULL					--売上NO
			   ,NULL					--売上明細連番
			   ,NULL					--分納元NO
			   ,0						--EDI送信状態
			   ,0						--分納フラグ
			   ,NULL					--メモ
			   ,0						--削除フラグ
			   ,@NOW
			   ,@USER_ID
			   ,@PGM_CD
			   ,@NOW
			   ,@USER_ID
			   ,@PGM_CD
		FROM #tmpShukkaYotei shukka
		INNER JOIN #tmp
			ON #tmp.LINE_NO = shukka.LINE_NO
		LEFT JOIN BC_MST_HINMOKU_KANRI HINKAN
			ON HINKAN.KAISHA_CD = @KAISHA_CD
			AND HINKAN.HINMOKU_SEQ = #tmp.HINMOKU_SEQ
		LEFT JOIN BC_MST_HINMOKU HIN
			ON HIN.KAISHA_CD = HINKAN.KAISHA_CD
			AND HIN.HINMOKU_CD = HINKAN.HINMOKU_CD
		LEFT JOIN BC_MST_TORIHIKISAKI TORI
			ON TORI.KAISHA_CD = @KAISHA_CD
			AND TORI.TORIHIKISAKI_CD = #tmp.TOKUISAKI_CD

		--出荷予定外貨
		INSERT INTO HK_TBL_SHUKKA_YOTEI_GAIKA
		(KAISHA_CD
		,SHUKKA_YOTEI_NO
		,JISSEKI_RATE
		,RATE
		,JISSEKI_TUKA_KINGAKU
		,TUKA_KINGAKU
		,DEL_FLG
		,INS_TM
		,INS_SHAIN_CD
		,INS_PGM_CD
		,UPD_TM
		,UPD_SHAIN_CD
		,UPD_PGM_CD
		)
		SELECT @KAISHA_CD
			  ,DENPYO_NO + RIGHT('0000' + CONVERT(NVARCHAR, ROW_NUMBER() OVER(PARTITION BY GROUP_KEY ORDER BY #tmp.LINE_NO)), 4)
			  ,#tmp.RATE
			  ,#tmp.RATE
			  --預かり出庫、預け出庫は金額0
			  ,CASE WHEN #tmp.SHUKKO_KBN IN ('04', '06')
							THEN 0
					ELSE CASE WHEN CONVERT(DECIMAL(7, 3),#tmp.RATE) = 1 THEN dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD, #tmp.TOKUISAKI_CD, shukka.SURYO * #tmp.JUCHU_TANKA, 1, 0)
					     ELSE dbo.CO_FUNC_HASU_SHORI_EX(#tmp.TORIHIKISAKI_TUKA_TANKA * shukka.SURYO ,'01' ,TUKA.DECIMAL_LENGTH) 
					END
			   END
			   --預かり出庫、預け出庫は金額0
			  ,CASE WHEN #tmp.SHUKKO_KBN IN ('04', '06')
							THEN 0
					ELSE CASE WHEN CONVERT(DECIMAL(7, 3),#tmp.RATE) = 1 THEN dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD, #tmp.TOKUISAKI_CD, shukka.SURYO * #tmp.JUCHU_TANKA, 1, 0)
					     ELSE dbo.CO_FUNC_HASU_SHORI_EX(#tmp.TORIHIKISAKI_TUKA_TANKA * shukka.SURYO ,'01' ,TUKA.DECIMAL_LENGTH) 
					END
			   END
			  ,0
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
		FROM #tmpShukkaYotei shukka
		INNER JOIN #tmp
			ON #tmp.LINE_NO = shukka.LINE_NO
		LEFT JOIN BC_MST_TORIHIKISAKI_GAIKA TORI_GAIKA
			ON TORI_GAIKA.KAISHA_CD = @KAISHA_CD
			AND TORI_GAIKA.TORIHIKISAKI_CD = #tmp.TOKUISAKI_CD
		LEFT JOIN BC_MST_TUKA TUKA
			ON TORI_GAIKA.KAISHA_CD = TUKA.KAISHA_CD
			AND TORI_GAIKA.TUKA_CD = TUKA.TUKA_CD
			AND TUKA.DEL_FLG = 0
			AND TUKA.MUKOU_FLG = 0

		--出荷予定拡張
		INSERT INTO HK_TBL_SHUKKA_YOTEI_EX
		(KAISHA_CD
		,SHUKKA_YOTEI_NO
		,YOYAKU_DENPYO_NO
		,YOYAKU_DENPYO_ENO
		,SHUKKA_JISSEKIZUMI_FLG
		,INS_TM
		,INS_SHAIN_CD
		,INS_PGM_CD
		,UPD_TM
		,UPD_SHAIN_CD
		,UPD_PGM_CD
		)
		SELECT @KAISHA_CD
			  ,DENPYO_NO + RIGHT('0000' + CONVERT(NVARCHAR, ROW_NUMBER() OVER(PARTITION BY GROUP_KEY ORDER BY #tmp.LINE_NO)), 4)
			  ,CASE WHEN JUCHU_KBN IN ('01', '03')	--予約伝票NO
						THEN shukka.YOYAKU_JUCHU_NO
					ELSE NULL
			   END
			  ,CASE WHEN JUCHU_KBN IN ('01', '03')	--予約伝票枝番
						THEN shukka.YOYAKU_JUCHU_ENO
					ELSE NULL
			   END
			  ,0
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
		FROM #tmpShukkaYotei shukka
		INNER JOIN #tmp
			ON #tmp.LINE_NO = shukka.LINE_NO

		/***********倉庫移動時の発注情報、倉庫移動情報作成START***********/
		--発注番号の採番、庫移動NOの採番を実行する

		--倉庫移動採番用に変数追加
		DECLARE @KETA_SOKO		DECIMAL(2,0)
		DECLARE @GET_NO_S_SOKO	DECIMAL(10,0) 
		DECLARE @GET_NO_E_SOKO	DECIMAL(10,0)
		DECLARE @RET_STATUS_SOKO INT

		--採番数を取得
		SELECT @INS_CNT = COUNT(*)
		FROM #tmpHdr
		WHERE #tmpHdr.JUCHU_KBN = '03'

		--ストアドプロシージャー「GET_NEXT_SAIBAN」を呼出し、発注番号を取得する
		EXEC @RET_STATUS = GET_NEXT_SAIBAN @KAISHA_CD
											,'KBHC'
											,'@NONPREFIX@'
											,@INS_CNT
											,@USER_ID
											,@PGM_CD
											,@KETA OUTPUT
											,@GET_NO_S OUTPUT
											,@GET_NO_E OUTPUT
			
		--戻り値が0以外の場合は採番失敗
		IF(@RET_STATUS <> 0)
		BEGIN
			--変数リターンコードに3を設定し
			SET @RetCd = 3
			--終了処理にジャンプ
			GOTO END_PROC
		END

		--ストアドプロシージャー「GET_NEXT_SAIBAN」を呼出し、倉庫移動番号を取得する
		EXEC @RET_STATUS_SOKO = GET_NEXT_SAIBAN @KAISHA_CD
											,'ZKSI'
											,'@NONPREFIX@'
											,@INS_CNT
											,@USER_ID
											,@PGM_CD
											,@KETA_SOKO OUTPUT
											,@GET_NO_S_SOKO OUTPUT
											,@GET_NO_E_SOKO OUTPUT
			
		--戻り値が0以外の場合は採番失敗
		IF(@RET_STATUS_SOKO <> 0)
		BEGIN
			--変数リターンコードに3を設定し
			SET @RetCd = 4
			--終了処理にジャンプ
			GOTO END_PROC
		END

		--#tmpHdrに発注番号・倉庫移動NOを設定する
		--発注番号：RIGHT(@KETA数分0埋め + @GET_NO_S(採番開始番号) + #tmpHdr行番号 - 1), @KETA)
		--倉庫移動番号を：RIGHT(@KETA_SOKO数分0埋め + @GET_NO_S_SOKO(採番開始番号) + #tmpHdr行番号 - 1), @KETA_SOKO)
		UPDATE #tmpHdr
		SET HACCHU_NO = #tmpHdrNo.HACCHU_NO
			,SOKO_IDO_NO = #tmpHdrNo.SOKO_IDO_NO
		FROM #tmpHdr
		INNER JOIN (SELECT GROUP_KEY
							,RIGHT(REPLICATE('0', @KETA)  + CONVERT(NVARCHAR, (@GET_NO_S + ROW_NUMBER() OVER (ORDER BY GROUP_KEY) -1)) , @KETA) AS HACCHU_NO
							,RIGHT(REPLICATE('0', @KETA_SOKO)  + CONVERT(NVARCHAR, (@GET_NO_S_SOKO + ROW_NUMBER() OVER (ORDER BY GROUP_KEY) -1)) , @KETA_SOKO) AS SOKO_IDO_NO
					FROM #tmpHdr
					WHERE JUCHU_KBN = '03'
					) #tmpHdrNo
			ON #tmpHdr.GROUP_KEY = #tmpHdrNo.GROUP_KEY

		--#tmpHdrに倉庫移動番号を設定する
		--倉庫移動番号を：RIGHT(@KETA数分0埋め + @GET_NO_S(採番開始番号) + #tmpHdr行番号 - 1), @KETA)
		UPDATE #tmpHdr
		SET SOKO_IDO_NO = #tmpHdrNo.SOKO_IDO_NO
		FROM #tmpHdr
		INNER JOIN (SELECT GROUP_KEY
							,RIGHT(REPLICATE('0', @KETA)  + CONVERT(NVARCHAR, (@GET_NO_S + ROW_NUMBER() OVER (ORDER BY GROUP_KEY) -1)) , @KETA) AS SOKO_IDO_NO
					FROM #tmpHdr
					WHERE JUCHU_KBN = '03'
					) #tmpHdrNo
			ON #tmpHdr.GROUP_KEY = #tmpHdrNo.GROUP_KEY

		--変数の初期化
		SET @INS_CNT = NULL
		SET @KETA = NULL
		SET @GET_NO_S = NULL 
		SET @GET_NO_E = NULL
		SET @RET_STATUS = NULL
		SET @KETA_SOKO = NULL
		SET @GET_NO_S_SOKO = NULL
		SET @GET_NO_E_SOKO = NULL
		SET @RET_STATUS_SOKO = NULL
		/***********発注番号・倉庫移動NO採番処理END***********/

		--発注伝票ヘッダ
		INSERT INTO KB_TBL_HACCHU_HDR
		(KAISHA_CD
		,HACCHU_NO
		,KAKUTEI_KBN
		,WF_SHONIN_STATUS
		,HACCHU_DATE
		,SHIRESAKI_CD
		,SHIRESAKI_TANTOSHA_NM
		,TANTO_BUSHO_CD
		,TANTOSHA_CD
		,PROJECT_CD
		,TEKIYO
		,SHIHARAISAKI_CD
		,SHIHARAI_HOHO_PATTERN
		,SHIHARAI_DATE
		,SHUKKASAKI_CD
		,NYUKA_YOTEI_DATE
		,NYUKO_KBN
		,UCHIZEI_SOTOZEI_KBN
		,SHOHIZEI_KBN
		,HENPIN_MOTO_URIAGE_NO
		,JIDO_HACCHU_FLG
		,IKKATSU_HIKIATE_FLG
		,HDR_JIDO_BUNNO_FLG
		,CANCEL_FLG
		,CANCEL_RIYU
		,CANCEL_TM
		,EDI_FLG
		,EDI_SEND_STATUS
		,DEL_FLG
		,INS_TM
		,INS_SHAIN_CD
		,INS_PGM_CD
		,UPD_TM
		,UPD_SHAIN_CD
		,UPD_PGM_CD
		)
		SELECT @KAISHA_CD			--会社コード
			  ,HACCHU_NO			--発注NO
			  ,NULL					--推定確定区分
			  ,'01'					--WF承認状態
			  ,CONVERT(DATE, JUCHU_DATE)			--発注日
			  ,NULL					--仕入先コード
			  ,NULL					--仕入先担当者名
			  ,TANTO_BUSHO_CD		--担当部署コード
			  ,TANTOSHA_CD			--担当者コード
			  ,NULL					--プロジェクトコード
			  ,'倉庫移動'			--摘要
			  ,NULL					--支払先コード
			  ,NULL					--支払方法パターン
			  ,NULL					--支払日
			  ,NULL					--出荷先コード
			  ,CONVERT(DATE, SHITEI_NOHIN_DATE)	--入荷予定日
			  ,'40'					--入庫区分：倉庫移動
			  ,'01'					--内税外税区分
			  ,NULL					--消費税区分
			  ,NULL					--返品元売上NO
			  ,0					--自動発注フラグ
			  ,0					--一括引当フラグ
			  ,0					--自動分納フラグ
			  ,0					--取り消しフラグ
			  ,NULL					--取り消し理由
			  ,NULL					--取り消し時間
			  ,0					--EDIフラグ	
			  ,0					--EDI送信状態
			  ,0					--削除フラグ
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
		FROM #tmpHdr
		WHERE #tmpHdr.JUCHU_KBN = '03'

		--発注伝票ヘッダ外貨
		INSERT INTO KB_TBL_HACCHU_HDR_GAIKA
		(KAISHA_CD
		,HACCHU_NO
		,TUKA_CD
		,DEL_FLG
		,INS_TM
		,INS_SHAIN_CD
		,INS_PGM_CD
		,UPD_TM
		,UPD_SHAIN_CD
		,UPD_PGM_CD
		)
		SELECT @KAISHA_CD
			  ,HACCHU_NO
			  ,TORIHIKI.TUKA_CD
			  ,0
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
		FROM #tmpHdr HDR
		LEFT JOIN BC_MST_TORIHIKISAKI_GAIKA TORIHIKI
			ON TORIHIKI.KAISHA_CD = @KAISHA_CD
			AND TORIHIKI.TORIHIKISAKI_CD = HDR.TOKUISAKI_CD
		WHERE HDR.JUCHU_KBN = '03'

		--発注伝票ヘッダ拡張
		INSERT INTO KB_TBL_HACCHU_HDR_EX
		(KAISHA_CD
		,HACCHU_NO
		,SHOKAI_REPEAT_KBN
		,INS_TM
		,INS_SHAIN_CD
		,INS_PGM_CD
		,UPD_TM
		,UPD_SHAIN_CD
		,UPD_PGM_CD
		)
		SELECT @KAISHA_CD
			  ,HACCHU_NO
			  ,NULL
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
		FROM #tmpHdr
		WHERE #tmpHdr.JUCHU_KBN = '03'

		--発注伝票明細
		INSERT INTO KB_TBL_HACCHU_DTL
		(KAISHA_CD
		,HACCHU_NO
		,HACCHU_ENO
		,SHIRE_KBN
		,HINMOKU_SEQ
		,SHUKKASAKI_CD
		,SOKO_CD
		,SHOHIN_LOT
		,NYUKA_YOTEI_DATE
		,NYUKA_YOTEI_JI_KBN
		,KENSHU_YOTEI_DATE
		,IRISU
		,HAKOSU
		,NISUGATA_RENBAN
		,SURYO
		,TANKA
		,STD_TANKA
		,TANKA_KAKERITSU
		,KINGAKU
		,SHOHIZEI
		,TAX_RATE
		,KAZEI_KBN
		,KEIJO_STD_KBN
		,TEKIYO
		,BIKO
		,SHOKUTI_HINMOKU_NM
		,GTIN
		,GTIN_KBN_CD
		,TAX_SITEI_KBN
		,JIDO_BUNNO_FLG
		,DEL_FLG
		,INS_TM
		,INS_SHAIN_CD
		,INS_PGM_CD
		,UPD_TM
		,UPD_SHAIN_CD
		,UPD_PGM_CD
		)
		SELECT @KAISHA_CD						--会社コード
			  ,#tmpHdr.HACCHU_NO				--発注NO
			  ,ROW_NUMBER() OVER(PARTITION BY #tmp.GROUP_KEY ORDER BY #tmp.LINE_NO)	--枝番
			  ,'01'								--仕入区分
			  ,#tmp.HINMOKU_SEQ					--品目SEQ	
			  ,NULL								--出荷先コード
			  ,#tmp.AZUKE_AZUKARI_IDO_SOKO_CD	--倉庫コード(移動先)
			  ,NULL								--商品ロット
			  ,CONVERT(DATE,#tmp.DTL_SHITEI_NOHIN_DATE)			--入荷予定日
			  ,NULL								--入荷予定時区分
			  ,NULL								--検収予定日
			  ,NULL								--入数
			  ,NULL								--箱数
			  ,NULL								--似姿連番
			  ,SURYO							--数量
			  ,JUCHU_TANKA						--単価
			  ,TANKA.SOTOZEI_KONYU_TANKA		--標準単価
			  ,NULL								--単価掛率
			  ,dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD, #tmp.TOKUISAKI_CD, JUCHU_TANKA * SURYO, 1, 0)				--金額
			  ,dbo.CO_FUNC_HASU_SHORI((JUCHU_TANKA * SURYO) * TAX_RATE, TORI.JUCHU_SHOHIZEI_HASU_KBN, 0)	--消費税
			  ,TAX_RATE							--税率
			  ,KAZEI_KBN						--課税区分
			  ,'01'								--計上基準区分：入荷基準
			  ,'倉庫移動'						--摘要
			  ,DTL_BIKO							--備考
			  ,NULL								--諸口品目名
			  ,NULL								--GTIN
			  ,NULL								--GTIN区分コード
			  ,TAX_SITEI_KBN					--税率指定区分
			  ,0								--自動分納フラグ
			  ,0								--削除フラグ
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
		FROM #tmp
		LEFT JOIN #tmpHdr
			ON #tmp.GROUP_KEY = #tmpHdr.GROUP_KEY
		LEFT JOIN BC_MST_TANKA TANKA 
			ON TANKA.KAISHA_CD = @KAISHA_CD
			AND TANKA.HINMOKU_SEQ = #tmp.HINMOKU_SEQ
			AND DATEDIFF(DAY, START_DATE, #tmp.DTL_SHUKKA_YOTEI_DATE) >= 0
			AND DATEDIFF(DAY, END_DATE, #tmp.DTL_SHUKKA_YOTEI_DATE) <= 0
		LEFT JOIN BC_MST_TORIHIKISAKI TORI
			ON TORI.KAISHA_CD = @KAISHA_CD
			AND TORI.TORIHIKISAKI_CD = #tmp.TOKUISAKI_CD
		WHERE #tmp.JUCHU_KBN = '03'

		--発注伝票明細外貨
		INSERT INTO KB_TBL_HACCHU_DTL_GAIKA
		(KAISHA_CD
		,HACCHU_NO
		,HACCHU_ENO
		,RATETYPE_CD
		,RATE
		,TUKA_TANKA
		,TUKA_KINGAKU
		,DEL_FLG
		,INS_TM
		,INS_SHAIN_CD
		,INS_PGM_CD
		,UPD_TM
		,UPD_SHAIN_CD
		,UPD_PGM_CD
		)
		SELECT @KAISHA_CD
			  ,#tmpHdr.HACCHU_NO
			  ,ROW_NUMBER() OVER(PARTITION BY #tmp.GROUP_KEY ORDER BY #tmp.LINE_NO)
			  ,TORI_GAIKA.RATETYPE_CD
			  ,#tmp.RATE
			  ,TORIHIKISAKI_TUKA_TANKA
			  ,dbo.CO_FUNC_HASU_SHORI_EX(#tmp.TORIHIKISAKI_TUKA_TANKA * SURYO ,'01' ,TUKA.DECIMAL_LENGTH)
			  ,0
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
		FROM #tmp
		LEFT JOIN #tmpHdr
			ON #tmp.GROUP_KEY = #tmpHdr.GROUP_KEY
		LEFT JOIN BC_MST_TORIHIKISAKI_GAIKA TORI_GAIKA
			ON TORI_GAIKA.KAISHA_CD = @KAISHA_CD
			AND TORI_GAIKA.TORIHIKISAKI_CD = #tmp.TOKUISAKI_CD
		LEFT JOIN BC_MST_TUKA TUKA
			ON TORI_GAIKA.KAISHA_CD = TUKA.KAISHA_CD
			AND TORI_GAIKA.TUKA_CD = TUKA.TUKA_CD
			AND TUKA.DEL_FLG = 0
			AND TUKA.MUKOU_FLG = 0
		WHERE #tmp.JUCHU_KBN = '03'

		--発注伝票明細拡張
		INSERT INTO KB_TBL_HACCHU_DTL_EX
		(KAISHA_CD
		,HACCHU_NO
		,HACCHU_ENO
		,UNSO_KBN
		,INS_TM
		,INS_SHAIN_CD
		,INS_PGM_CD
		,UPD_TM
		,UPD_SHAIN_CD
		,UPD_PGM_CD
		)
		SELECT @KAISHA_CD
			  ,#tmpHdr.HACCHU_NO
			  ,ROW_NUMBER() OVER(PARTITION BY #tmp.GROUP_KEY ORDER BY #tmp.LINE_NO)
			  ,NULL
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
		FROM #tmp
		LEFT JOIN #tmpHdr
			ON #tmp.GROUP_KEY = #tmpHdr.GROUP_KEY
		WHERE #tmp.JUCHU_KBN = '03'

		--入荷予定
		INSERT INTO KB_TBL_NYUKA_YOTEI
		(KAISHA_CD
		,NYUKA_YOTEI_NO
		,HACCHU_NO
		,HACCHU_ENO
		,IDO_NO
		,NYUKO_KBN
		,WF_SHONIN_STATUS
		,HINMOKU_SEQ
		,SHOHIN_LOT
		,NYUKA_YOTEI_DATE
		,KENSHU_YOTEI_DATE
		,IRISU
		,HAKOSU
		,NISUGATA_RENBAN
		,SOKO_CD
		,SHUKKASAKI_CD
		,JISSEKI_SURYO
		,SURYO
		,NYUKA_SURYO
		,GOUKAKU_SURYO
		,FUGOUKAKU_SURYO
		,FUGOUKAKU_KBN
		,TEKIYO
		,KENPIN_STATUS
		,KAKUNIN_MOSIOKURI
		,KENPIN_DATE
		,NYUKO_DATE
		,KENSHU_DATE
		,SHISAN_KEIJO_START_DATE
		,JISSEKI_KINGAKU
		,KINGAKU
		,JISSEKI_SHOHIZEI
		,SHOHIZEI
		,TAX_RATE
		,NYUKA_SHIJI_NO
		,TAISHOGAI_FLG
		,KEIJO_STD_KBN
		,SHIRE_NO
		,SHIRE_DTL_KEY
		,BUNNO_MOTO_NO
		,NYUKA_YOTEI_JI_KBN
		,EDI_SEND_STATUS
		,BUNNO_FLG
		,MEMO
		,BUNNO_NYUKA_YOTEI_DATE
		,DEL_FLG
		,INS_TM
		,INS_SHAIN_CD
		,INS_PGM_CD
		,UPD_TM
		,UPD_SHAIN_CD
		,UPD_PGM_CD
		)
		SELECT @KAISHA_CD				--会社コード
			  ,#tmpHdr.HACCHU_NO + RIGHT('0000' + CONVERT(NVARCHAR, ROW_NUMBER() OVER(PARTITION BY #tmp.GROUP_KEY ORDER BY #tmp.LINE_NO)), 4)
			  ,#tmpHdr.HACCHU_NO		--発注NO
			  ,ROW_NUMBER() OVER(PARTITION BY #tmp.GROUP_KEY ORDER BY #tmp.LINE_NO)	--枝番
			  ,NULL						--移動NO
			  ,'40'						--入庫区分：倉庫移動
			  ,'01'						--WF承認状態
			  ,shukka.HINMOKU_SEQ		--品目SEQ
			  ,NULL						--商品ロット
			  ,CASE 					--入荷予定日
			  		WHEN #tmp.DTL_SHITEI_NOHIN_DATE IS NOT NULL
			  			THEN CONVERT(DATE, #tmp.DTL_SHITEI_NOHIN_DATE)
			  			ELSE CONVERT(DATE, #tmp.DTL_SHUKKA_YOTEI_DATE)
			  	END
			  ,NULL						--検収予定日
			  ,NULL						--入数
			  ,NULL						--箱数
			  ,NULL						--似姿連番
			  ,#tmp.AZUKE_AZUKARI_IDO_SOKO_CD	--倉庫コード(移動先)
			  ,NULL						--出荷先コード
			  ,CASE WHEN HIN.ZAIKO_KANRI_FLG = 1	--実績数量
						THEN NULL
					ELSE shukka.SURYO
			   END
			  ,shukka.SURYO				--数量
			  ,NULL						--入荷数量
			  ,NULL						--合格数量
			  ,NULL						--不合格数量
			  ,NULL						--不合格区分
			  ,NULL						--摘要
			  ,'010'					--検品ステータス(未入荷)
			  ,NULL						--確認申し送り
			  ,NULL						--検品日
			  ,NULL						--入庫日
			  ,NULL						--検収日
			  ,CONVERT(DATE, #tmp.DTL_SHITEI_NOHIN_DATE)	--資産計上開始日(アドオンで品目の開始日数はなくなる)
			  ,dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD, #tmp.TOKUISAKI_CD, JUCHU_TANKA * shukka.SURYO, 1, 0)	--実績金額
			  ,dbo.CO_FUNC_HASU_SHORI_KINGAKU_EX(@KAISHA_CD, #tmp.TOKUISAKI_CD, JUCHU_TANKA * shukka.SURYO, 1, 0)	--金額
			  ,dbo.CO_FUNC_HASU_SHORI((JUCHU_TANKA * shukka.SURYO) * TAX_RATE, TORI.JUCHU_SHOHIZEI_HASU_KBN, 0)		--実績消費税
			  ,dbo.CO_FUNC_HASU_SHORI((JUCHU_TANKA * shukka.SURYO) * TAX_RATE, TORI.JUCHU_SHOHIZEI_HASU_KBN, 0)		--消費税
			  ,TAX_RATE					--税率
			  ,NULL						--入荷指示NO
			  ,CASE WHEN HIN.ZAIKO_KANRI_FLG = 1	--対象外フラグ
						THEN 0
					ELSE 1
			   END
			  ,'01'						--計上基準区分(入荷基準)
			  ,NULL						--仕入NO
			  ,NULL						--仕入明細連番
			  ,NULL						--分納元NO
			  ,NULL						--入荷予定時区分
			  ,0						--EDI送信状態
			  ,0						--分納フラグ
			  ,NULL						--メモ
			  ,NULL						--分納入荷予定日
			  ,0						--削除フラグ
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
		FROM #tmpShukkaYotei shukka
		INNER JOIN #tmp
			ON #tmp.LINE_NO = shukka.LINE_NO
		LEFT JOIN #tmpHdr
			ON #tmp.GROUP_KEY = #tmpHdr.GROUP_KEY
		LEFT JOIN BC_MST_HINMOKU_KANRI HINKAN
			ON HINKAN.KAISHA_CD = @KAISHA_CD
			AND HINKAN.HINMOKU_SEQ = shukka.HINMOKU_SEQ
		LEFT JOIN BC_MST_HINMOKU HIN
			ON HIN.KAISHA_CD = HINKAN.KAISHA_CD
			AND HIN.HINMOKU_CD = HINKAN.HINMOKU_CD
		LEFT JOIN BC_MST_TORIHIKISAKI TORI
			ON TORI.KAISHA_CD = @KAISHA_CD
			AND TORI.TORIHIKISAKI_CD = #tmp.TOKUISAKI_CD
		WHERE #tmp.JUCHU_KBN = '03'

		--入荷予定外貨
		INSERT INTO KB_TBL_NYUKA_YOTEI_GAIKA
		(KAISHA_CD
		,NYUKA_YOTEI_NO
		,JISSEKI_RATE
		,RATE
		,JISSEKI_TUKA_KINGAKU
		,TUKA_KINGAKU
		,DEL_FLG
		,INS_TM
		,INS_SHAIN_CD
		,INS_PGM_CD
		,UPD_TM
		,UPD_SHAIN_CD
		,UPD_PGM_CD
		)
		SELECT  @KAISHA_CD
			   ,#tmpHdr.HACCHU_NO + RIGHT('0000' + CONVERT(NVARCHAR, ROW_NUMBER() OVER(PARTITION BY #tmp.GROUP_KEY ORDER BY #tmp.LINE_NO)), 4)
			   ,#tmp.RATE
			   ,#tmp.RATE
			   ,dbo.CO_FUNC_HASU_SHORI_EX(#tmp.TORIHIKISAKI_TUKA_TANKA * shukka.SURYO ,'01' ,TUKA.DECIMAL_LENGTH)
			   ,dbo.CO_FUNC_HASU_SHORI_EX(#tmp.TORIHIKISAKI_TUKA_TANKA * shukka.SURYO ,'01' ,TUKA.DECIMAL_LENGTH)
			   ,0
			   ,@NOW
			   ,@USER_ID
			   ,@PGM_CD
			   ,@NOW
			   ,@USER_ID
			   ,@PGM_CD
		FROM #tmpShukkaYotei shukka
		INNER JOIN #tmp
			ON #tmp.LINE_NO = shukka.LINE_NO
		LEFT JOIN #tmpHdr
			ON #tmp.GROUP_KEY = #tmpHdr.GROUP_KEY
		LEFT JOIN BC_MST_TORIHIKISAKI_GAIKA TORI_GAIKA
			ON TORI_GAIKA.KAISHA_CD = @KAISHA_CD
			AND TORI_GAIKA.TORIHIKISAKI_CD = #tmp.TOKUISAKI_CD
		LEFT JOIN BC_MST_TUKA TUKA
			ON TORI_GAIKA.KAISHA_CD = TUKA.KAISHA_CD
			AND TORI_GAIKA.TUKA_CD = TUKA.TUKA_CD
			AND TUKA.DEL_FLG = 0
			AND TUKA.MUKOU_FLG = 0
		WHERE #tmp.JUCHU_KBN = '03'

		--倉庫移動ヘッダ
		INSERT INTO ZK_TBL_SOKO_IDO_HDR
		(KAISHA_CD
		,SOKO_IDO_NO
		,SOKO_IDO_DATE
		,JUCHU_NO
		,SHUKKA_SHIJI_NO
		,HACCHU_NO
		,NYUKA_SHIJI_NO
		,TEKIYO
		,CANCEL_FLG
		,CANCEL_RIYU
		,CANCEL_TM
		,DEL_FLG
		,INS_TM
		,INS_SHAIN_CD
		,INS_PGM_CD
		,UPD_TM
		,UPD_SHAIN_CD
		,UPD_PGM_CD
		)
		SELECT @KAISHA_CD
			  ,SOKO_IDO_NO
			  ,CONVERT(DATE, JUCHU_DATE)	--倉庫移動日=受注日とする
			  ,DENPYO_NO
			  ,NULL
			  ,HACCHU_NO
			  ,NULL
			  ,NULL
			  ,0
			  ,NULL
			  ,NULL
			  ,0
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
		FROM #tmpHdr
		WHERE #tmpHdr.JUCHU_KBN = '03'

		--倉庫移動明細
		INSERT INTO ZK_TBL_SOKO_IDO_DTL
		(KAISHA_CD
		,SOKO_IDO_NO
		,SOKO_IDO_ENO
		,SHUKKA_YOTEI_NO
		,NYUKA_YOTEI_NO
		,HINMOKU_SEQ
		,IDO_SURYO
		,BIKO
		,DEL_FLG
		,INS_TM
		,INS_SHAIN_CD
		,INS_PGM_CD
		,UPD_TM
		,UPD_SHAIN_CD
		,UPD_PGM_CD
		)
		SELECT @KAISHA_CD
			  ,#tmpHdr.SOKO_IDO_NO
			  ,ROW_NUMBER() OVER(PARTITION BY #tmp.GROUP_KEY ORDER BY #tmp.LINE_NO)
			  ,#tmp.DENPYO_NO + RIGHT('0000' + CONVERT(NVARCHAR, ROW_NUMBER() OVER(PARTITION BY #tmp.GROUP_KEY ORDER BY #tmp.LINE_NO)), 4)
			  ,#tmpHdr.HACCHU_NO + RIGHT('0000' + CONVERT(NVARCHAR, ROW_NUMBER() OVER(PARTITION BY #tmp.GROUP_KEY ORDER BY #tmp.LINE_NO)), 4)
			  ,#tmp.HINMOKU_SEQ
			  ,shukka.SURYO		--移動数量
			  ,NULL
			  ,0
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
			  ,@NOW
			  ,@USER_ID
			  ,@PGM_CD
		FROM #tmpShukkaYotei shukka
		INNER JOIN #tmp
			ON #tmp.LINE_NO = shukka.LINE_NO
		LEFT JOIN #tmpHdr
			ON #tmp.GROUP_KEY = #tmpHdr.GROUP_KEY
		WHERE #tmp.JUCHU_KBN = '03'

		--一括取込では出荷指示・入荷指示は未指示のため作成しない
		/***********倉庫移動時の発注情報、倉庫移動情報作成END***********/
		/*===============================登録処理END===============================*/

		SELECT @RetCd

		--登録可能の場合、エラー行なし(空レコード)として返す
		SELECT 0
		WHERE 1 = 0

		--警告レコード作成
		--エラーメッセージを使用する
		--請求基準日から算出される請求日において
		--請求先に対する請求テーブルの請求日より過去の場合は警告対象
		UPDATE #tmp
		SET ERROR_MSG = @ALERT_MSG_SEIKYU + DTL.JUCHU_NO + '-' + CONVERT(NVARCHAR, DTL.JUCHU_ENO)
		FROM #tmp
		LEFT JOIN HK_TBL_JUCHU_DTL DTL
			ON DTL.KAISHA_CD = @KAISHA_CD
			AND #tmp.DENPYO_NO = DTL.JUCHU_NO
		LEFT JOIN HK_TBL_JUCHU_HDR HDR
			ON HDR.KAISHA_CD = DTL.KAISHA_CD
			AND HDR.JUCHU_NO = DTL.JUCHU_NO
		WHERE JUCHU_KBN = '01'
		AND ERROR_MSG IS NULL
		AND ( EXISTS (SELECT *
		            FROM SK_TBL_SEIKYU_SHIME SEIKYU
					WHERE SEIKYU.KAISHA_CD = @KAISHA_CD
					AND SEIKYU.SEIKYUSAKI_CD = HDR.SEIKYUSAKI_CD
					AND DATEDIFF(DAY, SEIKYU.SEIKYU_DATE, dbo.HK_FUNC_GET_SEIKYU_DATE_PATTERN(@KAISHA_CD, HDR.SEIKYUSAKI_CD, HDR.KAISHU_HOHO_PATTERN, #tmp.DTL_SEIKYU_KIJUN_DATE)) <= 0
					AND SEIKYU.CANCEL_FLG = 0
					AND SEIKYU.DEL_FLG = 0
					)
			OR EXISTS (SELECT *
		            FROM SK_TBL_SEIKYU_HDR SEIKYU
					WHERE SEIKYU.KAISHA_CD = @KAISHA_CD
					AND SEIKYU.SEIKYUSAKI_CD = HDR.SEIKYUSAKI_CD
					AND DATEDIFF(DAY, SEIKYU.SEIKYU_DATE, dbo.HK_FUNC_GET_SEIKYU_DATE_PATTERN(@KAISHA_CD, HDR.SEIKYUSAKI_CD, HDR.KAISHU_HOHO_PATTERN, #tmp.DTL_SEIKYU_KIJUN_DATE)) <= 0
					AND SEIKYU.CANCEL_FLG = 0
					AND SEIKYU.DEL_FLG = 0
					)
			)

		--本受注の伝票において、出荷予定が休日の場合は警告対象
		UPDATE #tmp
		SET ERROR_MSG = @ALERT_MSG_HOLIDAY + DTL.JUCHU_NO + '-' + CONVERT(NVARCHAR, DTL.JUCHU_ENO)
		FROM #tmp
		LEFT JOIN HK_TBL_JUCHU_DTL DTL
			ON #tmp.DENPYO_NO = DTL.JUCHU_NO
		WHERE dbo.CO_FUNC_IS_HOLIDAY_EX(@KAISHA_CD, DTL.SHUKKA_YOTEI_DATE) = 1
		AND JUCHU_KBN = '01'
		AND ERROR_MSG IS NULL

		--出荷停止期間内の場合は警告対象
		/**********************************************
	    *出荷停止期間チェックSTART
	    **********************************************/
		UPDATE #tmp
	    SET #tmp.ERROR_MSG = 
				CASE --出荷停止期間FROM <= 出荷予定日
					 WHEN HINMOKU.SYUKKA_TEISHI_KIKAN_FROM IS NOT NULL
							AND HINMOKU.SYUKKA_TEISHI_KIKAN_TO IS NULL
							AND DATEDIFF(DAY, HINMOKU.SYUKKA_TEISHI_KIKAN_FROM, DTL_SHUKKA_YOTEI_DATE) >= 0	
						THEN @ERR_MSG_CANNOT_USE_HINMOKU + @FLD_NM_DTL_SHUKKA_YOTEI_DATE
					 --出荷停止期間TO >= 出荷予定日
					 WHEN HINMOKU.SYUKKA_TEISHI_KIKAN_FROM IS NULL
							AND HINMOKU.SYUKKA_TEISHI_KIKAN_TO IS NOT NULL
							AND DATEDIFF(DAY, HINMOKU.SYUKKA_TEISHI_KIKAN_TO, DTL_SHUKKA_YOTEI_DATE) <= 0
						THEN @ERR_MSG_CANNOT_USE_HINMOKU + @FLD_NM_DTL_SHUKKA_YOTEI_DATE
					 --出荷停止期間FROM <= 出荷予定日 <= 出荷停止期間TO
					 WHEN HINMOKU.SYUKKA_TEISHI_KIKAN_FROM IS NOT NULL
							AND HINMOKU.SYUKKA_TEISHI_KIKAN_TO IS NOT NULL
							AND DATEDIFF(DAY, HINMOKU.SYUKKA_TEISHI_KIKAN_FROM, DTL_SHUKKA_YOTEI_DATE) >= 0
							AND DATEDIFF(DAY, HINMOKU.SYUKKA_TEISHI_KIKAN_TO, DTL_SHUKKA_YOTEI_DATE) <= 0
						THEN @ERR_MSG_CANNOT_USE_HINMOKU + @FLD_NM_DTL_SHUKKA_YOTEI_DATE
				END
		FROM #tmp
		INNER JOIN BC_MST_HINMOKU_KANRI HINKAN
			ON #tmp.HINMOKU_SEQ = HINKAN.HINMOKU_SEQ
		INNER JOIN BC_MST_HINMOKU_EX HINMOKU
			ON HINMOKU.KAISHA_CD = HINKAN.KAISHA_CD
			AND HINMOKU.HINMOKU_CD = HINKAN.HINMOKU_CD
		WHERE #tmp.ERROR_MSG IS NULL
		AND HINKAN.KAISHA_CD = @KAISHA_CD
		AND #tmp.JUCHU_KBN = '01'
		AND #tmp.SURYO > 0
		/**********************************************
	    *出荷停止期間チェックEND
	    **********************************************/
	    
		--警告レコード取得
		SELECT LINE_NO
			  ,ERROR_MSG
		FROM #tmp
		WHERE #tmp.ERROR_MSG IS NOT NULL
		ORDER BY LINE_NO

		--登録伝票NO取得
		SELECT COUNT(*)
			  ,MIN(DENPYO_NO) AS MIN_DENPYO_NO
			  ,MAX(DENPYO_NO) AS MAX_DENPYO_NO
		FROM #tmpHdr
		
		--登録した伝票No、明細No取得
		IF (@PGM_CD = 'EDITorikomiTool')
		BEGIN
			SELECT 
				DENPYO_NO
				,DENPYO_ENO
			FROM #tmp
			WHERE 
				HINMOKU NOT IN ('DAIBIKI' ,'DELI', 'CHARGE-TF', 'CHARGE')
			ORDER BY
				DENPYO_NO
				,DENPYO_ENO
		 END
	END

	--#tmp、#tmpHdrを削除する
    DROP TABLE #tmp
	DROP TABLE #tmpHdr
	DROP TABLE #tmpHikiate
	DROP TABLE #tmpShukkaYotei
    RETURN

	--END_PROCラベルの処理
	END_PROC:
		SELECT @RetCd
END