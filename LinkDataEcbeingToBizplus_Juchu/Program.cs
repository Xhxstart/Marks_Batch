using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace LinkDataEcbeingToBizplus_Juchu
{
    internal class Program
    {
        private static int Main(string[] args)
        {
            var juchu = new Juchu(args);
            return juchu.Main();
        }
    }
}