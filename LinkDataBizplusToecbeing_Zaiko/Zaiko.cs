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

namespace LinkDataBizplusToecbeing_Zaiko
{
    public class Zaiko : AbstractBatch
    {
        #region 定数定義

        /// <summary>
        /// ロガー
        /// </summary>
        private static readonly ILog logger = LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);

        /// <summary>
        /// 連携済在庫リスト
        /// </summary>
        private List<UpdateDTO> renkeizumiZaikoList;

        /// <summary>
        /// 連携対象データ
        /// </summary>
        private DataTable renkeiDt;

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
        public Zaiko(string[] args)
            : base(logger, resultLogger)
        {
            Args = args;
            ConstResultKeyWord = BatchConst.ZAIKO_INFO_RESULT_LOG_KEYWORD;
            ConstBatchNm = BatchConst.ZAIKO_INFO_BATCH_NAME;
            ConstStored = SqlConst.ZAIKO_INFO_BATCH_STORED;
            ConstCsvFile = BatchConst.ZAIKO_INFO_CSV_FILE;
            ConstCsvBackupFile = BatchConst.ZAIKO_INFO_CSV_BACKUP_FILE;
            ConstCsvUploadFile = BatchConst.ZAIKO_INFO_CSV_UPLOAD_FILE;
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
        ///業務処理
        /// </summary>
        public override void BizProc()
        {
            Parameters = new object[]
            {
                SqlConst.P_KAISHA_CD + CommConst.COMMA + KaishaCd
            };
            // データ取得
            GetZaiSabunData();
            // 件数設定
            Count = renkeiDt.Rows.Count;
            var csvFile = CsvFile + JikkoDateTime.ToString(CommConst.YYYYMMDDHHMMSS) + CommConst.CSV_EXTENSION;
            // Csvファイル出力
            Util.DataTableToCsv(renkeiDt, csvFile, BatchNm, Encoding.GetEncoding(Util.GetAppConfigValue(CommConst.CSV_ENCODING)), CommConst.QUOTE_ALL_FIELDS_FLAG_TRUE, CommConst.FOOTER_FLAG_TRUE);
            // FTP転送
            var csvUploadFile = Util.GetAppConfigValue(ConstCsvUploadFile) + JikkoDateTime.ToString(CommConst.YYYYMMDDHHMMSS) + CommConst.CSV_EXTENSION;
            Util.FtpUpload(csvFile, csvUploadFile);
            // 連携済在庫リスト更新
            UpdRenkeizumiZaikoList();
        }

        #endregion 業務処理

        #region 在庫差分データ取得

        /// <summary>
        /// 在庫差分データ取得
        /// </summary>
        public void GetZaiSabunData()
        {
            var zaikoDt = GetData();
            var renkeizumiZaikoDt = GetRenkeizumiZaikoListData();
            var renkeiDtAE = zaikoDt.AsEnumerable().Except(renkeizumiZaikoDt.AsEnumerable(), DataRowComparer.Default);
            if (renkeiDtAE.Count() > 0)
            {
                renkeiDt = renkeiDtAE.CopyToDataTable();
            }
            else
            {
                renkeiDt = zaikoDt.Clone();
                renkeiDt.Clear();
            }
            renkeizumiZaikoList = new List<UpdateDTO>();
            renkeiDt.AsEnumerable().ToList().ForEach(x =>
            {
                if (renkeizumiZaikoDt.AsEnumerable().Where(y => y.Field<string>(SqlConst.HINMOKU_CD).Equals(x.Field<string>(SqlConst.HINMOKU_CD)) && y.Field<string>(SqlConst.SOKO_CD).Equals(x.Field<string>(SqlConst.SOKO_CD))).Count() == 1)
                {
                    renkeizumiZaikoList.Add(new UpdateDTO() { Query = SqlConst.RENKEIZUMI_ZAIKO_LIST_QUERY_UPDATE, Parameters = new object[] { SqlConst.P_HIKIATE_KANO_SURYO + CommConst.COMMA + x.Field<int>(SqlConst.ZAIKO_HIKIATE_KANO_SURYO), SqlConst.P_HINMOKU_CD + CommConst.COMMA + x.Field<string>(SqlConst.HINMOKU_CD), SqlConst.P_SOKO_CD + CommConst.COMMA + x.Field<string>(SqlConst.SOKO_CD) } });
                }
                else
                {
                    renkeizumiZaikoList.Add(new UpdateDTO() { Query = SqlConst.RENKEIZUMI_ZAIKO_LIST_QUERY_INSERT, Parameters = new object[] { SqlConst.P_HINMOKU_CD + CommConst.COMMA + x.Field<string>(SqlConst.HINMOKU_CD), SqlConst.P_SOKO_CD + CommConst.COMMA + x.Field<string>(SqlConst.SOKO_CD), SqlConst.P_HIKIATE_KANO_SURYO + CommConst.COMMA + x.Field<int>(SqlConst.ZAIKO_HIKIATE_KANO_SURYO) } });
                }
            });
            renkeiDt.Columns.Remove(SqlConst.SOKO_CD);
        }

        #endregion 在庫差分データ取得

        #region 連携済在庫リストデータ取得

        /// <summary>
        /// 連携済在庫リストデータ取得
        /// </summary>
        private DataTable GetRenkeizumiZaikoListData()
        {
            var dbAccess = new DbAccess(Logger, ConnectionStrings);
            var dt = new DataTable();
            try
            {
                dt = dbAccess.Reader(SqlConst.RENKEIZUMI_ZAIKO_LIST_QUERY_SELCET, null);
            }
            finally
            {
                dbAccess.Close();
            }
            return dt;
        }

        #endregion 連携済在庫リストデータ取得

        #region 連携済在庫リスト更新

        /// <summary>
        /// 連携済在庫リスト更新
        /// </summary>
        private void UpdRenkeizumiZaikoList()
        {
            var dbAccess = new DbAccess(Logger, ConnectionStrings);
            try
            {
                dbAccess.BeginTransaction();
                renkeizumiZaikoList.ForEach(x =>
                {
                    dbAccess.ExecuteNonQuery(x.Query, x.Parameters);
                });
                dbAccess.Commit();
            }
            catch (Exception ex)
            {
                dbAccess.RollBack();
                throw;
            }
            finally
            {
                dbAccess.Close();
            }
        }

        #endregion 連携済在庫リスト更新
    }
}