using System;
using System.Collections.Generic;
using System.Data;
using System.IO;
using System.Linq;
using System.Text;
using B2BSiteRenkei.Common;
using B2BSiteRenkei.Common.Const;
using log4net;
using Microsoft.VisualBasic.FileIO;

namespace LinkDataEcbeingToBizplus_Juchu
{
    public class Juchu : AbstractBatch
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

        /// <summary>
        /// 取込区分：受注時のCSV列数
        /// </summary>
        private const int COLUMN_NUM_JUCHU = 52;

        /// <summary>
        /// 登録用CSVファイル名
        /// </summary>
        private const string strWriteName = "受注情報（登録用）.csv";

        /// <summary>
        /// エラーCSV出力tmpファイル
        /// </summary>
        private string tempPath;

        #endregion 定数定義

        #region コンストラクタ

        /// <summary>
        /// コンストラクタ
        /// </summary>
        /// <param name="args"></param>
        public Juchu(string[] args)
            : base(logger, resultLogger)
        {
            Args = args;
            ConstResultKeyWord = BatchConst.JUCHU_INFO_RESULT_LOG_KEYWORD;
            ConstBatchNm = BatchConst.JUCHU_INFO_BATCH_NAME;
            ConstStored = SqlConst.JUCHU_INFO_BATCH_STORED;
            ConstCsvFile = BatchConst.JUCHU_INFO_CSV_FILE;
            ConstCsvBackupFile = BatchConst.JUCHU_INFO_CSV_BACKUP_FILE;
            ConstCsvDownloadFile = BatchConst.JUCHU_INFO_CSV_DOWNLOAD_FILE;
            BatchNm = Utility.Config.AppSettings.Settings[ConstBatchNm].Value;
            Parameters = new object[]
            {
            };
        }

        #endregion コンストラクタ

        #region メイン処理

        /// <summary>
        /// メイン処理
        /// </summary>
        /// <returns>リターンコード</returns>
        public int Main()
        {
            return DoJuchuMain();
        }

        #endregion メイン処理

        #region 業務処理

        /// <summary>
        /// 業務処理
        /// </summary>
        public override void BizProc()
        {
            if (File.Exists(Util.GetAppConfigValue(BatchConst.JUCHU_INFO_CSV_ERROR_FILE)))
            {
                // 【エラー一覧ファイル】を削除する。
                File.Delete(Util.GetAppConfigValue(BatchConst.JUCHU_INFO_CSV_ERROR_FILE));
            }

            Util.FtpDownload(Util.GetAppConfigValue(ConstCsvDownloadFile), CsvFile);
            // 登録用ファイルパス
            var strWritePath = Path.Combine(Path.GetDirectoryName(CsvFile), strWriteName);
            // インポートファイル作成処理
            MakeImportFileJuchu(CsvFile, strWritePath);
            Torikomi(strWritePath);
        }

        #endregion 業務処理

        #region 受注取込み

        /// <summary>
        /// 受注取込み
        /// </summary>
        private void Torikomi(string filePath)
        {
            var parameters = new object[] {SqlConst.P_KAISHA_CD+ CommConst.COMMA+ KaishaCd,
                SqlConst.P_USER_ID + CommConst.COMMA+ Util.GetAppConfigValue(CommConst.USER_ID) ,
                SqlConst.P_FILE_PATH + CommConst.COMMA+ filePath };

            var dsResult = new DataSet();
            try
            {
                var dbAccess = new DbAccess(Logger, ConnectionStrings);
                try
                {
                    dsResult = dbAccess.ExecuteStoredProcedure(Stored, parameters);
                }
                finally
                {
                    dbAccess.Close();
                }
            }
            finally
            {
                if (File.Exists(Path.Combine(Path.GetDirectoryName(CsvFile), strWriteName)))
                {
                    // 【一時登録用ファイル】を削除する。
                    File.Delete(Path.Combine(Path.GetDirectoryName(CsvFile), strWriteName));
                }
                if (File.Exists(tempPath))
                {
                    // 【一時登録用tmpファイル】を削除する。
                    File.Delete(tempPath);
                }
            }

            // dsResultの１つ目のテーブルの先頭行先頭列が０以外の場合はエラー
            if (Convert.ToInt32(dsResult.Tables[0].Rows[0][0]) != 0)
            {
                if (Convert.ToInt32(dsResult.Tables[0].Rows[0][0]) == 1)
                {
                    throw new Exception(Utility.ReplaceMsg(Utility.GetMsg(MsgConst.BB0023E), new string[] { CsvFile }));
                }
            }
            else if (dsResult.Tables[1].Rows.Count > 0)
            {
                // エラーCSVファイル出力パス
                var ErrorCsvFile = Util.GetAppConfigValue(BatchConst.JUCHU_INFO_CSV_ERROR_FILE);
                Util.DataTableToCsv(dsResult.Tables[1], ErrorCsvFile, BatchNm, Encoding.GetEncoding(Util.GetAppConfigValue(CommConst.CSV_ENCODING)), CommConst.QUOTE_ALL_FIELDS_FLAG_TRUE, CommConst.FOOTER_FLAG_FALSE);
                throw new Exception(Utility.ReplaceMsg(Utility.GetMsg(MsgConst.BB0024E), new string[] { ErrorCsvFile }));
            }
            else
            {   //取込成功の場合
                Count = Convert.ToInt32(dsResult.Tables[3].Rows[0][0]);
                //bkファルダに移動
                JuchuMoveFile();
                //正常の場合Ftpのファイルを削除する
                Util.FtpDelete(Util.GetAppConfigValue(BatchConst.JUCHU_INFO_CSV_DOWNLOAD_FILE));
            }
        }

        #endregion 受注取込み

        /// <summary>
        /// インポートファイル作成処理
        /// </summary>
        /// <param name="readPath">入力ファイルパス（アップロードファイル）</param>
        /// <param name="writePath">出力ファイルパス（作成ファイルパス）</param>
        private void MakeImportFileJuchu(string readPath, string writePath)
        {
            // ファイルパス
            tempPath = Path.ChangeExtension(readPath, "tmp");
            // インスタンスswを生成
            using (var sw = new StreamWriter(tempPath, false, Encoding.Unicode)) // BULK INSERTに対応するためUTF-8ではなくunicode
            {
                // インスタンスparserを生成
                using (var parser = new TextFieldParser(readPath, Encoding.GetEncoding("UTF-8")))
                {
                    // TextFieldParserインスタンスparserのプロパティを設定する
                    parser.TextFieldType = FieldType.Delimited;
                    parser.SetDelimiters(",");
                    parser.HasFieldsEnclosedInQuotes = true;
                    // 行番号(int)を定義
                    var lineNum = 0;

                    while (!parser.EndOfData)
                    {
                        // 行番号をインクリメント
                        lineNum++;
                        // １行読み出し
                        var RdFields = parser.ReadFields();

                        if (RdFields.Length > 1)
                        {
                            // エラー内容変数を定義
                            var errorMsg = "";

                            // 列数チェックを行う
                            var blnColumnCount = true;

                            if (!COLUMN_NUM_JUCHU.Equals(RdFields.Length))
                            {
                                blnColumnCount = false;
                            }

                            if (!blnColumnCount)
                            {
                                throw new Exception(Utility.ReplaceMsg(Utility.GetMsg(MsgConst.BB0022E), new string[] { RdFields.Length.ToString() }));
                            }
                            // 付加情報：行番号、エラー内容、TMP_ID、GRP_KEY、受注番号、品目SEQ
                            //データを作成する
                            var stringBuilder = new StringBuilder();
                            //『行番号(文字列化)』
                            stringBuilder.Append(lineNum.ToString());
                            // 『カンマ』
                            stringBuilder.Append(",");
                            // 『エラー内容』
                            stringBuilder.Append(errorMsg);
                            // 『カンマ』
                            stringBuilder.Append(",");
                            // 『TMP_ID(空文字)』
                            stringBuilder.Append("");
                            //『カンマ』
                            stringBuilder.Append(",");
                            // 『GRP_KEY(空文字)』
                            stringBuilder.Append("");
                            //『カンマ』
                            stringBuilder.Append(",");
                            // 『受注番号(空文字)』
                            stringBuilder.Append("");
                            //『カンマ』
                            stringBuilder.Append(",");
                            // 『受注枝番(空文字)』
                            stringBuilder.Append("");
                            //『カンマ』
                            stringBuilder.Append(",");
                            // 『品目シーケンス(空文字)』
                            stringBuilder.Append("");
                            //『カンマ』
                            stringBuilder.Append(",");
                            // 『受注数量(空文字)』
                            stringBuilder.Append("");
                            //『カンマ』
                            stringBuilder.Append(",");
                            // 『受注単価(空文字)』
                            stringBuilder.Append("");
                            //『カンマ』
                            stringBuilder.Append(",");
                            // 『税率(空文字)』
                            stringBuilder.Append("");
                            //『カンマ』
                            stringBuilder.Append(",");
                            // 『税率指定区分(空文字)』
                            stringBuilder.Append("");
                            //『カンマ』
                            stringBuilder.Append(",");
                            // 『掛率参照区分(空文字)』
                            stringBuilder.Append("");
                            //『カンマ』
                            stringBuilder.Append(",");
                            // 『引当区分(空文字)』
                            stringBuilder.Append("");
                            //『カンマ』
                            stringBuilder.Append(",");
                            RdFields.ToList().ForEach(y =>
                            {
                                // 項目内のカンマを半角スペースに置換
                                stringBuilder.Append(y.Replace(",", " "));
                                // 『カンマ』
                                stringBuilder.Append(",");
                            });
                            // データを書き込む
                            sw.WriteLine(stringBuilder.ToString().Substring(0, stringBuilder.ToString().Length - 1));
                        }
                    }
                }
            }
            // tempPathのファイルを出力ファイルパス（フルパス）にコピーする
            File.Copy(tempPath, writePath, true);
        }
    }
}