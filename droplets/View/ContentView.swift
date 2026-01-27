//
//  ContentView.swift
//  droplets
//
//  Created by Lareen Melo on 6/14/25.
//

import CoreLocation
import MapKit
import SwiftUI

struct ContentView: View {
    private var viewModel = ViewModel()
    @State var presentCitySearchSheet = false
        
    var body: some View {
        VStack {
            if let city = viewModel.currentCoordinates?.name {
                Text("Temperature in \(city)")
                Text("\(viewModel.weather) Celsius")
                
                Button(action: { presentCitySearchSheet.toggle() }, label: { Text("Search City") })
            }
        }
        .padding()
        .sheet(isPresented: $presentCitySearchSheet) {
            CitySearchView(
                city: .constant(viewModel.currentCoordinates),
                dismissViewAction: { presentCitySearchSheet.toggle() }
            )
        }
        .task(id: viewModel.location.coordinates) {
            await viewModel.fetchWeather()
        }
    }
}

#Preview {
    ContentView()
}

// MARK: - View Model
extension ContentView {
    @Observable
    class ViewModel {
        var location = LocationProvider()
        var weatherService = WeatherService()

        var weather: Int = 0
        var currentCoordinates: City?
        
        func fetchWeather() async {
            do {
                currentCoordinates = await coordinates(for: location.coordinates)
                weather = try await weatherService.fetchWeather(for: currentCoordinates)
            } catch {
                // TODO: Handle Error
            }
        }
    }
}

// MARK: CLGeocoder
extension ContentView.ViewModel {    
    private func coordinates(
        for location: CLLocation?
    ) async -> City? {
        guard let location else { return nil }
        
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
    
            guard let placemark = placemarks.first,
                  let city = placemark.locality else {
                return nil
            }
            
            return .init(name: city, latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        } catch {
            return nil
        }
    }
}

enum LocationError: Error {
    case locationNotDetermined
}
