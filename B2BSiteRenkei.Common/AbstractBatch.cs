using System;
using System.Data;
using System.IO;
using System.Linq;
using B2BSiteRenkei.Common.Const;
using log4net;

namespace B2BSiteRenkei.Common
{
    public class AbstractBatch
    {
        #region 変数定義

        /// <summary>
        /// 実行日時
        /// </summary>
        protected DateTime JikkoDateTime;

        /// <summary>
        /// バッチ引数
        /// </summary>
        public string[] Args;

        /// <summary>
        /// バッチ名称
        /// </summary>
        public string BatchNm;

        /// <summary>
        /// 結果キーワード
        /// </summary>
        public string ResultKeyWord;

        /// <summary>
        /// CSVファイル名
        /// </summary>
        public string CsvFile;

        /// <summary>
        /// CSVバックアップファイル名
        /// </summary>
        public string CsvBackupFile;

        /// <summary>
        /// 会社コード
        /// </summary>
        public string KaishaCd;

        /// <summary>
        /// カウント
        /// </summary>
        public int Count;

        /// <summary>
        /// ロガー
        /// </summary>
        public ILog Logger;

        /// <summary>
        /// 結果ロガー
        /// </summary>
        public ILog ResultLogger;

        /// <summary>
        /// Utility
        /// </summary>
        public Utility Util;

        /// <summary>
        /// コネクション文字列
        /// </summary>
        public string ConnectionStrings;

        /// <summary>
        /// クエリー
        /// </summary>
        public string Stored;

        /// <summary>
        /// パラメータ
        /// </summary>
        public object[] Parameters;

        /// <summary>
        /// 結果ログキーワード
        /// </summary>
        public string ConstResultKeyWord;

        /// <summary>
        /// バッチ名称
        /// </summary>
        public string ConstBatchNm;

        /// <summary>
        /// stored名称
        /// </summary>
        public string ConstStored;

        /// <summary>
        /// CSVファイル名称
        /// </summary>
        public string ConstCsvFile;

        /// <summary>
        /// CSVバックアップファイル名
        /// </summary>
        public string ConstCsvBackupFile;

        /// <summary>
        /// CSVアップロードファイル名称
        /// </summary>
        public string ConstCsvUploadFile;

        /// <summary>
        /// CSVダウンロードファイル名称
        /// </summary>
        public string ConstCsvDownloadFile;

        #endregion 変数定義

        #region コンストラクタ

        public AbstractBatch(ILog logger, ILog resultLogger)
        {
            JikkoDateTime = DateTime.Now;
            Logger = logger;
            ResultLogger = resultLogger;
            Util = new Utility(logger);
        }

        #endregion コンストラクタ

        #region メイン処理

        /// <summary>
        /// メイン処理
        /// </summary>
        /// <returns></returns>
        public int DoMain()
        {
            Logger.Info(Utility.ReplaceMsg(Utility.GetMsg(MsgConst.BB0001I), new string[] { BatchNm }));
            // リターンコード（"0"）
            var rtnCode = CommConst.BATCH_NORMAL;
            try
            {
                //変数初期化
                Init();
                // bkフォルダに移動
                MoveFile();
                // 業務処理
                BizProc();
                // 処理件数出力
                Logger.Info(Utility.ReplaceMsg(Utility.GetMsg(MsgConst.BB0003I), new string[] { BatchNm, Count.ToString() }));
                // 結果ログ出力
                Util.WriteResultLog(ResultLogger, ResultKeyWord + CommConst.ZENKAKU_SEMI_COLON + Util.GetAppConfigValue(BatchConst.RESULT_OK), JikkoDateTime);
            }
            catch (Exception ex)
            {
                // リターンコード（"-1"）
                rtnCode = CommConst.BATCH_ABNORMAL;
                Logger.Error(ex.Message);
                Logger.Error(Utility.ReplaceMsg(Utility.GetMsg(MsgConst.BB0011E), new string[] { BatchNm }));
                // 結果ログ出力
                Util.WriteResultLog(ResultLogger, ResultKeyWord + CommConst.ZENKAKU_SEMI_COLON + Util.GetAppConfigValue(BatchConst.RESULT_NG), JikkoDateTime);
            }
            finally
            {
                Logger.Info(Utility.ReplaceMsg(Utility.GetMsg(MsgConst.BB0002I), new string[] { BatchNm }));
            }
            return rtnCode;
        }

        #endregion メイン処理

        #region 受注メイン処理

        /// <summary>
        /// 受注メイン処理
        /// </summary>
        /// <returns></returns>
        public int DoJuchuMain()
        {
            Logger.Info(Utility.ReplaceMsg(Utility.GetMsg(MsgConst.BB0001I), new string[] { BatchNm }));
            // リターンコード（"0"）
            var rtnCode = CommConst.BATCH_NORMAL;
            try
            {
                //変数初期化
                Init();
                // 業務処理
                BizProc();
                // 処理件数出力
                Logger.Info(Utility.ReplaceMsg(Utility.GetMsg(MsgConst.BB0003I), new string[] { BatchNm, Count.ToString() }));
                // 結果ログ出力
                Util.WriteResultLog(ResultLogger, ResultKeyWord + CommConst.ZENKAKU_SEMI_COLON + Util.GetAppConfigValue(BatchConst.RESULT_OK), JikkoDateTime);
            }
            catch (Exception ex)
            {
                // リターンコード（"-1"）
                rtnCode = CommConst.BATCH_ABNORMAL;
                Logger.Error(ex.Message);
                Logger.Error(Utility.ReplaceMsg(Utility.GetMsg(MsgConst.BB0011E), new string[] { BatchNm }));
                // 結果ログ出力
                Util.WriteResultLog(ResultLogger, ResultKeyWord + CommConst.ZENKAKU_SEMI_COLON + Util.GetAppConfigValue(BatchConst.RESULT_NG), JikkoDateTime);
            }
            finally
            {
                Logger.Info(Utility.ReplaceMsg(Utility.GetMsg(MsgConst.BB0002I), new string[] { BatchNm }));
            }
            return rtnCode;
        }

        #endregion 受注メイン処理

        #region データ取得

        /// <summary>
        /// データ取得する
        /// </summary>
        /// <returns></returns>
        public DataTable GetData()
        {
            var dt = new DataTable();
            var dbAccess = new DbAccess(Logger, ConnectionStrings);
            try
            {
                // ストアド実行
                dt = dbAccess.ExecuteStoredProcedure(Stored, Parameters).Tables[0];
            }
            finally
            {
                dbAccess.Close();
            }
            return dt;
        }

        #endregion データ取得

        #region bkフォルダに移動

        /// <summary>
        /// bkフォルダに移動
        /// </summary>
        public void MoveFile()
        {
            var csvFile = string.Empty;
            try
            {
                var dir = (new FileInfo(CsvFile)).Directory;
                if (dir.Exists)
                {
                    dir.GetFiles(CommConst.ASTERISK + CsvFile.Split(CommConst.CHAR_SLASH).ToList().LastOrDefault() + CommConst.ASTERISK, SearchOption.TopDirectoryOnly).ToList().ForEach(file =>
                    {
                        csvFile = file.FullName;
                        var bkDir = (new FileInfo(CsvBackupFile)).DirectoryName;
                        if (!Directory.Exists(bkDir))
                        {
                            Directory.CreateDirectory(bkDir);
                        }
                        var csvBkFile = CsvBackupFile + file.Name.Split(new string[] { CommConst.CSV_EXTENSION }, StringSplitOptions.None).FirstOrDefault() + CommConst.BK + CommConst.CSV_EXTENSION;
                        if (File.Exists(csvBkFile))
                        {
                            File.Delete(csvBkFile);
                        }
                        File.Move(csvFile, csvBkFile);
                    });
                }
            }
            catch (Exception ex)
            {
                Logger.Error(Utility.ReplaceMsg(Utility.GetMsg(MsgConst.BB0016E), new string[] { csvFile }));
                throw;
            }
        }

        #endregion bkフォルダに移動

        #region 受注bkフォルダに移動

        /// <summary>
        /// 受注bkフォルダに移動
        /// </summary>
        public void JuchuMoveFile()
        {
            try
            {
                // ファイル存在した場合
                if (File.Exists(CsvFile))
                {
                    var dir = (new FileInfo(CsvBackupFile)).DirectoryName;
                    if (!Directory.Exists(dir))
                    {
                        Directory.CreateDirectory(dir);
                    }
                    var csvBkFile = CsvBackupFile + JikkoDateTime.ToString(CommConst.YYYYMMDDHHMMSS) + CommConst.BK + CommConst.CSV_EXTENSION;
                    if (File.Exists(csvBkFile))
                    {
                        File.Delete(csvBkFile);
                    }
                    File.Move(CsvFile, csvBkFile);
                }
            }
            catch (Exception ex)
            {
                Logger.Error(Utility.ReplaceMsg(Utility.GetMsg(MsgConst.BB0016E), new string[] { CsvBackupFile }));
                throw;
            }
        }

        #endregion 受注bkフォルダに移動

        #region 業務処理

        /// <summary>
        /// 業務処理
        /// </summary>
        public virtual void BizProc()
        {
        }

        #endregion 業務処理

        #region 変数初期化

        /// <summary>
        /// 変数初期化
        /// </summary>
        /// <returns></returns>
        private void Init()
        {
            ResultKeyWord = Util.GetAppConfigValue(ConstResultKeyWord);
            ConnectionStrings = Utility.GetConnection(CommConst.DB_CONNECTIONS);
            KaishaCd = Util.GetAppConfigValue(CommConst.KAISHA_CD);
            Stored = Util.GetAppConfigValue(ConstStored);
            CsvFile = Util.GetAppConfigValue(ConstCsvFile);
            CsvBackupFile = Util.GetAppConfigValue(ConstCsvBackupFile);
        }

        #endregion　変数初期化
    }
}