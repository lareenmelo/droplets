//
//  ContentView.swift
//  droplets
//
//  Created by Lareen Melo on 6/14/25.
//

import CoreLocation
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
            CitySearchView(city: $weatherService.coordinates)
        }
        .onChange(of: weatherService.coordinates) { oldValue, newValue in
            if let newValue {
                DispatchQueue.main.async {
                    fetchWeather(
                        latitude: newValue.latitude,
                        longitude: newValue.longitude
                    ) { result in
                        switch result {
                        case .success(let weather):
                            temperature = weather.inCelsius
                            cityName = newValue.name
                        case .failure(_): print("failure")
                        }
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

    override init () {
        super.init()
        
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else {
            locationManager.requestLocation()
        }
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
        // TODO: Handle Error IG
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
    func fetchWeather(latitude: Double, longitude: Double, completion: @escaping (Result<Weather, Error>) -> Void) {
        guard let url = URL(string: "https://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)&appid=\(apiKey)") else { return }
        
        let urlRequest = URLRequest(url: url)
        let dataTask = URLSession.shared.dataTask(with: urlRequest) { data, _, error in
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
    @State private var searchText: String = ""
    @Binding var city: City?

    let cities: [City] = [
        .init(name: "New York", latitude: 40.7128, longitude: -74.0060),
        .init(name: "Los Angeles", latitude: 34.0522, longitude: -118.2437),
        .init(name: "Chicago", latitude: 41.8781, longitude: -87.6298),
        .init(name: "Houston", latitude: 29.7604, longitude: -95.3698),
        .init(name: "Phoenix", latitude: 33.4484, longitude: -112.0740),
        .init(name: "San Francisco", latitude: 37.7749, longitude: -122.4194),
        .init(name: "Seattle", latitude: 47.6062, longitude: -122.3321)
    ]
        
    var filteredCities: [City] {
        if searchText.isEmpty { return cities }
        return cities.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List(filteredCities, id: \.name) { city in
                Button(action: {
                    self.city = city
                }, label: {
                    Text(city.name)
                })
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer, prompt: "Enter city name")
    }
}
