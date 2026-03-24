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
            switch viewModel.state {
            case .error: Text("Some error occurred")
            case .loading: Text("Loading...")
            case .loaded(let temperature, let city):
                Text("Temperature in \(city.name)")
                Text(temperature.formatted())
                Button(action: { presentCitySearchSheet.toggle() }, label: { Text("Search City") })
            }
        }
        .padding()
        .sheet(isPresented: $presentCitySearchSheet) {
//            CitySearchView(
//                city: .constant(viewModel.currentCity),
//                dismissViewAction: { presentCitySearchSheet.toggle() }
//            )
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
    enum ContentViewState: Equatable {
        case loading
        case loaded(Measurement<UnitTemperature>, City)
        case error
    }
    
    @Observable
    class ViewModel {
        var state: ContentViewState = .loading
        var location = LocationProvider()
        
        func fetchWeather() async {
            do {
                let currentCity = try await coordinates(for: location.coordinates)
                let temperature = try await WeatherService.fetchWeather(for: currentCity.coordinate)
                
                self.state = .loaded(temperature, currentCity)
            } catch {
                // TODO: Handle Error
                state = .error
            }
        }
    }
}

// MARK: CLGeocoder
extension ContentView.ViewModel {    
    private func coordinates(
        for location: CLLocation?
    ) async throws -> City {
        guard let location else { throw LocationError.locationNotDetermined }

        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
    
            guard let placemark = placemarks.first,
                  let cityName = placemark.locality else {
                throw LocationError.geoencodingFailed
            }

            return .init(name: cityName, coordinate: .init(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude))
        } catch {
            throw LocationError.geoencodingFailed
        }
    }
}

enum LocationError: Error {
    case locationNotDetermined
    case geoencodingFailed
}
