namespace LinkDataBizplusToecbeing_Hinmoku
{
    internal class Program
    {
        private static int Main(string[] args)
        {
            var hinmoku = new Hinmoku(args);
            return hinmoku.Main();
        }
    }
}