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
    @State
    private var viewModel = ViewModel()

    var body: some View {
        NavigationStack {
            ContainerView(viewModel: viewModel)
                .searchable(text: $viewModel.searchText, placement: .toolbar, prompt: "Enter city")
        }
    }
}

struct ContainerView: View {
    @Bindable var viewModel: ContentView.ViewModel
    @Environment(\.isSearching) private var isSearching
    
    var body: some View {
        if isSearching {
            SearchView(results: viewModel.suggestedCities)
        } else {
            mainContent
                .task(id: viewModel.location.coordinates) {
                    await viewModel.fetchWeather()
                }
        }
    }
    
    @ViewBuilder
    var mainContent: some View {
        if viewModel.location.coordinates == nil {
            MainView()
        } else {
            if let viewState = viewModel.viewState {
                switch viewState.loadingState {
                case .loading, .error: MainView()
                case .loaded(let temperature, let city):
                    CityView(
                        city: city,
                        temperature: temperature.formatted()
                    )
                }
            }
        }
    }
}

extension ContentView {
    @Observable
    class ViewModel: NSObject {
        let completer = MKLocalSearchCompleter()
        var viewState: ViewState?
        
        let location = LocationProvider()
        
        var suggestedCities: [MKLocalSearchCompletion] = []
        var searchText = "" {
            didSet {
                completer.queryFragment = searchText
            }
        }
        
        override init() {
            super.init()
            
            completer.delegate = self
            completer.resultTypes = .address
            completer.addressFilter = .init(including: .locality)
        }
        
        func fetchWeather() async {
            do {
                let currentCity = try await coordinates(for: location.coordinates)
                viewState = .init(city: currentCity)
                let temperature = try await WeatherService.fetchWeather(for: currentCity.coordinate)
                viewState?.loadingState = .loaded(temperature, currentCity)

            } catch {
                // TODO: Handle Error
                viewState?.loadingState = .error
            }
        }
    }
}

extension ContentView.ViewModel: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        suggestedCities = completer.results
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: any Error) {
        print(#function, error)
    }
}

extension ContentView {
    enum LoadingState: Equatable {
        case loading
        case loaded(Measurement<UnitTemperature>, City)
        case error
    }
    
    struct ViewState {
        var city: City
        var loadingState: LoadingState = .loading
    }
}

#Preview {
    ContentView()
}


struct MainView: View {
    var body: some View {
        Text("Main View")
    }
}

struct CityView: View {
    let city: City
    let temperature: String
    
    var body: some View {
        VStack {
            Text(city.name)
            Text(temperature)
        }
    }
}

struct SearchView: View {
    let results: [MKLocalSearchCompletion]
    
    var body: some View {
        List(results, id: \.description) { city in
            Button(action: {
                // select city action
            }, label: {
                Text(city.title)
            })
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
