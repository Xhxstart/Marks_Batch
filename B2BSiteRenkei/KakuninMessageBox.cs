using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;

namespace B2BSiteRenkei
{
    public partial class KakuninMessageBox : Form
    {
        public KakuninMessageBox()
        {
            InitializeComponent();
        }

        public KakuninMessageBox(Point location, Size size, string title, string message)
        {
            InitializeComponent();
            lblMessage.Text = message;
            Text = title;
            StartPosition = FormStartPosition.Manual;
            Location = new Point(location.X + (size.Width - Size.Width) / 2, location.Y + (size.Height - Size.Height) / 2);
        }

        private void btnYes_Click(object sender, EventArgs e)
        {
            DialogResult = DialogResult.Yes;
        }

        private void btnNo_Click(object sender, EventArgs e)
        {
            DialogResult = DialogResult.No;
        }
    }
}