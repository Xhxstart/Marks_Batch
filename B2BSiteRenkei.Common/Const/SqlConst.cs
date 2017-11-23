namespace B2BSiteRenkei.Common.Const
{
    public class SqlConst
    {
        /// <summary>
        /// SQLパラメータ（@KAISHA_CD）
        /// </summary>
        public const string P_KAISHA_CD = "@KAISHA_CD";

        /// <summary>
        /// SQLパラメータ（@USER_ID）
        /// </summary>
        public const string P_USER_ID = "@USER_ID";

        /// <summary>
        /// SQLパラメータ（@PGM_CD）
        /// </summary>
        public const string P_PGM_CD = "@PGM_CD";

        /// <summary>
        /// SQLパラメータ（@FILE_PATH）
        /// </summary>
        public const string P_FILE_PATH = "@FILE_PATH";

        /// <summary>
        /// 売上登録日時（@URIAGE_INS_DATE）
        /// </summary>
        public const string P_URIAGE_INS_DATE = "@URIAGE_INS_DATE";

        /// <summary>
        /// SQLパラメータ（@hinmokuCd）
        /// </summary>
        public const string P_HINMOKU_CD = "@hinmokuCd";

        /// <summary>
        /// SQLパラメータ（@sokoCd）
        /// </summary>
        public const string P_SOKO_CD = "@sokoCd";

        /// <summary>
        /// SQLパラメータ（@hikiateKanoSuryo）
        /// </summary>
        public const string P_HIKIATE_KANO_SURYO = "@hikiateKanoSuryo";

        /// <summary>
        /// 品目コード
        /// </summary>
        public const string HINMOKU_CD = "品目コード";

        /// <summary>
        /// 前回バッチ実行日時
        /// </summary>
        public const string ZENKAI_JIKKOU_TM = "前回バッチ実行日時";

        /// <summary>
        /// SQLパラメータ（@UPD_TM）
        /// </summary>
        public const string P_UPD_TM = "@UPD_TM";

        /// <summary>
        /// SQLパラメータ（@batchNm）
        /// </summary>
        public const string P_BATCH_NM = "@batchNm";

        /// <summary>
        /// 倉庫コード
        /// </summary>
        public const string SOKO_CD = "倉庫コード";

        /// <summary>
        /// 在庫引当可能数
        /// </summary>
        public const string ZAIKO_HIKIATE_KANO_SURYO = "在庫引当可能数";

        /// <summary>
        /// HinmokuInfoBatchStored
        /// </summary>
        public const string HINMOKU_INFO_BATCH_STORED = "HinmokuInfoBatchStored";

        /// <summary>
        /// TokuisakiHinmokuTankaInfoBatchStored
        /// </summary>
        public const string TOKUISAKI_HINMOKU_TANKA_INFO_BATCH_STORED = "TokuisakiHinmokuTankaInfoBatchStored";

        /// <summary>
        /// ZaikoInfoBatchStored
        /// </summary>
        public const string ZAIKO_INFO_BATCH_STORED = "ZaikoInfoBatchStored";

        /// <summary>
        /// NyukayoteiInfoBatchStored
        /// </summary>
        public const string NYUKA_YOTEI_INFO_BATCH_STORED = "NyukayoteiInfoBatchStored";

        /// <summary>
        /// ShukkaJissekiInfoBatchStored
        /// </summary>
        public const string SHUKKA_JISSEKI_INFO_BATCH_STORED = "ShukkaJissekiInfoBatchStored";

        /// <summary>
        /// JuchuInfoBatchStored
        /// </summary>
        public const string JUCHU_INFO_BATCH_STORED = "JuchuInfoBatchStored";

        /// <summary>
        /// 連携済在庫リストデータ取得
        /// </summary>
        public const string RENKEIZUMI_ZAIKO_LIST_QUERY_SELCET = "SELECT HINMOKU_CD AS " + HINMOKU_CD + ", SOKO_CD AS " + SOKO_CD + ", CONVERT(INT,HIKIATE_KANO_SURYO) AS " + ZAIKO_HIKIATE_KANO_SURYO + " FROM RENKEIZUMI_ZAIKO_LIST";

        /// <summary>
        /// 連携済在庫リストデータ更新
        /// </summary>
        public const string RENKEIZUMI_ZAIKO_LIST_QUERY_UPDATE = "UPDATE  RENKEIZUMI_ZAIKO_LIST SET HIKIATE_KANO_SURYO = " + P_HIKIATE_KANO_SURYO + " WHERE HINMOKU_CD = " + P_HINMOKU_CD + " AND SOKO_CD = " + P_SOKO_CD;

        /// <summary>
        /// 連携済在庫リストデータ登録
        /// </summary>
        public const string RENKEIZUMI_ZAIKO_LIST_QUERY_INSERT = "INSERT  INTO RENKEIZUMI_ZAIKO_LIST ( HINMOKU_CD, SOKO_CD, HIKIATE_KANO_SURYO ) VALUES ( " + P_HINMOKU_CD + ", " + P_SOKO_CD + ", " + P_HIKIATE_KANO_SURYO + ")";
    }
}