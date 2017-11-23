using System;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Windows.Forms;
using B2BSiteRenkei.Common;
using B2BSiteRenkei.Common.Const;

namespace B2BSiteRenkei
{
    public partial class LogKaiseki : Form
    {
        #region 変数定義

        /// <summary>
        /// filename
        /// </summary>
        private string filename;

        /// <summary>
        /// batchname
        /// </summary>
        private string batchName;

        /// <summary>
        /// path
        /// </summary>
        private string path;

        /// <summary>
        /// Utility
        /// </summary>
        private Utility util;

        #endregion 変数定義

        #region コンストラクタ

        /// <summary>
        /// コンストラクタ
        /// </summary>
        public LogKaiseki()
        {
            InitializeComponent();
            util = new Utility(null);
        }

        /// <summary>
        /// コンストラクタ
        /// </summary>
        /// <param name="batchName"></param>
        /// <param name="dt"></param>
        /// <param name="filename"></param>
        /// <param name="path"></param>
        public LogKaiseki(DataTable dt, string filename, string batchName, string path)
        {
            InitializeComponent();
            util = new Utility(null);
            this.filename = filename;
            this.batchName = batchName;
            this.path = path;
            dgvLog.DataSource = dt;
            bool isCSVFile = filename.Split(CommConst.CHAR_SLASH).LastOrDefault().Contains(CommConst.CSV_EXTENSION);
            if (isCSVFile)
            {
                for (int i = 0; i < dgvLog.ColumnCount; ++i)
                    dgvLog.Columns[i].AutoSizeMode = DataGridViewAutoSizeColumnMode.AllCells;
                dgvLog.Columns[BatchConst.ERROR_KOMOKU_NM].Visible = false;
                dgvLog.Columns[0].Frozen = true;
                dgvLog.Columns[1].Frozen = true;
            }
            else
            {
                for (int i = 0; i < dgvLog.ColumnCount - 1; ++i)
                    dgvLog.Columns[i].Width = 100;
                dgvLog.Columns[dgvLog.ColumnCount - 1].AutoSizeMode = DataGridViewAutoSizeColumnMode.AllCells;
                dgvLog.Columns[0].Frozen = true;
                dgvLog.Columns[1].Frozen = true;
            }
        }

        #endregion コンストラクタ

        #region 閉じる

        /// <summary>
        /// 閉じる
        /// </summary>
        private void tsmClose_Click(object sender, EventArgs e)
        {
            Close();
        }

        #endregion 閉じる

        #region データ更新

        /// <summary>
        /// データ更新
        /// </summary>
        private void tsmKoshin_Click(object sender, EventArgs e)
        {
            bool isCSVFile = filename.Split(CommConst.CHAR_SLASH).LastOrDefault().Contains(CommConst.CSV_EXTENSION);
            DataTable dt = (DataTable)dgvLog.DataSource;
            dt.Rows.Clear();
            dgvLog.DataSource = dt;
            dgvLog.Refresh();
            LoadingForm loadingForm = new LoadingForm(DesktopLocation, Size,
                Utility.ReplaceMsg(Utility.GetMsg(MsgConst.BB0026I), new string[] { isCSVFile ? CommConst.CSV_FILE_ERROR_KAISEKI_CYU : CommConst.LOG_KAISEKI_CYU }));
            try
            {
                loadingForm.changeLoadingColor();
                loadingForm.Show();
                loadingForm.Update();
                this.Enabled = false;
                if (isCSVFile)
                {
                    dgvLog.DataSource = util.KaisekiErrorCSV(filename);
                }
                else
                    dgvLog.DataSource = util.KaisekiTraceLog(filename, path, batchName);
                dgvLog.Refresh();
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, CommConst.ERROR_JPS);
            }
            finally
            {
                Application.DoEvents();
                this.Enabled = true;
                loadingForm.Close();
            }
        }

        #endregion データ更新

        private void changeColor()
        {
            for (int i = 0; i < dgvLog.RowCount; ++i)
            {
                dgvLog[BatchConst.ERROR_KOMOKU_NM, i].Value.ToString().Split(CommConst.CHAR_CR).ToList().ForEach(x =>
                {
                    if (dgvLog.Columns.Contains(x))
                        dgvLog[x, i].Style.BackColor = Color.Red;
                });
            }
        }

        private void dgvLog_DataBindingComplete(object sender, DataGridViewBindingCompleteEventArgs e)
        {
            bool isCSVFile = filename.Split(CommConst.CHAR_SLASH).LastOrDefault().Contains(CommConst.CSV_EXTENSION);
            if (isCSVFile)
                changeColor();
        }
    }
}