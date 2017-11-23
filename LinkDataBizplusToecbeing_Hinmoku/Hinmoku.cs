using System;
using System.Collections.Generic;
using System.Data;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using B2BSiteRenkei.Common;
using B2BSiteRenkei.Common.Const;
using log4net;

namespace LinkDataBizplusToecbeing_Hinmoku
{
    public class Hinmoku : AbstractBatch
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

        #region 半角カナ→全角カナ

        private string COL_HINMOKU_NM = "品目名称";
        private string COL_KIKAKU = "規格";
        private string COL_GENSANKOKU_CD = "原産国";
        private string COL_HINMOKU_GRP_CD_4 = "カタログ区分１";
        private string COL_HINMOKU_GRP_CD_2 = "ブランド";
        private string COL_HINMOKU_GRP_CD_3 = "アイテム";
        private string COL_HINMOKU_GRP_CD_10 = "発表展示会";
        private string COL_HINMOKU_GRP_CD_11 = "シーズン";
        private string COL_TANI_CD = "単位コード";
        private string COL_SOZAI = "素材";
        private string COL_PACKAGE = "パッケージ";
        private string COL_SHIYOU = "仕様";
        private string COL_SHOHIN_CHUI_JIKOU = "商品注意事項";
        private string COL_SOKYU_KOUMOKU = "訴求";

        #endregion 半角カナ→全角カナ

        #endregion 定数定義

        #region コンストラクタ

        /// <summary>
        /// コンストラクタ
        /// </summary>
        /// <param name="args"></param>
        public Hinmoku(string[] args)
            : base(logger, resultLogger)
        {
            Args = args;
            ConstResultKeyWord = BatchConst.HINMOKU_INFO_RESULT_LOG_KEYWORD;
            ConstBatchNm = BatchConst.HINMOKU_INFO_BATCH_NAME;
            ConstStored = SqlConst.HINMOKU_INFO_BATCH_STORED;
            ConstCsvFile = BatchConst.HINMOKU_INFO_CSV_FILE;
            ConstCsvBackupFile = BatchConst.HINMOKU_INFO_CSV_BACKUP_FILE;
            ConstCsvUploadFile = BatchConst.HINMOKU_INFO_CSV_UPLOAD_FILE;
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
            Parameters = new object[] {
                SqlConst.P_KAISHA_CD + CommConst.COMMA + KaishaCd
                };
            var dt = GetData();
            // 半角カナ→全角カナに変換
            dt.Select().ToList().ForEach(row =>
            {
                row[COL_HINMOKU_NM] = KanaEx.ToZenkakuKana(row[COL_HINMOKU_NM].ToString());
                row[COL_KIKAKU] = KanaEx.ToZenkakuKana(row[COL_KIKAKU].ToString());
                row[COL_GENSANKOKU_CD] = KanaEx.ToZenkakuKana(row[COL_GENSANKOKU_CD].ToString());
                row[COL_HINMOKU_GRP_CD_4] = KanaEx.ToZenkakuKana(row[COL_HINMOKU_GRP_CD_4].ToString());
                row[COL_HINMOKU_GRP_CD_2] = KanaEx.ToZenkakuKana(row[COL_HINMOKU_GRP_CD_2].ToString());
                row[COL_HINMOKU_GRP_CD_3] = KanaEx.ToZenkakuKana(row[COL_HINMOKU_GRP_CD_3].ToString());
                row[COL_HINMOKU_GRP_CD_10] = KanaEx.ToZenkakuKana(row[COL_HINMOKU_GRP_CD_10].ToString());
                row[COL_HINMOKU_GRP_CD_11] = KanaEx.ToZenkakuKana(row[COL_HINMOKU_GRP_CD_11].ToString());
                row[COL_TANI_CD] = KanaEx.ToZenkakuKana(row[COL_TANI_CD].ToString());
                row[COL_SOZAI] = KanaEx.ToZenkakuKana(row[COL_SOZAI].ToString());
                row[COL_PACKAGE] = KanaEx.ToZenkakuKana(row[COL_PACKAGE].ToString());
                row[COL_SHIYOU] = KanaEx.ToZenkakuKana(row[COL_SHIYOU].ToString());
                row[COL_SHOHIN_CHUI_JIKOU] = KanaEx.ToZenkakuKana(row[COL_SHOHIN_CHUI_JIKOU].ToString());
                row[COL_SOKYU_KOUMOKU] = KanaEx.ToZenkakuKana(row[COL_SOKYU_KOUMOKU].ToString());
            });
            // 件数設定
            Count = dt.Rows.Count;
            var csvFile = CsvFile + JikkoDateTime.ToString(CommConst.YYYYMMDDHHMMSS) + CommConst.CSV_EXTENSION;
            // Csvファイル出力
            Util.DataTableToCsv(dt, csvFile, BatchNm, Encoding.GetEncoding(Util.GetAppConfigValue(CommConst.CSV_ENCODING)), CommConst.QUOTE_ALL_FIELDS_FLAG_TRUE, CommConst.FOOTER_FLAG_TRUE);
            // FTP転送
            var csvUploadFile = Util.GetAppConfigValue(ConstCsvUploadFile) + JikkoDateTime.ToString(CommConst.YYYYMMDDHHMMSS) + CommConst.CSV_EXTENSION;
            Util.FtpUpload(csvFile, csvUploadFile);
        }

        #endregion 業務処理
    }
}