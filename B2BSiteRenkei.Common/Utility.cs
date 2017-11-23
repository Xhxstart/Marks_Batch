using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.IO;
using System.Linq;
using System.Net;
using System.Reflection;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Xml.Linq;
using B2BSiteRenkei.Common.Const;
using CsvHelper;
using log4net;

namespace B2BSiteRenkei.Common
{
    public class Utility
    {
        #region 変数定義

        public static Configuration Config;

        private static XDocument Message;

        /// <summary>
        /// ロガー
        /// </summary>
        public ILog logger;

        #endregion 変数定義

        #region コンストラクタ

        /// <summary>
        /// コンストラクタ
        /// </summary>
        public Utility(ILog log)
        {
            if (Config == null)
            {
                Config = GetAppConfig(CommConst.APP_COMMON_CONFIG_FILE);
            }
            logger = log;
        }

        #endregion コンストラクタ

        #region App.config取得

        /// <summary>
        /// App.config取得
        /// </summary>
        /// <param name="appConfig"></param>
        /// <returns></returns>
        private Configuration GetAppConfig(string appConfig)
        {
            var configFile = new ExeConfigurationFileMap();
            configFile.ExeConfigFilename = Path.GetDirectoryName(Assembly.GetExecutingAssembly().CodeBase.Replace(CommConst.FILE_URI, "")) + CommConst.YEN_MARK + CommConst.APP_COMMON_CONFIG_FILE;
            return ConfigurationManager.OpenMappedExeConfiguration(configFile, ConfigurationUserLevel.None);
        }

        #endregion App.config取得

        #region コネクション取得

        public static string GetConnection(string connectName)
        {
            return Utility.Config.ConnectionStrings.ConnectionStrings[connectName].ToString();
        }

        #endregion コネクション取得

        #region メッセージ埋込文字変換

        /// <summary>
        /// メッセージ埋込文字変換
        /// </summary>
        /// <param name="msg">メッセージ</param>
        /// <param name="values">変換内容</param>
        /// <returns></returns>
        public static string ReplaceMsg(string msg, params string[] values)
        {
            if (values != null)
            {
                values.ToList().Select((value, idx) => new { idx, value }).ToList().ForEach(x =>
                {
                    msg = msg.Replace(CommConst.LEFT_BRACES + x.idx + CommConst.RIGHT_BRACES, x.value);
                });
            }

            return msg;
        }

        #endregion メッセージ埋込文字変換

        #region メッセージ取得

        /// <summary>
        /// メッセージ取得
        /// </summary>
        /// <param name="msgId"></param>
        /// <returns></returns>
        public static string GetMsg(string msgId)
        {
            var message = string.Empty;
            if (Message == null)
            {
                Message = XDocument.Load(Path.GetDirectoryName(Assembly.GetExecutingAssembly().CodeBase.Replace(CommConst.FILE_URI, "")) + CommConst.YEN_MARK + CommConst.MESSAGE + CommConst.YEN_MARK + CommConst.MESSAGES);
            }
            var msg = Message.Descendants(CommConst.MESSAGE).Where(x => msgId.Equals(x.Attribute(CommConst.ID).Value)).Select(x => x.Value).FirstOrDefault();
            if (msg != null)
            {
                message = msgId + CommConst.SEMI_COLON + msg;
            }
            return message;
        }

        #endregion メッセージ取得

        #region FTPサーバー情報取得

        private static string GetFtpAddress()
        {
            return Config.AppSettings.Settings[CommConst.FTP_SERVER_ADDRESS].Value; ;
        }

        private static string GetFtpPort()
        {
            return Config.AppSettings.Settings[CommConst.FTP_PORT].Value; ;
        }

        private static string GetFtpUserId()
        {
            return Config.AppSettings.Settings[CommConst.FTP_USERID].Value; ;
        }

        private static string GetFtpPassword()
        {
            return Config.AppSettings.Settings[CommConst.FTP_PASSWORD].Value; ;
        }

        #endregion FTPサーバー情報取得

        #region FTPプロキシサーバー情報取得

        private static string GetProxyAddress()
        {
            return Config.AppSettings.Settings[CommConst.PROXY_SERVER_ADDRESS].Value; ;
        }

        private static string GetProxyPort()
        {
            return Config.AppSettings.Settings[CommConst.PROXY_SERVER_PORT].Value; ;
        }

        private static string GetProxyUserId()
        {
            return Config.AppSettings.Settings[CommConst.PROXY_SERVER_USERID].Value; ;
        }

        private static string GetProxyPassword()
        {
            return Config.AppSettings.Settings[CommConst.PROXY_SERVER_PASSWORD].Value; ;
        }

        private static bool IsProxyUser()
        {
            return CommConst.USE.Equals(Config.AppSettings.Settings[CommConst.PROXY_SERVER].Value);
        }

        #endregion FTPプロキシサーバー情報取得

        #region データテーブルからCSV出力

        /// <summary>
        /// データテーブルからCSV出力
        /// </summary>
        /// <param name="dt"></param>
        /// <param name="fileFullName"></param>
        /// <param name="batchNm"></param>
        /// <param name="encoding"></param>
        /// <param name="quoteAllFieldsFlag"></param>
        /// <param name="footerFlag"></param>
        public void DataTableToCsv(DataTable dt, string fileFullName, string batchNm, Encoding encoding, bool quoteAllFieldsFlag, bool footerFlag)
        {
            try
            {
                var dir = (new FileInfo(fileFullName)).DirectoryName;
                if (!Directory.Exists(dir))
                {
                    Directory.CreateDirectory(dir);
                }
                using (var textWriter = new StreamWriter(fileFullName, false, encoding))
                {
                    var csv = new CsvWriter(textWriter);
                    csv.Configuration.QuoteAllFields = quoteAllFieldsFlag;

                    dt.Columns.Cast<DataColumn>().ToList().ForEach(column =>
                    {
                        csv.WriteField(column.ColumnName);
                    });
                    csv.NextRecord();
                    dt.Rows.Cast<DataRow>().ToList().ForEach(row =>
                    {
                        dt.Columns.Cast<DataColumn>().ToList().ForEach(x =>
                        {
                            var idx = dt.Columns.IndexOf(x);
                            csv.WriteField(row[idx]);
                        });
                        csv.NextRecord();
                    });
                    if (footerFlag)
                    {
                        csv.WriteField(dt.Rows.Count);
                        csv.NextRecord();
                    }
                }
            }
            catch (Exception ex)
            {
                logger.Error(ReplaceMsg(GetMsg(MsgConst.BB0017E), new string[] { batchNm }));
                throw;
            }
        }

        #endregion データテーブルからCSV出力

        #region 処理ログ解析

        /// <summary>
        /// 処理ログ解析
        /// </summary>
        /// <param name="fileFullName"></param>
        /// <param name="path"></param>
        /// <param name="batchName"></param>
        public DataTable KaisekiTraceLog(string filename, string path, string batchName)
        {
            if (!Directory.Exists(path))
            {
                var msg = Utility.ReplaceMsg(Utility.GetMsg(MsgConst.BB0012E), new string[] { CommConst.TRACE_LOG, path });
                throw new Exception(msg);
            }
            var filenames = Directory.GetFiles(path, GetAppConfigValueNoLog(BatchConst.LOG_FILE_SUFFIX_NAME));
            string fullFilename = filenames.Where(x => x.Contains(filename)).LastOrDefault();
            if (string.IsNullOrEmpty(fullFilename))
            {
                var msg = Utility.ReplaceMsg(Utility.GetMsg(MsgConst.BB0013E), new string[] { CommConst.TRACE_LOG });
                throw new Exception(msg);
            }
            DataTable dt = new DataTable();
            var header = GetAppConfigValueNoLog(BatchConst.LOG_HEADER).Split(CommConst.CHAR_COMMA).ToList();
            dt.Columns.AddRange(header.Select(x => new DataColumn(x, System.Type.GetType(CommConst.TYPE_OF_STRING))).ToArray());
            using (var streamReader = new StreamReader(new FileStream(fullFilename, FileMode.Open, FileAccess.Read, FileShare.ReadWrite),
                Encoding.GetEncoding(GetAppConfigValueNoLog(CommConst.LOG_ENCODING))))
            {
                var lineAllList = streamReader.ReadToEnd().Replace(CommConst.CRLF, CommConst.LF).Split(CommConst.CHAR_LF)
                    .Select((text, idx) => new { Idx = idx, Text = text }).ToList();
                var keyWordEnd = Utility.ReplaceMsg(Utility.GetMsg(MsgConst.BB0002I), new string[] { }).Split(CommConst.RIGHT_BRACES.FirstOrDefault()).LastOrDefault();
                var keyWordStart = Utility.ReplaceMsg(Utility.GetMsg(MsgConst.BB0001I), new string[] { }).Split(CommConst.RIGHT_BRACES.FirstOrDefault()).LastOrDefault();
                var endLineIdx = lineAllList.Where(x => x.Text.Contains(keyWordEnd)).Select(x => x.Idx).LastOrDefault();
                if (endLineIdx == 0)
                    return dt;
                var endLine = lineAllList[endLineIdx].Text;
                var threadCode = (endLine.IndexOf(CommConst.LEFT_SQUARE_BRACKET) < 0 || endLine.IndexOf(CommConst.RIGHT_SQUARE_BRACKET) < 0) ? string.Empty :
                    endLine.Substring(endLine.IndexOf(CommConst.LEFT_SQUARE_BRACKET), endLine.IndexOf(CommConst.RIGHT_SQUARE_BRACKET) - endLine.IndexOf(CommConst.LEFT_SQUARE_BRACKET) + 1);
                var startLineIdx = lineAllList.Where(x => x.Text.Contains(keyWordStart) && x.Text.Contains(threadCode) && x.Idx < endLineIdx).Select(x => x.Idx).LastOrDefault();
                var lineList = lineAllList.Where(x => x.Idx >= startLineIdx && x.Idx <= endLineIdx && x.Text.Contains(threadCode)).Select(x => x.Text).ToList();
                lineList.ForEach(line =>
                {
                    var words = line.Split(CommConst.CHAR_SPACE).ToArray();
                    DataRow row = dt.NewRow();
                    for (int i = 0; i < words.Count(); ++i)
                    {
                        if (i < header.Count() - 1)
                            row[i] = words[i];
                        else
                        {
                            row[header.Count() - 1] += words[i] + CommConst.CHAR_SPACE;
                        }
                    }
                    dt.Rows.Add(row);
                });
            }
            return dt;
        }

        #endregion 処理ログ解析

        #region 結果ログ解析

        /// <summary>
        /// 結果ログ解析
        /// </summary>
        /// <param name="fileFullName"></param>
        /// <param name="path"></param>
        /// <param name="logKeyword"></param>
        public List<string> KaisekiResultLog(string filename, string path, string logKeyword)
        {
            List<string> result = new List<string> { string.Empty, string.Empty };
            if (!Directory.Exists(path))
            {
                return result;
            }
            var filenames = Directory.GetFiles(path);
            string fullFilename = filenames.Where(x => x.Contains(filename)).OrderByDescending(x => x).FirstOrDefault();
            if (string.IsNullOrEmpty(fullFilename))
            {
                return result;
            }
            using (var streamReader = new StreamReader(new FileStream(fullFilename, FileMode.Open, FileAccess.Read, FileShare.ReadWrite),
                Encoding.GetEncoding(GetAppConfigValueNoLog(CommConst.LOG_ENCODING))))
            {
                var lineAllList = streamReader.ReadToEnd().Replace(CommConst.CRLF, CommConst.LF).Split(CommConst.CHAR_LF).ToList();
                var line = lineAllList.Where(x => (x.Contains(logKeyword + CommConst.ZENKAKU_SEMI_COLON + GetAppConfigValueNoLog(BatchConst.RESULT_OK)) ||
                    x.Contains(logKeyword + CommConst.ZENKAKU_SEMI_COLON + GetAppConfigValueNoLog(BatchConst.RESULT_NG)))).ToList();
                if (line.Count() > 0)
                    result = line.LastOrDefault().Substring(line.LastOrDefault().IndexOf(logKeyword)).Split(CommConst.CHAR_COMMA).ToList();
            }
            return result;
        }

        #endregion 結果ログ解析

        #region AppCommon.configからValueを取得

        /// <summary>
        /// AppCommon.configからValueを取得
        /// </summary>
        /// <param name="key"></param>
        public string GetAppConfigValue(string key)
        {
            var rtnValue = string.Empty;
            try
            {
                rtnValue = Config.AppSettings.Settings[key].Value;
                if (string.IsNullOrEmpty(rtnValue))
                {
                    throw new Exception(ReplaceMsg(GetMsg(MsgConst.BB0015E), new string[] { key }));
                }
            }
            catch (Exception ex)
            {
                logger.Error(GetMsg(MsgConst.BB0014E));
                throw;
            }
            return rtnValue;
        }

        #endregion AppCommon.configからValueを取得

        #region AppCommon.configからValueを取得

        /// <summary>
        /// AppCommon.configからValueを取得
        /// </summary>
        /// <param name="key"></param>
        public string GetAppConfigValueNoLog(string key)
        {
            var rtnValue = string.Empty;
            rtnValue = Config.AppSettings.Settings[key].Value;
            if (string.IsNullOrEmpty(rtnValue))
            {
                var msg = Utility.ReplaceMsg(Utility.GetMsg(MsgConst.BB0015E), new string[] { key });
                throw new Exception(msg);
            }
            return rtnValue;
        }

        #endregion AppCommon.configからValueを取得

        #region FTPサーバへアップロード

        /// <summary>
        /// FTPサーバへアップロード
        /// </summary>
        /// <param name="srcfFileName">アップロード元ファイル名</param>
        /// <param name="destFileName">アップロード先ファイル名</param>
        public void FtpUpload(string srcFileName, string destFileName)
        {
            // リトライ回数
            var ftpRetryTimes = int.Parse(GetAppConfigValue(CommConst.FTP_RETRY_TIMES));
            for (var idx = 1; idx <= ftpRetryTimes; idx++)
            {
                using (var wc = new WebClient())
                {
                    if (IsProxyUser())
                    {
                        // 認証情報設定
                        var proxy = new WebProxy(GetAppConfigValue(CommConst.PROXY_SERVER_ADDRESS), int.Parse(GetAppConfigValue(CommConst.PROXY_SERVER_PORT)));
                        proxy.Credentials = new NetworkCredential(GetAppConfigValue(CommConst.PROXY_SERVER_USERID), GetAppConfigValue(CommConst.PROXY_SERVER_PASSWORD));
                        wc.Proxy = proxy;
                    }

                    try
                    {
                        wc.Credentials = new NetworkCredential(GetAppConfigValue(CommConst.FTP_USERID), GetAppConfigValue(CommConst.FTP_PASSWORD));
                        wc.UploadFile(CommConst.FTP_URI +
                            GetAppConfigValue(CommConst.FTP_SERVER_ADDRESS) +
                            CommConst.SEMI_COLON +
                            GetAppConfigValue(CommConst.FTP_PORT) +
                            CommConst.SLASH +
                            destFileName,
                            srcFileName
                            );
                        break;
                    }
                    catch (Exception ex)
                    {
                        logger.Error(ReplaceMsg(GetMsg(MsgConst.BB0019E), new string[] { srcFileName }));
                        if (idx == ftpRetryTimes)
                        {
                            throw;
                        }
                        else
                        {
                            // リトライ間隔
                            Thread.Sleep(int.Parse(GetAppConfigValue(CommConst.FTP_RETRY_INTERVAL)));
                        }
                    }
                }
            }
        }

        #endregion FTPサーバへアップロード

        #region FTPサーバからダウンロード

        /// <summary>
        /// FTPサーバからダウンロード
        /// </summary>
        /// <param name="srcFileName">ダウンロード元ファイル名</param>
        /// <param name="destFileName">ダウンロード先ファイル名</param>
        public void FtpDownload(string srcFileName, string destFileName)
        {
            // リトライ回数
            var ftpRetryTimes = int.Parse(GetAppConfigValue(CommConst.FTP_RETRY_TIMES));
            for (var idx = 1; idx <= ftpRetryTimes; idx++)
            {
                using (var wc = new WebClient())
                {
                    if (IsProxyUser())
                    {
                        // 認証情報設定
                        var proxy = new WebProxy(GetAppConfigValue(CommConst.PROXY_SERVER_ADDRESS), int.Parse(GetAppConfigValue(CommConst.PROXY_SERVER_PORT)));
                        proxy.Credentials = new NetworkCredential(GetAppConfigValue(CommConst.PROXY_SERVER_USERID), GetAppConfigValue(CommConst.PROXY_SERVER_PASSWORD));
                        wc.Proxy = proxy;
                    }
                    var dir = (new FileInfo(destFileName)).DirectoryName;
                    if (!Directory.Exists(dir))
                    {
                        Directory.CreateDirectory(dir);
                    }
                    try
                    {
                        wc.Credentials = new NetworkCredential(GetAppConfigValue(CommConst.FTP_USERID), GetAppConfigValue(CommConst.FTP_PASSWORD));
                        wc.DownloadFile(CommConst.FTP_URI +
                            GetAppConfigValue(CommConst.FTP_SERVER_ADDRESS) +
                            CommConst.SEMI_COLON +
                            GetAppConfigValue(CommConst.FTP_PORT) +
                            CommConst.SLASH +
                            srcFileName,
                            destFileName
                            );
                        break;
                    }
                    catch (Exception ex)
                    {
                        logger.Error(ReplaceMsg(GetMsg(MsgConst.BB0018E), new string[] { srcFileName }));
                        if (idx == ftpRetryTimes)
                        {
                            throw;
                        }
                        else
                        {
                            // リトライ間隔
                            Thread.Sleep(int.Parse(GetAppConfigValue(CommConst.FTP_RETRY_INTERVAL)));
                        }
                    }
                }
            }
        }

        #endregion FTPサーバからダウンロード

        #region FTPサーバから削除

        /// <summary>
        /// FTPサーバから削除
        /// </summary>
        /// <param name="fileName">削除ファイル名</param>
        public void FtpDelete(string fileName)
        {
            // リトライ回数
            var ftpRetryTimes = int.Parse(GetAppConfigValue(CommConst.FTP_RETRY_TIMES));
            for (var idx = 1; idx <= ftpRetryTimes; idx++)
            {
                try
                {
                    var reqFTP = (FtpWebRequest)FtpWebRequest.Create(new Uri(CommConst.FTP_URI +
                        GetAppConfigValue(CommConst.FTP_SERVER_ADDRESS) +
                        CommConst.SEMI_COLON +
                        GetAppConfigValue(CommConst.FTP_PORT) +
                        CommConst.SLASH +
                        (new FileInfo(fileName)).Name));
                    reqFTP.Method = WebRequestMethods.Ftp.DeleteFile;
                    reqFTP.Credentials = new NetworkCredential(GetAppConfigValue(CommConst.FTP_USERID), GetAppConfigValue(CommConst.FTP_PASSWORD));
                    if (IsProxyUser())
                    {
                        // 認証情報設定
                        var proxy = new WebProxy(GetAppConfigValue(CommConst.PROXY_SERVER_ADDRESS), int.Parse(GetAppConfigValue(CommConst.PROXY_SERVER_PORT)));
                        proxy.Credentials = new NetworkCredential(GetAppConfigValue(CommConst.PROXY_SERVER_USERID), GetAppConfigValue(CommConst.PROXY_SERVER_PASSWORD));
                        reqFTP.Proxy = proxy;
                    }
                    FtpWebResponse response = (FtpWebResponse)reqFTP.GetResponse();
                    break;
                }
                catch (Exception ex)
                {
                    logger.Error(ReplaceMsg(GetMsg(MsgConst.BB0020E), new string[] { fileName }));
                    if (idx == ftpRetryTimes)
                    {
                        throw;
                    }
                    else
                    {
                        // リトライ間隔
                        Thread.Sleep(int.Parse(GetAppConfigValue(CommConst.FTP_RETRY_INTERVAL)));
                    }
                }
            }
        }

        #endregion FTPサーバから削除

        #region 結果ログ書込み

        /// <summary>
        /// 結果ログ書込み
        /// </summary>
        /// <param name="resultLog"></param>
        /// <param name="result"></param>
        /// <param name="dateTime"></param>
        public void WriteResultLog(ILog resultLog, string result, DateTime dateTime)
        {
            resultLog.Info(result + CommConst.COMMA + dateTime.ToString(CommConst.YYYY_MM_DD_HH_MM_SS));
        }

        #endregion 結果ログ書込み

        #region 連携件数取得

        /// <summary>
        /// 連携件数取得
        /// </summary>
        /// <param name="fileFullName"></param>
        /// <param name="path"></param>
        /// <param name="batchName"></param>
        public string GetRenkeiKensu(string filename, string path, string batchName)
        {
            string result = string.Empty;
            if (!Directory.Exists(path))
            {
                return result;
            }
            var filenames = Directory.GetFiles(path);
            string fullFilename = filenames.Where(x => x.Contains(filename)).OrderByDescending(x => x).FirstOrDefault();
            if (string.IsNullOrEmpty(fullFilename))
            {
                return result;
            }
            using (var streamReader = new StreamReader(new FileStream(fullFilename, FileMode.Open, FileAccess.Read, FileShare.ReadWrite),
                Encoding.GetEncoding(GetAppConfigValueNoLog(CommConst.LOG_ENCODING))))
            {
                var lineAllList = streamReader.ReadToEnd().Replace(CommConst.CRLF, CommConst.LF).Split(CommConst.CHAR_LF).ToList();
                var keyWord = Utility.ReplaceMsg(Utility.GetMsg(MsgConst.BB0003I), new string[] { batchName, null });
                keyWord = keyWord.Substring(0, keyWord.IndexOf(CommConst.ZENKAKU_SEMI_COLON));
                var line = lineAllList.Where(x => (x.Contains(keyWord))).ToList();
                if (line.Count() > 0)
                    result = line.LastOrDefault().Substring(line.LastOrDefault().IndexOf(CommConst.KEN), line.LastOrDefault().LastIndexOf(CommConst.KEN) - line.LastOrDefault().IndexOf(CommConst.KEN));
                if (string.IsNullOrEmpty(result))
                    return string.Empty;
                var matches = Regex.Match(result, CommConst.SEISU_SEISOKU_HYOGEN);
                if (matches.Success)
                    result = matches.Groups[0].Value;
            }
            return result;
        }

        #endregion 連携件数取得

        #region エラーCSV内容解析

        /// <summary>
        /// エラーCSV内容解析
        /// </summary>
        /// <param name="fileFullName"></param>
        /// <param name="path"></param>
        /// <param name="logKeyword"></param>
        public DataTable KaisekiErrorCSV(string fullFilename)
        {
            if (!File.Exists(fullFilename))
            {
                var msg = Utility.ReplaceMsg(Utility.GetMsg(MsgConst.BB0013E), new string[] { CommConst.LEFT_PARENTHESES + fullFilename + CommConst.RIGHT_PARENTHESES });
                throw new Exception(msg);
            }
            DataTable dt = new DataTable();
            using (var streamReader = new StreamReader(new FileStream(fullFilename, FileMode.Open, FileAccess.Read, FileShare.ReadWrite),
                Encoding.GetEncoding(GetAppConfigValueNoLog(CommConst.CSV_ENCODING))))
            {
                var csv = new CsvHelper.CsvReader(streamReader);
                csv.ReadHeader();
                var columns = csv.FieldHeaders;
                foreach (var column in columns)
                {
                    dt.Columns.Add(column, System.Type.GetType(CommConst.TYPE_OF_STRING));
                }
                while (csv.Read())
                {
                    var row = dt.NewRow();
                    foreach (DataColumn column in dt.Columns)
                    {
                        row[column.ColumnName] = csv.GetField(column.DataType, column.ColumnName);
                    }
                    dt.Rows.Add(row);
                }
                dt.Columns.Add(BatchConst.ERROR_KOMOKU_NM, System.Type.GetType(CommConst.TYPE_OF_STRING));
                foreach (DataRow row in dt.Rows)
                {
                    row[BatchConst.ERROR_KOMOKU_NM] = row[BatchConst.ERROR_JOHO];
                    string errorJoho = string.Empty;
                    row[BatchConst.ERROR_KOMOKU_NM].ToString().Split(CommConst.CHAR_CR).Where(x => !dt.Columns.Contains(x)).ToList().ForEach(x =>
                    {
                        errorJoho += x;
                    });
                    row[BatchConst.ERROR_JOHO] = errorJoho;
                }
            }
            return dt;
        }

        #endregion エラーCSV内容解析
    }
}