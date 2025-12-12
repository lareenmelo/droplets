//
//  WeatherService.swift
//  droplets
//
//  Created by Lareen Melo on 11/30/25.
//

class WeatherService {
    func fetchWeather(
        for coordinates: City?,
        completion: @escaping (Int, String?) -> Void
    ) {
        Networking().fetchWeather(
            latitude: coordinates?.latitude ?? 0.0,
            longitude: coordinates?.longitude ?? 0.0) { result in
                switch result {
                case .success(let temperature):
                    completion(temperature.inCelsius, coordinates?.name)
                case .failure(_):
                    print("Handle networking call error")
                }
            }
    }
}
