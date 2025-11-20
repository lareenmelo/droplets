//
//  NetworkingTests.swift
//  dropletsTests
//
//  Created by Lareen Melo on 11/4/25.
//

import Foundation
import Testing
@testable import droplets

struct NetworkingTests {
    let sut = Networking()
 
    let validJSONData = """
        {
            "main": {
                "temp": 298.08
            }
        }
    """
    
    @Test
    func hasCorrectBaseURL() {
        let url = URL(string: sut.baseURL)!
        
        #expect(url.scheme == "https")
        #expect(url.host == "api.openweathermap.org")
        #expect(url.path == "/data/2.5/weather")
    }
    
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
}
