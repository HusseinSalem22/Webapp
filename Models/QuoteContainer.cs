namespace Appen.Models
{
    public class QuoteContainer
    {
        public List<Quote> Quotes { get; set; }

        public QuoteContainer()
        {
            Quotes = new List<Quote>();
        }
    }
}
