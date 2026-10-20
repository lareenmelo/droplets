//
//  WeatherService.swift
//  droplets
//
//  Created by Lareen Melo on 11/30/25.
//

import Foundation

protocol WeatherServiceProtocol {
    var location: LocationProvider { get }
    func fetchWeather(for coordinates: Coordinate) async throws -> Measurement<UnitTemperature>
}

struct WeatherService: WeatherServiceProtocol {
    // TODO: Location protocol??? 😭
    let location = LocationProvider()

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


// MARK: Fake
struct FakeWeatherService: WeatherServiceProtocol {
    // TODO: Make fake location provider??
    let location = LocationProvider()

    init() {}

    func fetchWeather(for coordinates: Coordinate) async throws -> Measurement<UnitTemperature> {
        .init(value: 0.0, unit: .fahrenheit)
    }
}
