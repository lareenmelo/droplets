//
//  WeatherService.swift
//  droplets
//
//  Created by Lareen Melo on 11/30/25.
//

import Foundation

enum WeatherService {
    static func fetchWeather(
        for coordinates: Coordinate
    ) async throws -> Measurement<UnitTemperature> {
        let weather = try await Networking().fetchWeather(
            latitude: coordinates.latitude,
            longitude: coordinates.longitude
        )
        
        return weather.temperature
    }
}
