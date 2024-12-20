using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json;
using Appen.Models;
using System.IO;

namespace Appen.Controllers
{
    public class QuotesController : Controller
    {
        public IActionResult Index()
        {
            // Read the JSON file
            var json = System.IO.File.ReadAllText("quotes.json");

            // Deserialize into a QuoteContainer
            var quoteContainer = JsonConvert.DeserializeObject<QuoteContainer>(json);

            // Access the list of quotes
            var quotesList = quoteContainer.Quotes;

            //Show a random quote when a button is clicked 
            var random = new Random();
            var randomQuote = quotesList[random.Next(quotesList.Count)];
            return View(randomQuote);
        }

        [HttpPost]
        public IActionResult GetRandomQuote()
        {
            // Read the JSON file
            var json = System.IO.File.ReadAllText("quotes.json");

            // Deserialize into a QuoteContainer
            var quoteContainer = JsonConvert.DeserializeObject<QuoteContainer>(json);

            // Access the list of quotes
            var quotesList = quoteContainer.Quotes;

            // Show a random quote
            var random = new Random();
            var randomQuote = quotesList[random.Next(quotesList.Count)];
            return Json(randomQuote);
        }
           
            

        }
    }

