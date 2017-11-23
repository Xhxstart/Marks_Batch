namespace LinkDataBizplusToecbeing_Zaiko
{
    internal class Program
    {
        private static int Main(string[] args)
        {
            var zaiko = new Zaiko(args);
            return zaiko.Main();
        }
    }
}