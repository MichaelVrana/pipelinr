# library(devtools)
library(httr)
library(jsonlite)
library(dplyr)
library(purrr)
library(ggplot2)

# devtools::load_all()

cities_by_country_url <- "https://countriesnow.space/api/v0.1/countries/cities"

get_cities <- function(country) {
    body <- list(country = country) %>% toJSON(., auto_unbox = TRUE)

    POST(cities_by_country_url, add_headers("Content-Type" = "application/json"), body = body) %>%
        content() %>%
        pluck("data") %>%
        unlist() %>%
        data.frame(name = ., country = country)
}

city_population_url <- "https://countriesnow.space/api/v0.1/countries/population/cities"

get_city_population <- function(city) {
    body <- list(city = city) %>% toJSON(., auto_unbox = TRUE)

    population_counts <- POST(city_population_url, add_headers("Content-Type" = "application/json"), body = body) %>%
        content()

    population <- population_counts %>%
        pluck("data", "populationCounts", 1, "value") %>%
        as.numeric()

    if (is_empty(population)) {
        paste("Failed to retrieve population for city", city$name) %>% stop()
    }

    population
}

pipeline <- make_pipeline(
    nigerian_cities = stage(function() get_cities("nigeria")),
    #
    ethiopian_cities = stage(function() get_cities("ethiopia")),
    #
    cities = stage(function(nigerian_cities, ethiopian_cities) {
        rbind(nigerian_cities, ethiopian_cities)
    }),
    #
    city_populations = stage(
        inputs = stage_inputs(
            city = mapped(cities)
        ),
        function(city) {
            city$population <- get_city_population(city$name)
            city
        }
    ),
    #
    total_city_population = stage(
        inputs = stage_inputs(
            city_populations = collect_df(city_populations)
        ),
        function(city_populations) {
            cities$population <- city_populations
            cities %>%
                group_by(country) %>%
                summarize(total_population = sum(population))
        }
    ),
    #
    plot_city_population_by_country = stage(function(total_city_population) {
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

make(pipeline = pipeline)
