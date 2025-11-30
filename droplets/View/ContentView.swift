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
    private var weatherService = WeatherService()
    @State var temperature: Int = 0
    @State var cityName: String?
    
    @State var presentCitySearchSheet = false
        
    var body: some View {
        VStack {
            if let city = cityName {
                Text("Temperature in \(city)")
                Text("\(temperature) Celsius")
                
                Button(action: { presentCitySearchSheet.toggle() }, label: { Text("Search City") })
            }
        }
        .padding()
        .sheet(isPresented: $presentCitySearchSheet) {
            CitySearchView(
                city: $weatherService.coordinates,
                dismissViewAction: { presentCitySearchSheet.toggle() }
            )
        }
        .task(id: weatherService.coordinates) {
            DispatchQueue.main.async {
                weatherService.fetchWeather { temperature, city in
                    self.temperature = temperature
                    self.cityName = city
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

// MARK: - Models
struct Weather {
    var temperature: Double
    
    var inCelsius: Int {
        Int(temperature - 273.15)
    }
}

struct City: Equatable {
    let name: String
    let latitude: Double
    let longitude: Double
}

// MARK: Views
struct CitySearchView: View {
    @ObservedObject var viewModel = ViewModel()
    @Binding var city: City?
    var dismissViewAction: () -> Void

    var body: some View {
        NavigationStack {
            List(viewModel.suggestedCities, id: \.self) { city in
                Button(action: {
                    searchLocation(completion: city)
                    dismissViewAction()
                }, label: {
                    Text(city.title)
                })
            }
        }
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer, prompt: "Enter city name")
    }

    private func searchLocation(completion: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: completion)
        searchRequest.naturalLanguageQuery = viewModel.searchText
        
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { response, error in
            if let response {
                for item in response.mapItems {
                    if let name = item.name,
                       let location = item.placemark.location {
                        city = .init(
                            name: name,
                            latitude: location.coordinate.latitude,
                            longitude: location.coordinate.longitude)
                    }
                }
            }
        }
    }
}

// MARK: City Search View Model
extension CitySearchView {
    class ViewModel: NSObject, ObservableObject {
        let completer = MKLocalSearchCompleter()
        @Published var suggestedCities: [MKLocalSearchCompletion] = []
        @Published var cities: [City] = []
        @Published var searchText = "" {
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

extension CitySearchView.ViewModel: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        suggestedCities = completer.results
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: any Error) {
        // TODO: Error Handling
        print(#function, error)
    }
}
