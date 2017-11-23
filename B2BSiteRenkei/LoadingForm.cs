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
    public partial class LoadingForm : Form
    {
        public LoadingForm()
        {
            InitializeComponent();
        }

        public LoadingForm(Point location, Size size, string text)
        {
            InitializeComponent();
            StartPosition = FormStartPosition.Manual;
            Location = location;
            Size = size;
            lblLoading.Text = text;
            lblLoading.Location = new Point((Size.Width - lblLoading.Width) / 2, (Size.Height - lblLoading.Height) / 2);
            TransparencyKey = BackColor;
            TopMost = true;
        }

        public void changeLoadingColor()
        {
            lblLoading.BackColor = Color.LightGray;
        }
    }
}