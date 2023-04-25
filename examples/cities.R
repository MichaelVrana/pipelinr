library(devtools)
library(httr)
library(jsonlite)
library(dplyr)
library(purrr)
library(ggplot2)

devtools::load_all()

cities_by_country_url <- "https://countriesnow.space/api/v0.1/countries/cities"

get_cities <- function(country) {
    body <- list(country = country) %>% toJSON(., auto_unbox = TRUE)

    POST(cities_by_country_url, add_headers("Content-Type" = "application/json"), body = body) %>%
        content() %>%
        pluck("data") %>%
        unlist() %>%
        head(., n = 10) %>%
        data.frame(name = ., country = country)
}

city_population_url <- "https://countriesnow.space/api/v0.1/countries/population/cities"

get_city_population <- function(city) {
    body <- list(city = city) %>% toJSON(., auto_unbox = TRUE)

    population_counts <- POST(city_population_url, add_headers("Content-Type" = "application/json"), body = body) %>%
        content()

    population_counts %>%
        pluck("data", "populationCounts", 1, "value") %>%
        as.numeric()
}

pipeline <- make_pipeline(
    nigerian_cities = stage(function() get_cities("nigeria")),
    #
    turkish_cities = stage(function() get_cities("turkey")),
    #
    cities = stage(function(nigerian_cities, turkish_cities) {
        rbind(nigerian_cities, turkish_cities)
    }),
    #
    city_populations = stage(function(cities) {
        cities$population <- map(cities$name, get_city_population) %>% unlist()
        cities
    }),
    #
    plot_city_population_by_country = stage(function(city_populations) {
        total_city_population <- city_populations %>%
            group_by(country) %>%
            summarize(total_population = sum(population))

        ggplot(total_city_population, aes(x = country, y = total_population)) +
            geom_col() +
            xlab("Country") +
            ylab("City population") +
            ggtitle("Total city population by country")

        ggsave("total_city_population.png")
    })
)

make(pipeline = pipeline, plot_city_population_by_country)
