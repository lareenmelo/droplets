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
    @Bindable
    private var viewModel = ViewModel()

    var body: some View {
        citySearchView
        .searchable(text: $viewModel.searchText, placement: .toolbar, prompt: "Enter city")
    }
    
    @ViewBuilder
    var citySearchView: some View {
        NavigationStack {
            List(viewModel.suggestedCities, id: \.self) { city in
                Button(action: {
                    // select city action
                }, label: {
                    Text(city.title)
                })
            }
        }
        
    }
}


//    var body: some View {
//        NavigationStack {
//            WeatherView()
//            .searchable(text: $testString, placement: .toolbar)
//        }
////        .task(id: viewModel.location.coordinates) {
////            await viewModel.fetchWeather()
////        }
//    }

extension ContentView {
    @Observable
    class ViewModel: NSObject {
        let completer = MKLocalSearchCompleter()
        
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

#Preview {
    ContentView()
}

// MARK: Search View
struct WeatherView: View {
    @State private var viewModel = ViewModel()
    @State var testString = ""
    @Environment(\.isSearching) private var isSearching
    
    var body: some View {
        VStack {
            if !isSearching {
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
            } else {
                CitySearchView(city: Binding(
                    get: { viewModel.viewState?.city },
                    set: { newCity in
                        if let newCity = newCity {
                            viewModel.location.coordinates = .init(latitude: newCity.coordinate.latitude, longitude: newCity.coordinate.longitude)
                        }
                    }
                ),
                               dismissViewAction: {/* TODO: Dismiss search state*/ }
                )
            }
        }
    }
}

// MARK: - View Model
extension WeatherView {
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
extension WeatherView.ViewModel {
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
