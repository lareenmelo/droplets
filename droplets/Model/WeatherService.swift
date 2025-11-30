//
//  WeatherService.swift
//  droplets
//
//  Created by Lareen Melo on 11/30/25.
//

import CoreLocation

class WeatherService: NSObject, CLLocationManagerDelegate, ObservableObject {
    @Published
    var coordinates: City?
    private var locationManager = CLLocationManager()
    
    override init() {
        super.init()

        locationManager.delegate = self
    }
}

// MARK: Location Manager

extension WeatherService {
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

// MARK: - Networking

extension WeatherService {
    func fetchWeather(completion: @escaping (Int, String?) -> Void) {
        Networking().fetchWeather(
            latitude: coordinates?.latitude ?? 0.0,
            longitude: coordinates?.longitude ?? 0.0) { result in
                switch result {
                case .success(let temperature):
                    completion(temperature.inCelsius, self.coordinates?.name)
                case .failure(_): print("Handle networking call error")
                }
            }
    }
}
