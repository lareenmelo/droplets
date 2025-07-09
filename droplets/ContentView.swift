//
//  ContentView.swift
//  droplets
//
//  Created by Lareen Melo on 6/14/25.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    private let apiKey = "getYourOwn"
    @ObservedObject
    private var weatherService = WeatherService()

    @State var temperature: Int = 0
    
    var body: some View {
        VStack {
            Text("\(temperature) Celsius")
        }
        .padding()
        .onChange(of: weatherService.coordinates) { oldValue, newValue in
            if let newValue {
                DispatchQueue.main.async {
                    fetchWeather(latitude: newValue.latitude,
                                 longitude: newValue.longitude
                    ) { result in
                        switch result {
                        case .success(let weather):
                            temperature = weather.inCelsius
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
    var coordinates: WeatherServiceLocation?
    
    struct WeatherServiceLocation: Equatable {
        var latitude: Double
        var longitude: Double
    }

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
            
            let currentCoordinates = WeatherServiceLocation(
                latitude: latitude,
                longitude: longitude
            )
            
            coordinates = currentCoordinates
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
