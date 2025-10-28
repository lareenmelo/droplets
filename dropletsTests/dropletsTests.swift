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
}
