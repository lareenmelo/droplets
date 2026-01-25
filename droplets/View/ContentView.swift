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
    @StateObject
    private var viewModel = ViewModel()
    
    @State var presentCitySearchSheet = false
        
    var body: some View {
        VStack {
            if let city = viewModel.cityName {
                Text("Temperature in \(city)")
                Text("\(viewModel.temperature) Celsius")
                
                Button(action: { presentCitySearchSheet.toggle() }, label: { Text("Search City") })
            }
        }
        .padding()
        .sheet(isPresented: $presentCitySearchSheet) {
            CitySearchView(
                city: $viewModel.currentCoordinates,
                dismissViewAction: { presentCitySearchSheet.toggle() }
            )
        }
        .task(id: viewModel.location.coordinates) {
            viewModel.fetchWeather()
        }
    }
}

#Preview {
    ContentView()
}

// MARK: - View Model
extension ContentView {
    class ViewModel: ObservableObject {
        var location = LocationProvider()
        var weatherService = WeatherService()

        @Published var temperature: Int = 0
        @Published var cityName: String?
        
        var currentCoordinates: City?
        
        func fetchWeather() {
            coordinates(for: location.coordinates) { self.currentCoordinates = $0
                self.weatherService.fetchWeather(for: self.currentCoordinates) { temperature, city in
                    DispatchQueue.main.async {
                        self.temperature = temperature
                        self.cityName = city
                    }
                }
            }
        }
    }
}

extension ContentView.ViewModel {
    private func coordinates(
        for location: CLLocation?,
        _ completion: @escaping (City?) -> Void
    ) {
        guard let location else {
            completion(nil)
            return
        }
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if error == nil,
               let placemarks = placemarks,
               !placemarks.isEmpty,
               let placemark = placemarks.first,
               let cityName = placemark.locality {
                completion(.init(
                    name: cityName,
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                ))
            }
        }
    }
}
