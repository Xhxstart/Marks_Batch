using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Security;
using System.Threading;
using System.Windows.Forms;
using B2BSiteRenkei.Common;
using B2BSiteRenkei.Common.Const;

namespace B2BSiteRenkei
{
    public partial class RenkeiKakunin : Form
    {
        #region 変数定義

        /// <summary>
        /// Utility
        /// </summary>
        public Utility util = new Utility(null);

        /// <summary>
        /// ログ解析フォームリスト
        /// </summary>
        private List<LogKaiseki> logKaisekiFormList = new List<LogKaiseki> { };

        #endregion 変数定義

        #region コンストラクタ

        /// <summary>
        /// コンストラクタ
        /// </summary>
        public RenkeiKakunin()
        {
            InitializeComponent();
        }

        #endregion コンストラクタ

        #region 商品情報連携

        /// <summary>
        /// 商品情報連携
        /// </summary>
        private void btnHinmokuRenkei_Click(object sender, EventArgs e)
        {
            if (!KakuninMessageBox(lbl1.Text.Replace(CommConst.POINT, string.Empty)))
                return;
            LoadingForm loadingForm = new LoadingForm(DesktopLocation, Size, Utility.ReplaceMsg(Utility.GetMsg(MsgConst.BB0026I), new string[] { CommConst.BATCH_JIKKO_CYU }));
            try
            {
                lblSaishinJikkoTm.Text = lblHinmokuRenkeiResult.Text = lblHinmokuRenkeiResultKensu.Text = lblHinmokuRenkeiTime.Text = string.Empty;
                loadingForm.Show();
                loadingForm.Update();
                SetButtonEnable(true);
                CreatProcess(util.GetAppConfigValueNoLog(BatchConst.HINMOKU_INFO_BATCH_EXE_PATH), util.GetAppConfigValueNoLog(BatchConst.HINMOKU_INFO_BATCH_EXE_NAME), lbl1.Text, null);
                SetRenkeiResult(lblHinmokuRenkeiResult, lblHinmokuRenkeiTime, BatchConst.HINMOKU_INFO_RESULT_LOG_NAME, util.GetAppConfigValueNoLog(BatchConst.BIZPLUS_TO_ECBEINGT_RESULT_LOG_PATH), BatchConst.HINMOKU_INFO_RESULT_LOG_KEYWORD);
                SetRenkeiKensu(lblHinmokuRenkeiResult, lblHinmokuRenkeiResultKensu, BatchConst.HINMOKU_INFO_TRACE_LOG_NAME, util.GetAppConfigValueNoLog(BatchConst.BIZPLUS_TO_ECBEINGT_TRACE_LOG_PATH), BatchConst.HINMOKU_INFO_BATCH_NAME);
                lblSaishinJikkoTm.Text = DateTime.Now.ToString(CommConst.YYYY_MM_DD_HH_MM);
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, CommConst.ERROR_JPS);
            }
            finally
            {
                Application.DoEvents();
                SetButtonEnable(false);
                loadingForm.Close();
            }
        }

        #endregion 商品情報連携

        #region 得意先商品別価格情報連携

        /// <summary>
        /// 得意先商品別価格情報連携
        /// </summary>
        private void btnTokuisakiRenkei_Click(object sender, EventArgs e)
        {
            if (!KakuninMessageBox(lbl5.Text.Replace(CommConst.POINT, string.Empty)))
                return;
            LoadingForm loadingForm = new LoadingForm(DesktopLocation, Size, Utility.ReplaceMsg(Utility.GetMsg(MsgConst.BB0026I), new string[] { CommConst.BATCH_JIKKO_CYU }));
            try
            {
                lblSaishinJikkoTm.Text = lblTokuisakiRenkeiResult.Text = lblTokuisakiRenkeiResultKensu.Text = lblTokuisakiRenkeiTime.Text = string.Empty;
                loadingForm.Show();
                loadingForm.Update();
                SetButtonEnable(true);
                CreatProcess(util.GetAppConfigValueNoLog(BatchConst.TOKUISAKI_HINMOKU_TANKA_INFO_BATCH_EXE_PATH), util.GetAppConfigValueNoLog(BatchConst.TOKUISAKI_HINMOKU_TANKA_INFO_BATCH_EXE_NAME), lbl5.Text, null);
                SetRenkeiResult(lblTokuisakiRenkeiResult, lblTokuisakiRenkeiTime, BatchConst.TOKUISAKI_HINMOKU_TANKA_INFO_RESULT_LOG_NAME, util.GetAppConfigValueNoLog(BatchConst.BIZPLUS_TO_ECBEINGT_RESULT_LOG_PATH), BatchConst.TOKUISAKI_HINMOKU_TANKA_INFO_RESULT_LOG_KEYWORD);
                SetRenkeiKensu(lblTokuisakiRenkeiResult, lblTokuisakiRenkeiResultKensu, BatchConst.TOKUISAKI_HINMOKU_TANKA_INFO_TRACE_LOG_NAME, util.GetAppConfigValueNoLog(BatchConst.BIZPLUS_TO_ECBEINGT_TRACE_LOG_PATH), BatchConst.TOKUISAKI_HINMOKU_TANKA_INFO_BATCH_NAME);
                lblSaishinJikkoTm.Text = DateTime.Now.ToString(CommConst.YYYY_MM_DD_HH_MM);
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, CommConst.ERROR_JPS);
            }
            finally
            {
                Application.DoEvents();
                SetButtonEnable(false);
                loadingForm.Close();
            }
        }

        #endregion 得意先商品別価格情報連携

        #region 在庫情報連携

        /// <summary>
        /// 在庫情報連携
        /// </summary>
        private void btnZaikoRenkei_Click(object sender, EventArgs e)
        {
            if (!KakuninMessageBox(lbl9.Text.Replace(CommConst.POINT, string.Empty)))
                return;
            LoadingForm loadingForm = new LoadingForm(DesktopLocation, Size, Utility.ReplaceMsg(Utility.GetMsg(MsgConst.BB0026I), new string[] { CommConst.BATCH_JIKKO_CYU }));
            try
            {
                lblSaishinJikkoTm.Text = lblZaikoRenkeiResult.Text = lblZaikoRenkeiResultKensu.Text = lblZaikoRenkeiTime.Text = string.Empty;
                loadingForm.Show();
                loadingForm.Update();
                SetButtonEnable(true);
                CreatProcess(util.GetAppConfigValueNoLog(BatchConst.ZAIKO_INFO_BATCH_EXE_PATH), util.GetAppConfigValueNoLog(BatchConst.ZAIKO_INFO_BATCH_EXE_NAME), lbl9.Text, null);
                SetRenkeiResult(lblZaikoRenkeiResult, lblZaikoRenkeiTime, BatchConst.ZAIKO_INFO_RESULT_LOG_NAME, util.GetAppConfigValueNoLog(BatchConst.BIZPLUS_TO_ECBEINGT_RESULT_LOG_PATH), BatchConst.ZAIKO_INFO_RESULT_LOG_KEYWORD);
                SetRenkeiKensu(lblZaikoRenkeiResult, lblZaikoRenkeiResultKensu, BatchConst.ZAIKO_INFO_TRACE_LOG_NAME, util.GetAppConfigValueNoLog(BatchConst.BIZPLUS_TO_ECBEINGT_TRACE_LOG_PATH), BatchConst.ZAIKO_INFO_BATCH_NAME);
                lblSaishinJikkoTm.Text = DateTime.Now.ToString(CommConst.YYYY_MM_DD_HH_MM);
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, CommConst.ERROR_JPS);
            }
            finally
            {
                Application.DoEvents();
                SetButtonEnable(false);
                loadingForm.Close();
            }
        }

        #endregion 在庫情報連携

        #region 入荷予定情報連携

        /// <summary>
        /// 入荷予定情報連携
        /// </summary>
        private void btnNyukaRenkei_Click(object sender, EventArgs e)
        {
            if (!KakuninMessageBox(lbl13.Text.Replace(CommConst.POINT, string.Empty)))
                return;
            LoadingForm loadingForm = new LoadingForm(DesktopLocation, Size, Utility.ReplaceMsg(Utility.GetMsg(MsgConst.BB0026I), new string[] { CommConst.BATCH_JIKKO_CYU }));
            try
            {
                lblSaishinJikkoTm.Text = lblNyukaRenkeiResult.Text = lblNyukaRenkeiResultKensu.Text = lblNyukaRenkeiTime.Text = string.Empty;
                loadingForm.Show();
                loadingForm.Update();
                SetButtonEnable(true);
                CreatProcess(util.GetAppConfigValueNoLog(BatchConst.NYUKA_YOTEI_INFO_BATCH_EXE_PATH), util.GetAppConfigValueNoLog(BatchConst.NYUKA_YOTEI_INFO_BATCH_EXE_NAME), lbl13.Text, null);
                SetRenkeiResult(lblNyukaRenkeiResult, lblNyukaRenkeiTime, BatchConst.NYUKA_YOTEI_INFO_RESULT_LOG_NAME, util.GetAppConfigValueNoLog(BatchConst.BIZPLUS_TO_ECBEINGT_RESULT_LOG_PATH), BatchConst.NYUKA_YOTEI_INFO_RESULT_LOG_KEYWORD);
                SetRenkeiKensu(lblNyukaRenkeiResult, lblNyukaRenkeiResultKensu, BatchConst.NYUKA_YOTEI_INFO_TRACE_LOG_NAME, util.GetAppConfigValueNoLog(BatchConst.BIZPLUS_TO_ECBEINGT_TRACE_LOG_PATH), BatchConst.NYUKA_YOTEI_INFO_BATCH_NAME);
                lblSaishinJikkoTm.Text = DateTime.Now.ToString(CommConst.YYYY_MM_DD_HH_MM);
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, CommConst.ERROR_JPS);
            }
            finally
            {
                Application.DoEvents();
                SetButtonEnable(false);
                loadingForm.Close();
            }
        }

        #endregion 入荷予定情報連携

        #region 受注情報連携

        /// <summary>
        /// 受注情報連携
        /// </summary>
        private void btnJuchuRenkei_Click(object sender, EventArgs e)
        {
            if (!KakuninMessageBox(lbl17.Text.Replace(CommConst.POINT, string.Empty)))
                return;
            LoadingForm loadingForm = new LoadingForm(DesktopLocation, Size, Utility.ReplaceMsg(Utility.GetMsg(MsgConst.BB0026I), new string[] { CommConst.BATCH_JIKKO_CYU }));
            try
            {
                lblSaishinJikkoTm.Text = lblJuchuRenkeiResult.Text = lblJuchuRenkeiResultKensu.Text = lblJuchuRenkeiTime.Text = string.Empty;
                loadingForm.Show();
                loadingForm.Update();
                SetButtonEnable(true);
                CreatProcess(util.GetAppConfigValueNoLog(BatchConst.JUCHU_INFO_BATCH_EXE_PATH), util.GetAppConfigValueNoLog(BatchConst.JUCHU_INFO_BATCH_EXE_NAME), lbl17.Text, null);
                SetRenkeiResult(lblJuchuRenkeiResult, lblJuchuRenkeiTime, BatchConst.JUCHU_INFO_RESULT_LOG_NAME, util.GetAppConfigValueNoLog(BatchConst.ECBEING_TO_BIZPLUS_RESULT_LOG_PATH), BatchConst.JUCHU_INFO_RESULT_LOG_KEYWORD);
                SetRenkeiKensu(lblJuchuRenkeiResult, lblJuchuRenkeiResultKensu, BatchConst.JUCHU_INFO_TRACE_LOG_NAME, util.GetAppConfigValueNoLog(BatchConst.ECBEING_TO_BIZPLUS_TRACE_LOG_PATH), BatchConst.JUCHU_INFO_BATCH_NAME);
                btnErrorCSVKakunin.Enabled = (lblJuchuRenkeiResult.Text == CommConst.MARK_BATSU ? true : false);
                lblSaishinJikkoTm.Text = DateTime.Now.ToString(CommConst.YYYY_MM_DD_HH_MM);
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, CommConst.ERROR_JPS);
            }
            finally
            {
                Application.DoEvents();
                SetButtonEnable(false);
                loadingForm.Close();
            }
        }

        #endregion 受注情報連携

        #region 出荷完了情報連携

        /// <summary>
        /// 出荷完了情報連携
        /// </summary>
        private void btnShukkaRenkei_Click(object sender, EventArgs e)
        {
            if (!KakuninMessageBox(lbl21.Text.Replace(CommConst.POINT, string.Empty)))
                return;
            LoadingForm loadingForm = new LoadingForm(DesktopLocation, Size, Utility.ReplaceMsg(Utility.GetMsg(MsgConst.BB0026I), new string[] { CommConst.BATCH_JIKKO_CYU }));
            try
            {
                ShukkaNyuryokuDialog shukkaNyuryokuDialog = new ShukkaNyuryokuDialog(Location, Size);
                shukkaNyuryokuDialog.ShowDialog(this);
                string JikkoNichiji = string.Empty;
                if (shukkaNyuryokuDialog.DialogResult == DialogResult.OK)
                    JikkoNichiji = shukkaNyuryokuDialog.GetJikkoNichiji();
                else
                    return;
                lblSaishinJikkoTm.Text = lblShukkaRenkeiResult.Text = lblShukkaRenkeiResultKensu.Text = lblShukkaRenkeiTime.Text = string.Empty;
                loadingForm.Show();
                loadingForm.Update();
                SetButtonEnable(true);
                CreatProcess(util.GetAppConfigValueNoLog(BatchConst.SHUKKA_JISSEKI_INFO_BATCH_EXE_PATH), util.GetAppConfigValueNoLog(BatchConst.SHUKKA_JISSEKI_INFO_BATCH_EXE_NAME), lbl21.Text, JikkoNichiji);
                SetRenkeiResult(lblShukkaRenkeiResult, lblShukkaRenkeiTime, BatchConst.SHUKKA_JISSEKI_INFO_RESULT_LOG_NAME, util.GetAppConfigValueNoLog(BatchConst.BIZPLUS_TO_ECBEINGT_RESULT_LOG_PATH), BatchConst.SHUKKA_JISSEKI_INFO_RESULT_LOG_KEYWORD);
                SetRenkeiKensu(lblShukkaRenkeiResult, lblShukkaRenkeiResultKensu, BatchConst.SHUKKA_JISSEKI_INFO_TRACE_LOG_NAME, util.GetAppConfigValueNoLog(BatchConst.BIZPLUS_TO_ECBEINGT_TRACE_LOG_PATH), BatchConst.SHUKKA_JISSEKI_INFO_BATCH_NAME);
                lblSaishinJikkoTm.Text = DateTime.Now.ToString(CommConst.YYYY_MM_DD_HH_MM);
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, CommConst.ERROR_JPS);
            }
            finally
            {
                Application.DoEvents();
                SetButtonEnable(false);
                loadingForm.Close();
            }
        }

        #endregion 出荷完了情報連携

        #region 連携バッチ実行

        /// <summary>
        /// 連携バッチ実行
        /// </summary>
        /// <param name="path"></param>
        /// <param name="batchFileName"></param>
        /// <param name="batchName"></param>
        /// <param name="arguments"></param>
        private void CreatProcess(string path, string batchFileName, string batchName, string arguments)
        {
            //if (!Directory.Exists(path) || !File.Exists(path + batchFileName))
            //{
            //    var msg = Utility.ReplaceMsg(Utility.GetMsg(MsgConst.BB0021E), new string[] { batchName, path + batchFileName });
            //    throw new Exception(msg);
            //}
            Process proBatch = new Process();
            string userName = CommConst.QUOTE + util.GetAppConfigValueNoLog(BatchConst.SERVER_USER_NAME) + CommConst.QUOTE;
            string password = CommConst.QUOTE + util.GetAppConfigValueNoLog(BatchConst.SERVER_PASSWORD) + CommConst.QUOTE;
            string psExec = Environment.CurrentDirectory + util.GetAppConfigValueNoLog(BatchConst.PSEXEC);
            string pslist = Environment.CurrentDirectory + util.GetAppConfigValueNoLog(BatchConst.PSLIST);
            if (!File.Exists(psExec))
            {
                var msg = Utility.ReplaceMsg(Utility.GetMsg(MsgConst.BB0030E), new string[] { psExec });
                throw new Exception(msg);
            }
            if (!File.Exists(pslist))
            {
                var msg = Utility.ReplaceMsg(Utility.GetMsg(MsgConst.BB0030E), new string[] { pslist });
                throw new Exception(msg);
            }
            proBatch.StartInfo.FileName = psExec;
            string serverName = CommConst.YEN_MARK + CommConst.YEN_MARK + util.GetAppConfigValueNoLog(BatchConst.SERVER_NAME);
            var argvs = Utility.ReplaceMsg(util.GetAppConfigValueNoLog(BatchConst.PSEXEC_ARGV), new string[] { userName, password, serverName, path + batchFileName, arguments });
            proBatch.StartInfo.Arguments = argvs;
            string output = string.Empty;
            proBatch.StartInfo.UseShellExecute = false;
            proBatch.StartInfo.CreateNoWindow = true;
            proBatch.StartInfo.RedirectStandardError = true;
            proBatch.Start();
            output = proBatch.StandardError.ReadToEnd();
            proBatch.WaitForExit();
            if (output.Contains(Utility.ReplaceMsg(util.GetAppConfigValueNoLog(BatchConst.PSEXEC_SERVER_ERROR), new string[] { serverName.Replace(CommConst.YEN_MARK, string.Empty) })))
            {
                var msg = Utility.ReplaceMsg(Utility.GetMsg(MsgConst.BB0029E), new string[] { serverName.Replace(CommConst.YEN_MARK, string.Empty) });
                throw new Exception(msg);
            }
            if (output.Contains(util.GetAppConfigValueNoLog(BatchConst.PSEXEC_LOGON_FAIL)))
            {
                var msg = Utility.GetMsg(MsgConst.BB0028E);
                throw new Exception(msg);
            }
            if (output.Contains(Utility.ReplaceMsg(util.GetAppConfigValueNoLog(BatchConst.PSEXEC_FILE_NOT_FOUND), new string[] { path + batchFileName, serverName.Replace(CommConst.YEN_MARK, string.Empty) })))
            {
                var msg = Utility.ReplaceMsg(Utility.GetMsg(MsgConst.BB0021E), new string[] { batchName, path + batchFileName });
                throw new Exception(msg);
            }
            int pid = proBatch.ExitCode;
            proBatch.StartInfo.FileName = pslist;
            argvs = Utility.ReplaceMsg(util.GetAppConfigValueNoLog(BatchConst.PSLIST_ARGV), new string[] { userName, password, serverName, pid.ToString() });
            proBatch.StartInfo.Arguments = argvs;
            proBatch.StartInfo.UseShellExecute = false;
            proBatch.StartInfo.CreateNoWindow = true;
            proBatch.StartInfo.RedirectStandardOutput = true;
            do
            {
                proBatch.Start();
                output = proBatch.StandardOutput.ReadToEnd();
                proBatch.WaitForExit();
            }
            while (output.Contains(batchFileName.Replace(CommConst.EXE_EXTENSION, string.Empty)) && output.Contains(pid.ToString()));
            int waitTime = 0;
            Int32.TryParse(util.GetAppConfigValueNoLog(BatchConst.WAIT_TIME_FOR_LOG_WRITE), out waitTime);
            Thread.Sleep(waitTime);
        }

        #endregion 連携バッチ実行

        #region 商品情報連携ログ確認

        /// <summary>
        /// 商品情報連携ログ確認
        /// </summary>
        private void btnHinmokuLog_Click(object sender, EventArgs e)
        {
            CreatLogKaisekiForm(BatchConst.HINMOKU_INFO_TRACE_LOG_NAME, BatchConst.BIZPLUS_TO_ECBEINGT_TRACE_LOG_PATH, BatchConst.HINMOKU_INFO_BATCH_NAME, lbl1.Text + CommConst.LOG_KAISEKI);
        }

        #endregion 商品情報連携ログ確認

        #region 得意先商品別価格情報連携ログ確認

        /// <summary>
        /// 得意先商品別価格情報連携ログ確認
        /// </summary>
        private void btnTokuisakiLog_Click(object sender, EventArgs e)
        {
            CreatLogKaisekiForm(BatchConst.TOKUISAKI_HINMOKU_TANKA_INFO_TRACE_LOG_NAME, BatchConst.BIZPLUS_TO_ECBEINGT_TRACE_LOG_PATH, BatchConst.TOKUISAKI_HINMOKU_TANKA_INFO_BATCH_NAME, lbl5.Text + CommConst.LOG_KAISEKI);
        }

        #endregion 得意先商品別価格情報連携ログ確認

        #region 在庫情報連携ログ確認

        /// <summary>
        /// 在庫情報連携ログ確認
        /// </summary>
        private void btnZaikoLog_Click(object sender, EventArgs e)
        {
            CreatLogKaisekiForm(BatchConst.ZAIKO_INFO_TRACE_LOG_NAME, BatchConst.BIZPLUS_TO_ECBEINGT_TRACE_LOG_PATH, BatchConst.ZAIKO_INFO_BATCH_NAME, lbl9.Text + CommConst.LOG_KAISEKI);
        }

        #endregion 在庫情報連携ログ確認

        #region 入荷予定情報連携ログ確認

        /// <summary>
        /// 入荷予定情報連携ログ確認
        /// </summary>
        private void btnNyukaLog_Click(object sender, EventArgs e)
        {
            CreatLogKaisekiForm(BatchConst.NYUKA_YOTEI_INFO_TRACE_LOG_NAME, BatchConst.BIZPLUS_TO_ECBEINGT_TRACE_LOG_PATH, BatchConst.NYUKA_YOTEI_INFO_BATCH_NAME, lbl13.Text + CommConst.LOG_KAISEKI);
        }

        #endregion 入荷予定情報連携ログ確認

        #region 受注情報連携ログ確認

        /// <summary>
        /// 受注情報連携ログ確認
        /// </summary>
        private void btnJuchuLog_Click(object sender, EventArgs e)
        {
            CreatLogKaisekiForm(BatchConst.JUCHU_INFO_TRACE_LOG_NAME, BatchConst.ECBEING_TO_BIZPLUS_TRACE_LOG_PATH, BatchConst.JUCHU_INFO_BATCH_NAME, lbl17.Text + CommConst.LOG_KAISEKI);
        }

        #endregion 受注情報連携ログ確認

        #region 出荷完了情報連携ログ確認

        /// <summary>
        /// 出荷完了情報連携ログ確認
        /// </summary>
        private void btnShukkaLog_Click(object sender, EventArgs e)
        {
            CreatLogKaisekiForm(BatchConst.SHUKKA_JISSEKI_INFO_TRACE_LOG_NAME, BatchConst.BIZPLUS_TO_ECBEINGT_TRACE_LOG_PATH, BatchConst.SHUKKA_JISSEKI_INFO_BATCH_NAME, lbl21.Text + CommConst.LOG_KAISEKI);
        }

        #endregion 出荷完了情報連携ログ確認

        #region 最新情報更新

        /// <summary>
        /// 最新情報更新
        /// </summary>
        private void btnSaiShin_Click(object sender, EventArgs e)
        {
            LoadingForm loadingDialog = new LoadingForm(DesktopLocation, Size, Utility.ReplaceMsg(Utility.GetMsg(MsgConst.BB0026I), new string[] { CommConst.KEKKA_SHUTOKU_CYU }));
            try
            {
                loadingDialog.Show();
                loadingDialog.Update();
                SetButtonEnable(true);
                string pathBtoE = util.GetAppConfigValueNoLog(BatchConst.BIZPLUS_TO_ECBEINGT_RESULT_LOG_PATH);
                string pathEtoB = util.GetAppConfigValueNoLog(BatchConst.ECBEING_TO_BIZPLUS_RESULT_LOG_PATH);
                lblSaishinJikkoTm.Text = string.Empty;
                lblHinmokuRenkeiResult.Text = lblHinmokuRenkeiResultKensu.Text = lblHinmokuRenkeiTime.Text = string.Empty;
                lblTokuisakiRenkeiResult.Text = lblTokuisakiRenkeiResultKensu.Text = lblTokuisakiRenkeiTime.Text = string.Empty;
                lblZaikoRenkeiResult.Text = lblZaikoRenkeiResultKensu.Text = lblZaikoRenkeiTime.Text = string.Empty;
                lblNyukaRenkeiResult.Text = lblNyukaRenkeiResultKensu.Text = lblNyukaRenkeiTime.Text = string.Empty;
                lblJuchuRenkeiResult.Text = lblJuchuRenkeiResultKensu.Text = lblJuchuRenkeiTime.Text = string.Empty;
                lblShukkaRenkeiResult.Text = lblShukkaRenkeiResultKensu.Text = lblShukkaRenkeiTime.Text = string.Empty;
                SetRenkeiResult(lblHinmokuRenkeiResult, lblHinmokuRenkeiTime, BatchConst.HINMOKU_INFO_RESULT_LOG_NAME, pathBtoE, BatchConst.HINMOKU_INFO_RESULT_LOG_KEYWORD);
                SetRenkeiKensu(lblHinmokuRenkeiResult, lblHinmokuRenkeiResultKensu, BatchConst.HINMOKU_INFO_TRACE_LOG_NAME, util.GetAppConfigValueNoLog(BatchConst.BIZPLUS_TO_ECBEINGT_TRACE_LOG_PATH), BatchConst.HINMOKU_INFO_BATCH_NAME);
                SetRenkeiResult(lblTokuisakiRenkeiResult, lblTokuisakiRenkeiTime, BatchConst.TOKUISAKI_HINMOKU_TANKA_INFO_RESULT_LOG_NAME, pathBtoE, BatchConst.TOKUISAKI_HINMOKU_TANKA_INFO_RESULT_LOG_KEYWORD);
                SetRenkeiKensu(lblTokuisakiRenkeiResult, lblTokuisakiRenkeiResultKensu, BatchConst.TOKUISAKI_HINMOKU_TANKA_INFO_TRACE_LOG_NAME, util.GetAppConfigValueNoLog(BatchConst.BIZPLUS_TO_ECBEINGT_TRACE_LOG_PATH), BatchConst.TOKUISAKI_HINMOKU_TANKA_INFO_BATCH_NAME);
                SetRenkeiResult(lblZaikoRenkeiResult, lblZaikoRenkeiTime, BatchConst.ZAIKO_INFO_RESULT_LOG_NAME, pathBtoE, BatchConst.ZAIKO_INFO_RESULT_LOG_KEYWORD);
                SetRenkeiKensu(lblZaikoRenkeiResult, lblZaikoRenkeiResultKensu, BatchConst.ZAIKO_INFO_TRACE_LOG_NAME, util.GetAppConfigValueNoLog(BatchConst.BIZPLUS_TO_ECBEINGT_TRACE_LOG_PATH), BatchConst.ZAIKO_INFO_BATCH_NAME);
                SetRenkeiResult(lblNyukaRenkeiResult, lblNyukaRenkeiTime, BatchConst.NYUKA_YOTEI_INFO_RESULT_LOG_NAME, pathBtoE, BatchConst.NYUKA_YOTEI_INFO_RESULT_LOG_KEYWORD);
                SetRenkeiKensu(lblNyukaRenkeiResult, lblNyukaRenkeiResultKensu, BatchConst.NYUKA_YOTEI_INFO_TRACE_LOG_NAME, util.GetAppConfigValueNoLog(BatchConst.BIZPLUS_TO_ECBEINGT_TRACE_LOG_PATH), BatchConst.NYUKA_YOTEI_INFO_BATCH_NAME);
                SetRenkeiResult(lblShukkaRenkeiResult, lblShukkaRenkeiTime, BatchConst.SHUKKA_JISSEKI_INFO_RESULT_LOG_NAME, pathBtoE, BatchConst.SHUKKA_JISSEKI_INFO_RESULT_LOG_KEYWORD);
                SetRenkeiKensu(lblShukkaRenkeiResult, lblShukkaRenkeiResultKensu, BatchConst.SHUKKA_JISSEKI_INFO_TRACE_LOG_NAME, util.GetAppConfigValueNoLog(BatchConst.BIZPLUS_TO_ECBEINGT_TRACE_LOG_PATH), BatchConst.SHUKKA_JISSEKI_INFO_BATCH_NAME);
                SetRenkeiResult(lblJuchuRenkeiResult, lblJuchuRenkeiTime, BatchConst.JUCHU_INFO_RESULT_LOG_NAME, pathEtoB, BatchConst.JUCHU_INFO_RESULT_LOG_KEYWORD);
                SetRenkeiKensu(lblJuchuRenkeiResult, lblJuchuRenkeiResultKensu, BatchConst.JUCHU_INFO_TRACE_LOG_NAME, util.GetAppConfigValueNoLog(BatchConst.ECBEING_TO_BIZPLUS_TRACE_LOG_PATH), BatchConst.JUCHU_INFO_BATCH_NAME);
                btnErrorCSVKakunin.Enabled = (lblJuchuRenkeiResult.Text == CommConst.MARK_BATSU ? true : false);
                lblSaishinJikkoTm.Text = DateTime.Now.ToString(CommConst.YYYY_MM_DD_HH_MM);
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, CommConst.ERROR_JPS);
            }
            finally
            {
                Application.DoEvents();
                SetButtonEnable(false);
                loadingDialog.Close();
            }
        }

        #endregion 最新情報更新

        #region 連携日時、結果設定

        /// <summary>
        /// 連携日時、結果設定
        /// </summary>
        /// <param name="renkeiResult"></param>
        /// <param name="renkeiTime"></param>
        /// <param name="filename"></param>
        /// <param name="path"></param>
        /// <param name="logKeyword"></param>
        private void SetRenkeiResult(Label renkeiResult, Label renkeiTime, string filename, string path, string logKeyword)
        {
            filename = util.GetAppConfigValueNoLog(filename);
            logKeyword = util.GetAppConfigValueNoLog(logKeyword);
            path = CommConst.YEN_MARK + CommConst.YEN_MARK + util.GetAppConfigValueNoLog(BatchConst.SERVER_NAME) + CommConst.YEN_MARK + path.Replace(CommConst.CHAR_SLASH, CommConst.BACKSLASH).Replace(CommConst.SEMI_COLON, CommConst.DOLLAR);
            var result = util.KaisekiResultLog(filename, path, logKeyword);
            if (result == null || result.Count() == 0)
            {
                renkeiResult.Text = string.Empty;
                renkeiTime.Text = string.Empty;
            }
            else
            {
                if (result.FirstOrDefault().Contains(logKeyword + CommConst.ZENKAKU_SEMI_COLON + util.GetAppConfigValueNoLog(BatchConst.RESULT_OK)))
                {
                    renkeiResult.Text = CommConst.MARK_MARU;
                    renkeiTime.Text = string.Empty;
                    if (result.Count() >= 2)
                        renkeiTime.Text = result.LastOrDefault().Substring(0, result.LastOrDefault().LastIndexOf(CommConst.SEMI_COLON)).Replace(CommConst.SLASH, CommConst.HAIFUN);
                }
                else if (result.FirstOrDefault().Contains(logKeyword + CommConst.ZENKAKU_SEMI_COLON + util.GetAppConfigValueNoLog(BatchConst.RESULT_NG)))
                {
                    renkeiResult.Text = CommConst.MARK_BATSU;
                    renkeiTime.Text = string.Empty;
                    if (result.Count() >= 2)
                        renkeiTime.Text = result.LastOrDefault().Substring(0, result.LastOrDefault().LastIndexOf(CommConst.SEMI_COLON)).Replace(CommConst.SLASH, CommConst.HAIFUN);
                }
                else
                {
                    renkeiResult.Text = string.Empty;
                    renkeiTime.Text = string.Empty;
                }
            }
        }

        #endregion 連携日時、結果設定

        #region 連携件数設定

        /// <summary>
        /// 連携件数設定
        /// </summary>
        /// <param name="renkeiResult"></param>
        /// <param name="renkeiKensu"></param>
        /// <param name="filename"></param>
        /// <param name="path"></param>
        /// <param name="batchName"></param>
        private void SetRenkeiKensu(Label renkeiResult, Label renkeiKensu, string filename, string path, string batchName)
        {
            path = CommConst.YEN_MARK + CommConst.YEN_MARK + util.GetAppConfigValueNoLog(BatchConst.SERVER_NAME) + CommConst.YEN_MARK + path.Replace(CommConst.CHAR_SLASH, CommConst.BACKSLASH).Replace(CommConst.SEMI_COLON, CommConst.DOLLAR);
            if (renkeiResult.Text == CommConst.MARK_MARU)
            {
                filename = util.GetAppConfigValueNoLog(filename);
                batchName = util.GetAppConfigValueNoLog(batchName);
                int result = 0;
                Int32.TryParse(util.GetRenkeiKensu(filename, path, batchName), out result);
                renkeiKensu.Text = string.Format("{0:N0}", result);
            }
            else
                renkeiKensu.Text = CommConst.HAIFUN;
        }

        #endregion 連携件数設定

        #region ログ解析フォーム作成

        /// <summary>
        /// ログ解析フォーム作成
        /// </summary>
        /// <param name="filename"></param>
        /// <param name="path"></param>
        /// <param name="batchName"></param>
        /// <param name="formTitle"></param>
        private void CreatLogKaisekiForm(string filename, string path, string batchName, string formTitle)
        {
            LoadingForm loadingForm = new LoadingForm(DesktopLocation, Size, Utility.ReplaceMsg(Utility.GetMsg(MsgConst.BB0026I), new string[] { CommConst.LOG_KAISEKI_CYU }));
            try
            {
                path = CommConst.YEN_MARK + CommConst.YEN_MARK + util.GetAppConfigValueNoLog(BatchConst.SERVER_NAME) + CommConst.YEN_MARK + util.GetAppConfigValueNoLog(path).Replace(CommConst.CHAR_SLASH, CommConst.BACKSLASH).Replace(CommConst.SEMI_COLON, CommConst.DOLLAR);
                filename = util.GetAppConfigValueNoLog(filename);
                batchName = util.GetAppConfigValueNoLog(batchName);
                loadingForm.Show();
                loadingForm.Update();
                SetButtonEnable(true);
                var logKaisekiForm = logKaisekiFormList.Where(form => form.Text == formTitle).ToList();
                if (logKaisekiForm.Count() > 0)
                {
                    logKaisekiForm.FirstOrDefault().Close();
                }
                LogKaiseki logKaiseki = new LogKaiseki(util.KaisekiTraceLog(filename, path, batchName), filename, batchName, path);
                logKaiseki.Text = formTitle;
                logKaiseki.Show();
                logKaisekiFormList.Add(logKaiseki);
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, CommConst.ERROR_JPS);
            }
            finally
            {
                Application.DoEvents();
                SetButtonEnable(false);
                loadingForm.Close();
            }
        }

        #endregion ログ解析フォーム作成

        #region ボタン非活性

        /// <summary>
        /// ボタン非活性
        /// </summary>
        /// <param name="state"></param>
        private void SetButtonEnable(bool state)
        {
            this.Enabled = state == false ? true : false;
        }

        #endregion ボタン非活性

        #region 閉じる

        /// <summary>
        /// 閉じる
        /// </summary>
        private void closeBtn_Click(object sender, EventArgs e)
        {
            this.Close();
        }

        #endregion 閉じる

        #region 手動実行確認メッセージボクス

        /// <summary>
        /// 手動実行確認メッセージボクス
        /// </summary>
        /// <param name="text"></param>
        private bool KakuninMessageBox(string text)
        {
            KakuninMessageBox kakuninMessageBox = new KakuninMessageBox(this.Location, this.Size, text, Utility.ReplaceMsg(Utility.GetMsg(MsgConst.BB0027I), new string[] { text }));
            kakuninMessageBox.ShowDialog();
            return kakuninMessageBox.DialogResult == DialogResult.Yes;
        }

        #endregion 手動実行確認メッセージボクス

        #region エラーCSV内容確認

        /// <summary>
        /// エラーCSV内容確認
        /// </summary>
        private void btnErrorCSVKakunin_Click(object sender, EventArgs e)
        {
            var fullFilename = CommConst.YEN_MARK + CommConst.YEN_MARK + util.GetAppConfigValueNoLog(BatchConst.SERVER_NAME) + CommConst.YEN_MARK + util.GetAppConfigValueNoLog(BatchConst.JUCHU_INFO_CSV_ERROR_FILE).Replace(CommConst.CHAR_SLASH, CommConst.BACKSLASH).Replace(CommConst.SEMI_COLON, CommConst.DOLLAR);
            CreatErrorCSVKakuninForm(fullFilename);
        }

        #endregion エラーCSV内容確認

        #region エラーCSV内容確認フォーム作成

        /// <summary>
        /// エラーCSV内容確認フォーム作成
        /// </summary>
        /// <param name="fullFilename"></param>
        /// <param name="formTitle"></param>
        private void CreatErrorCSVKakuninForm(string fullFilename)
        {
            LoadingForm loadingForm = new LoadingForm(DesktopLocation, Size, Utility.ReplaceMsg(Utility.GetMsg(MsgConst.BB0026I), new string[] { CommConst.CSV_FILE_ERROR_KAISEKI_CYU }));
            try
            {
                var formTitle = CommConst.JUCHU_CSV_ERROR_ICHIRAN;
                loadingForm.Show();
                loadingForm.Update();
                SetButtonEnable(true);
                var logKaisekiForm = logKaisekiFormList.Where(form => form.Text == formTitle).ToList();
                if (logKaisekiForm.Count() > 0)
                {
                    logKaisekiForm.FirstOrDefault().Close();
                }
                LogKaiseki logKaiseki = new LogKaiseki(util.KaisekiErrorCSV(fullFilename), fullFilename, string.Empty, string.Empty);
                logKaiseki.Text = formTitle;
                logKaiseki.Show();
                logKaisekiFormList.Add(logKaiseki);
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, CommConst.ERROR_JPS);
            }
            finally
            {
                Application.DoEvents();
                SetButtonEnable(false);
                loadingForm.Close();
            }
        }

        #endregion エラーCSV内容確認フォーム作成
    }
}