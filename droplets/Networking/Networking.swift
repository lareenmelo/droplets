//
//  Networking.swift
//  droplets
//
//  Created by Lareen Melo on 11/4/25.
//

import Foundation

struct Networking {
    private let apiKey = "getUrs"
    let baseURL = "https://api.openweathermap.org/data/2.5/weather"

    func fetchWeather(
        latitude: Double,
        longitude: Double,
        completion: @escaping (Result<Weather, Error>) -> Void) {
            guard let url = URL(string: "\(baseURL)?lat=\(latitude)&lon=\(longitude)&appid=\(apiKey)") else { return }
            
            let urlRequest = URLRequest(url: url)
            let dataTask = URLSession.shared.dataTask(with: urlRequest) { data, _, error in
                guard let data = data else { return }
                
                do {
                    let jsonData = try JSONDecoder().decode(WeatherResponse.self, from: data)
                    let weather = WeatherResponse.buildWeather(from: jsonData)
                    
                    completion(.success(weather))
                    
                } catch let error {
                    completion(.failure(error))
                }
            }
            
            dataTask.resume()
        }
}
