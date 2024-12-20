using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json;
using System.Net.Http;
using System.Threading.Tasks;
using Appen.Models;

namespace Appen.Controllers
{
    public class NewsController : Controller
    {
        private readonly HttpClient _httpClient;

        public NewsController(HttpClient httpClient)
        {
            _httpClient = httpClient;
        }
                                                 // GET: News
        public async Task<IActionResult> Index()
        {
            string apiUrl = Variables.apiKey.key; // API URL
           
            var response = await _httpClient.GetAsync(apiUrl);

            if (!response.IsSuccessStatusCode)
            {
                // Handle error
                return View("Error");
            }

            var jsonString = await response.Content.ReadAsStringAsync();
            var newsResponse = JsonConvert.DeserializeObject<NewsResponse>(jsonString);

            return View(newsResponse);
        }
    }
}
