//
//  WeatherService.swift
//  droplets
//
//  Created by Lareen Melo on 11/30/25.
//

import Foundation

struct WeatherService {
    func fetchWeather(
        for coordinates: City?
    ) async throws -> Measurement<UnitTemperature> {
        let weather = try await Networking().fetchWeather(
            latitude: coordinates?.latitude ?? 0.0,
            longitude: coordinates?.longitude ?? 0.0
        )
        
        return weather.temperature
    }
}
