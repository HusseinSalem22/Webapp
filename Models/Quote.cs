namespace Appen.Models

{
    public class Quote
    {

        public string author { get; set; }
        public string quote { get; set; }

        public Quote(string author, string quote)
        {
            this.author = author;
            this.quote = quote;
        }

        public Quote()
        {
            
        }



    }
}