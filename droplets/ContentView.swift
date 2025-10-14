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
    private let apiKey = "getYourOwn"
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
                fetchWeather(
                    latitude: weatherService.coordinates?.latitude ?? 0.0,
                    longitude: weatherService.coordinates?.longitude ?? 0.0) { result in
                        switch result {
                        case .success(let weather):
                            temperature = weather.inCelsius
                            cityName = weatherService.coordinates?.name ?? ""
                        case .failure(_): print("failure")
                        }
                    }
            }
        }
    }
}

#Preview {
    ContentView()
}

// MARK: - Data
class WeatherService: NSObject, CLLocationManagerDelegate, ObservableObject {
    @Published
    var coordinates: City?
    private var locationManager = CLLocationManager()

    override init () {
        super.init()
        
        locationManager.delegate = self
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
                if error == nil,
                   let placemarks = placemarks,
                   !placemarks.isEmpty,
                   let placemark = placemarks.first,
                   let cityName = placemark.locality
                {
                    let currentCoordinates = City(
                        name: cityName,
                        latitude: latitude,
                        longitude: longitude
                    )
                    
                    self.coordinates = currentCoordinates
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        // TODO: Handle Error
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .restricted,
                .denied:
            print("Handle Location Denied")
        case .authorizedAlways,
                .authorizedWhenInUse:
            manager.requestLocation()
        @unknown default:
            print("Handle unknown error")
        }
    }
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

struct WeatherResponse: Decodable {
    var main: WeatherData
    
    struct WeatherData: Decodable {
        var temp: Double
    }
    
    static func buildWeather(from response: WeatherResponse) -> Weather {
        .init(temperature: response.main.temp)
    }
}


// MARK: - Networking
extension ContentView {
    func fetchWeather(
        latitude: Double,
        longitude: Double,
        session: URLSession = .shared,
        completion: @escaping (Result<Weather, Error>) -> Void
    ) {
        guard let url = URL(string: "https://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)&appid=\(apiKey)") else { return }
        
        let urlRequest = URLRequest(url: url)
        let dataTask = session.dataTask(with: urlRequest) { data, _, error in
            guard let data = data else { return }
            
            do {
                let jsonData = try JSONDecoder().decode(WeatherResponse.self, from: data)
                let weather = WeatherResponse.buildWeather(from: jsonData)
                
                completion(.success(weather))
                
            } catch let error {
                completion(.failure(error))
            }
        }
        
        dataTask.resume()
    }
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
