using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace LinkDataBizplusToecbeing_ShukkaJisseki
{
    internal class Program
    {
        private static int Main(string[] args)
        {
            var shukkaJisseki = new ShukkaJisseki(args);
            return shukkaJisseki.Main();
        }
    }
}