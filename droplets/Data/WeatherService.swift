//
//  WeatherService.swift
//  droplets
//
//  Created by Lareen Melo on 11/30/25.
//

import Foundation

protocol WeatherServiceProtocol {
    func fetchWeather(for coordinates: Coordinate) async throws -> Measurement<UnitTemperature>
}

struct WeatherService: WeatherServiceProtocol {
    init() {}
    
    func fetchWeather(
        for coordinates: Coordinate
    ) async throws -> Measurement<UnitTemperature> {
        let weather = try await Networking().fetchWeather(
            latitude: coordinates.latitude,
            longitude: coordinates.longitude
        )
        
        return weather.temperature
    }
}
