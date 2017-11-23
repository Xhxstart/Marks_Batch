using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using B2BSiteRenkei.Common;
using B2BSiteRenkei.Common.Const;

namespace B2BSiteRenkei
{
    public partial class ShukkaNyuryokuDialog : Form
    {
        #region 変数定義

        /// <summary>
        /// JikkoNichiji
        /// </summary>
        private string JikkoNichiji;

        #endregion 変数定義

        #region コンストラクタ

        /// <summary>
        /// コンストラクタ
        /// </summary>
        public ShukkaNyuryokuDialog()
        {
            InitializeComponent();
        }

        /// <summary>
        /// コンストラクタ
        /// </summary>
        /// <param name="location"></param>
        /// <param name="size"></param>
        public ShukkaNyuryokuDialog(Point location, Size size)
        {
            InitializeComponent();
            StartPosition = FormStartPosition.Manual;
            Location = new Point(location.X + (size.Width - Size.Width) / 2, location.Y + (size.Height - Size.Height) / 2);
        }

        #endregion コンストラクタ

        public string GetJikkoNichiji()
        {
            return JikkoNichiji;
        }

        #region OKボタン押下

        /// <summary>
        /// OKボタン押下
        /// </summary>
        private void btnOK_Click(object sender, EventArgs e)
        {
            DateTime tmpDateTime = new DateTime();
            if (!string.IsNullOrEmpty(tbJikkoNichiji.Text) && !DateTime.TryParse(tbJikkoNichiji.Text, out tmpDateTime))
            {
                MessageBox.Show(Utility.ReplaceMsg(Utility.GetMsg(MsgConst.BB0025E), new string[] { }), CommConst.ERROR_JPS);
            }
            else
            {
                if (string.IsNullOrEmpty(tbJikkoNichiji.Text))
                    JikkoNichiji = string.Empty;
                else
                    JikkoNichiji = tmpDateTime.ToString();
                DialogResult = DialogResult.OK;
                Close();
            }
        }

        #endregion OKボタン押下

        #region キャンセルボタン押下

        /// <summary>
        /// キャンセルボタン押下
        /// </summary>
        private void btnCancel_Click(object sender, EventArgs e)
        {
            DialogResult = DialogResult.Cancel;
            Close();
        }

        #endregion キャンセルボタン押下
    }
}