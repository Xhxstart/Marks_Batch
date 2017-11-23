namespace LinkDataBizplusToecbeing_NyukaYotei
{
    internal class Program
    {
        private static int Main(string[] args)
        {
            var nyukaYotei = new NyukaYotei(args);
            return nyukaYotei.Main();
        }
    }
}