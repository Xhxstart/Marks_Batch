using System.IO;
using System.Text;
using B2BSiteRenkei.Common;
using B2BSiteRenkei.Common.Const;
using log4net;

namespace LinkDataBizplusToecbeing_TokuisakiHinmokuTanka
{
    public class TokuisakiHinmokuTanka : AbstractBatch
    {
        #region 定数定義

        /// <summary>
        /// ロガー
        /// </summary>
        private static readonly ILog logger = LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);

        /// <summary>
        /// 結果ロガー
        /// </summary>
        private static readonly ILog resultLogger = LogManager.GetLogger(CommConst.RESULT_LOGGER_NAME);

        #endregion 定数定義

        #region コンストラクタ

        /// <summary>
        /// コンストラクタ
        /// </summary>
        /// <param name="args"></param>
        public TokuisakiHinmokuTanka(string[] args)
            : base(logger, resultLogger)
        {
            Args = args;
            ConstResultKeyWord = BatchConst.TOKUISAKI_HINMOKU_TANKA_INFO_RESULT_LOG_KEYWORD;
            ConstBatchNm = BatchConst.TOKUISAKI_HINMOKU_TANKA_INFO_BATCH_NAME;
            ConstStored = SqlConst.TOKUISAKI_HINMOKU_TANKA_INFO_BATCH_STORED;
            ConstCsvFile = BatchConst.TOKUISAKI_HINMOKU_TANKA_INFO_CSV_FILE;
            ConstCsvBackupFile = BatchConst.TOKUISAKI_HINMOKU_TANKA_INFO_CSV_BACKUP_FILE;
            ConstCsvUploadFile = BatchConst.TOKUISAKI_HINMOKU_TANKA_INFO_CSV_UPLOAD_FILE;
            BatchNm = Utility.Config.AppSettings.Settings[ConstBatchNm].Value;
        }

        #endregion コンストラクタ

        #region メイン処理

        /// <summary>
        /// メイン処理
        /// </summary>
        /// <returns>リターンコード</returns>
        public int Main()
        {
            return DoMain();
        }

        #endregion メイン処理

        #region 業務処理

        /// <summary>
        /// 業務処理
        /// </summary>
        public override void BizProc()
        {
            // データ取得
            Parameters = new object[]
            {
                SqlConst.P_KAISHA_CD + CommConst.COMMA + KaishaCd
            };
            var dt = GetData();
            // 件数設定
            Count = dt.Rows.Count;
            var csvFile = CsvFile + JikkoDateTime.ToString(CommConst.YYYYMMDDHHMMSS) + CommConst.CSV_EXTENSION;
            // Csvファイル出力
            Util.DataTableToCsv(dt, csvFile, BatchNm, Encoding.GetEncoding(Util.GetAppConfigValue(CommConst.CSV_ENCODING)), CommConst.QUOTE_ALL_FIELDS_FLAG_FALSE, CommConst.FOOTER_FLAG_FALSE);
            // FTP転送
            var csvUploadFile = Util.GetAppConfigValue(ConstCsvUploadFile) + JikkoDateTime.ToString(CommConst.YYYYMMDDHHMMSS) + CommConst.CSV_EXTENSION;
            Util.FtpUpload(csvFile, csvUploadFile);
        }

        #endregion 業務処理
    }
}