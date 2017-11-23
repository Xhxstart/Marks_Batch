using System;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using B2BSiteRenkei.Common.Const;
using log4net;

namespace B2BSiteRenkei.Common
{
    /// <summary>
    /// データアクセスクラス
    /// </summary>
    public class DbAccess
    {
        #region 変数定義

        /// <summary>
        /// ロガー
        /// </summary>
        private ILog logger;

        /// <summary>
        /// コネクション
        /// </summary>
        private SqlConnection sqlCon;

        /// <summary>
        /// トランザクション
        /// </summary>
        private SqlTransaction sqlTran;

        /// <summary>
        /// ステートメント
        /// </summary>
        private SqlCommand cmd;

        /// <summary>
        /// コネクション接続文字列
        /// </summary>
        private string connection;

        #endregion 変数定義

        #region コンストラクタ

        /// <summary>
        /// コンストラクタ
        /// </summary>
        /// <param name="log">ロガー</param>
        /// <param name="conn">コネクション</param>
        public DbAccess(ILog log, string conn)
        {
            logger = log;
            connection = conn;
            // 新しいコネクション
            sqlCon = new SqlConnection(connection);
            // データベース接続を開く
            Open();
        }

        #endregion コンストラクタ

        #region publicメソッド

        #region コネクションオープン

        /// <summary>
        /// コネクションオープン
        /// </summary>
        public void Open()
        {
            try
            {
                sqlCon.Open();
            }
            catch (Exception ex)
            {
                logger.Error(Utility.GetMsg(MsgConst.BB0004E));
                throw;
            }
        }

        #endregion コネクションオープン

        #region トランザクション開始

        /// <summary>
        /// トランザクション開始
        /// </summary>
        public void BeginTransaction()
        {
            //トランザクションの開始
            sqlTran = sqlCon.BeginTransaction();
        }

        #endregion トランザクション開始

        #region コミット

        /// <summary>
        /// コミット
        /// </summary>
        public void Commit()
        {
            if (sqlTran.Connection != null)
            {
                sqlTran.Commit();
                sqlTran.Dispose();
            }
        }

        #endregion コミット

        #region ロールバック

        /// <summary>
        /// ロールバック
        /// </summary>
        public void RollBack()
        {
            if (sqlTran.Connection != null)
            {
                sqlTran.Rollback();
                sqlTran.Dispose();
            }
        }

        #endregion ロールバック

        #region コネクションクローズ

        /// <summary>
        /// コネクションクローズ
        /// </summary>
        public void Close()
        {
            try
            {
                if (sqlCon != null)
                {
                    sqlCon.Close();
                    sqlCon.Dispose();
                }
            }
            catch (Exception ex)
            {
                logger.Error(Utility.GetMsg(MsgConst.BB0008E));
                throw;
            }
        }

        #endregion コネクションクローズ

        #region データ取得

        /// <summary>
        /// データ取得
        /// </summary>
        /// <param name="query">クエリー</param>
        /// <param name="parameters">パラメータ</param>
        /// <returns>データテーブル</returns>
        public DataTable Reader(string query, object[] parameters)
        {
            try
            {
                cmd = new SqlCommand(query, sqlCon);
                cmd.CommandTimeout = sqlCon.ConnectionTimeout;
                SetParameter(parameters);
                cmd.CommandType = CommandType.Text;
                logger.Debug("SQL文：" + cmd.CommandText);
                OutputParameters(cmd.Parameters);
                var da = new SqlDataAdapter(cmd);
                var dt = new DataTable();
                da.Fill(dt);
                return dt;
            }
            catch (Exception ex)
            {
                logger.Error(Utility.GetMsg(MsgConst.BB0006E));
                throw;
            }
        }

        #endregion データ取得

        #region ストアド実行

        /// <summary>
        /// ストアド実行
        /// </summary>
        /// <param name="query">クエリー</param>
        /// <param name="parameters">パラメータ</param>
        /// <returns></returns>
        public DataSet ExecuteStoredProcedure(string query, object[] parameters)
        {
            try
            {
                cmd = new SqlCommand(query, sqlCon);
                cmd.CommandTimeout = sqlCon.ConnectionTimeout;
                SetParameter(parameters);
                cmd.CommandType = CommandType.StoredProcedure;
                logger.Debug("SQL文：" + cmd.CommandText);
                OutputParameters(cmd.Parameters);
                var da = new SqlDataAdapter(cmd);
                var ds = new DataSet();
                da.Fill(ds);
                return ds;
            }
            catch (Exception ex)
            {
                logger.Error(Utility.GetMsg(MsgConst.BB0006E));
                throw;
            }
        }

        #endregion ストアド実行

        #region SQL実行（登録、更新、削除）

        /// <summary>
        /// SQL実行
        /// </summary>
        /// <param name="query">sql文</param>
        /// <param name="parameters">パラメータ</param>
        /// <returns>件数</returns>
        public int ExecuteNonQuery(string query, object[] parameters)
        {
            var count = 0;
            try
            {
                cmd = new SqlCommand(query, sqlCon);
                cmd.CommandTimeout = sqlCon.ConnectionTimeout;
                cmd.Transaction = sqlTran;
                SetParameter(parameters);
                logger.Debug(Utility.GetMsg(MsgConst.BB0009I) + cmd.CommandText);
                OutputParameters(cmd.Parameters);
                count = cmd.ExecuteNonQuery();
            }
            catch (Exception ex)
            {
                logger.Error(Utility.GetMsg(MsgConst.BB0007E));
                throw;
            }
            return count;
        }

        #endregion SQL実行（登録、更新、削除）

        #endregion publicメソッド

        #region privateメソッド

        #region パラメータ設定

        /// <summary>
        /// パラメータ設定
        /// </summary>
        /// <param name="parameters">パラメータ群</param>
        private void SetParameter(object[] parameters)
        {
            if (cmd != null)
            {
                cmd.Parameters.Clear();
            }
            if (parameters == null)
            {
                return;
            }
            parameters.ToList().ForEach(arg =>
            {
                object[] argList = arg.ToString().Split(CommConst.CHAR_COMMA);
                var parameter = cmd.CreateParameter();
                if (argList == null)
                {
                    parameter.Value = (null);
                }
                else
                {
                    parameter.ParameterName = argList[0].ToString();
                    try
                    {
                        parameter.DbType = GetDbType(argList[1]);
                    }
                    catch (ArgumentException ex)
                    {
                        logger.Error(ex.Message);
                        throw new Exception(ex.Message);
                    }
                    parameter.Value = argList[1];
                    parameter.Size = argList[1].ToString().Count();
                    if (parameter.Size == 0)
                    {
                        parameter.Size = 1;
                    }
                }
                cmd.Parameters.Add(parameter);
            });
            cmd.Prepare();
        }

        #endregion パラメータ設定

        #region DBの型取得

        /// <summary>
        /// DBの型取得
        /// </summary>
        /// <param name="arg">オブジェクト</param>
        /// <returns></returns>
        private DbType GetDbType(object arg)
        {
            if (arg is int) return DbType.Int32;
            else if (arg is float || arg is double) return DbType.Double;
            else if (arg is string) return DbType.String;
            else if (arg is DateTime) return DbType.DateTime;
            else if (arg is bool) return DbType.Boolean;
            else throw new ArgumentException(Utility.GetMsg(MsgConst.BB0005E));
        }

        #endregion DBの型取得

        private void OutputParameters(SqlParameterCollection parameters)
        {
            if (parameters != null)
            {
                parameters.Cast<SqlParameter>().ToList().Select((parameter, idx) => new { idx, parameter }).ToList().ForEach(x =>
                {
                    logger.Debug(Utility.ReplaceMsg(Utility.GetMsg(MsgConst.BB0010I), new string[] { (x.idx + 1).ToString(), x.parameter.ParameterName, x.parameter.SqlValue.ToString() }));
                });
            }
        }

        #endregion privateメソッド
    }
}