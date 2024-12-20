using System;
using System.Collections.Generic;
using Newtonsoft.Json;

namespace Appen.Models
{
    public class Meta
    {
        public int Found { get; set; }
        public int Returned { get; set; }
        public int Limit { get; set; }
        public int Page { get; set; }
    }

    public class Article
    {
        public string Uuid { get; set; }
        public string Title { get; set; }
        public string Description { get; set; }
        public string Keywords { get; set; }
        public string Snippet { get; set; }
        public string Url { get; set; }
        [JsonProperty("image_url")]
        public string ImageUrl { get; set; }
        public string Language { get; set; }
        public DateTime PublishedAt { get; set; }
        public string Source { get; set; }
        public List<string> Categories { get; set; }
        public double? RelevanceScore { get; set; }
        public string Locale { get; set; }
    }

    public class NewsResponse
    {
        public Meta Meta { get; set; }
        public List<Article> Data { get; set; }
    }
}
