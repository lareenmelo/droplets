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
    @ObservedObject
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
                city: $viewModel.location.coordinates,
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
        var location = LocationService()
        var weatherService = WeatherService()

        @Published var temperature: Int = 0
        @Published var cityName: String?
                
        func fetchWeather() {
            weatherService.fetchWeather(for: location.coordinates) { temperature, city in
                DispatchQueue.main.async {
                    self.temperature = temperature
                    self.cityName = city
                }
            }
        }
    }
}
