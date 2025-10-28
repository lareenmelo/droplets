//
//  dropletsTests.swift
//  dropletsTests
//
//  Created by Lareen Melo on 10/9/25.
//

import Foundation
import Testing
@testable import droplets

struct dropletsTests {

    // MARK: Object Parsing
    let validJSONData = """
        {
            "main": {
                "temp": 298.08
            }
        }
        """
    
    @Test
    func validWeatherJSONWhenParsedReturnsWeatherObject() {
        // Arrange
        let data = validJSONData.data(using: .utf8)!
        var weatherObject: Weather?
        
        // Act
        #expect(throws: Never.self) {
            let response = try JSONDecoder().decode(WeatherResponse.self, from: data)
            weatherObject = WeatherResponse.buildWeather(from: response)
        }

        // Assert
        #expect(weatherObject != nil)
    }
        
    // MARK: Networking
    @Test
    func fetchWeatherReturnsWeather() async {
        // Arrange
        let sut = ContentView()
        
        // Act
        await withCheckedContinuation { continuation in
            sut.fetchWeather(latitude: 0, longitude: 0) { result in
                switch result {
                case .success(let weather):
                    // Assert
                    #expect(weather.temperature > 0)
                case .failure: Issue.record()
                }
                continuation.resume()
            }
        }
    }
}
