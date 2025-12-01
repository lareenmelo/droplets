//
//  Weather.swift
//  droplets
//
//  Created by Lareen Melo on 11/30/25.
//

struct Weather {
    var temperature: Double
    
    var inCelsius: Int {
        Int(temperature - 273.15)
    }
}
