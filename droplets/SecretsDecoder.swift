//
//  SecretsDecoder.swift
//  droplets
//
//  Created by Lareen Melo on 11/29/25.
//

import Foundation

enum Secrets {
    static var weatherAPIKey: String {
        guard let key = Bundle.main.infoDictionary?["WEATHER_API_KEY"] as? String else {
            fatalError("Weather API Key not found in Secrets.xcconfig")
        }
        
        return key
    }
}
