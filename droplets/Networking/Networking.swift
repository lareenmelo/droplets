//
//  Networking.swift
//  droplets
//
//  Created by Lareen Melo on 11/4/25.
//

import Foundation

struct Networking {
    private let apiKey = Secrets.weatherAPIKey
    let baseURL = "https://api.openweathermap.org/data/2.5/weather"
    
    func fetchWeather(
        latitude: Double,
        longitude: Double
    ) async throws -> Weather {
        guard let url = URL(string: "\(baseURL)?lat=\(latitude)&lon=\(longitude)&appid=\(apiKey)") else { throw FetchError.invalidURL }
        
        let urlRequest = URLRequest(url: url)
        let (data, _) = try await URLSession.shared.data(for: urlRequest)
        let jsonData = try JSONDecoder().decode(WeatherResponse.self, from: data)
        let weather = WeatherResponse.buildWeather(from: jsonData)
        
        return weather
    }
}

// MARK: Weather Response Decoding

struct WeatherResponse: Decodable {
    var main: WeatherData
    
    struct WeatherData: Decodable {
        var temp: Double
    }
    
    static func buildWeather(from response: WeatherResponse) -> Weather {
        .init(temperature: response.main.temp)
    }
}

enum FetchError: Error {
    case invalidURL
}
