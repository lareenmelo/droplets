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
    @State private var viewModel = ViewModel()
    @State var presentCitySearchSheet = false

    var body: some View {
        VStack {
            if viewModel.location.coordinates == nil {
                Image(systemName: "map.circle.fill")
                    .resizable()
                    .frame(width: 56, height: 56)
                Text("Search for a city to get started")
            } else {
                if let viewState = viewModel.viewState {
                    switch viewState.loadingState {
                    case .loading: Text("Loading...")
                    case .loaded(let temperature):
                        Text("Temperature in \(viewState.city.name)")
                        Text(temperature.formatted())
                    case .error: Text("Some error occurred")
                    }
                }
            }
            Button(action: { presentCitySearchSheet.toggle() }, label: { Text("Search City") })
        }
        .padding()
        .sheet(isPresented: $presentCitySearchSheet) {
            CitySearchView(
                city: Binding(
                    get: { viewModel.viewState?.city },
                    set: { newCity in
                        if let newCity = newCity {
                            viewModel.location.coordinates = .init(latitude: newCity.coordinate.latitude, longitude: newCity.coordinate.longitude)
                        }
                    }
                ),
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
    enum LoadingState: Equatable {
        case loading
        case loaded(Measurement<UnitTemperature>)
        case error
    }
    
    struct ViewState {
        var city: City
        var loadingState: LoadingState = .loading
    }
    
    @Observable
    class ViewModel {
        var viewState: ViewState?
        var location = LocationProvider()
        
        func fetchWeather() async {
            do {
                let currentCity = try await coordinates(for: location.coordinates)
                viewState = .init(city: currentCity)
                let temperature = try await WeatherService.fetchWeather(for: currentCity.coordinate)
                viewState?.loadingState = .loaded(temperature)

            } catch {
                // TODO: Handle Error
                viewState?.loadingState = .error
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
