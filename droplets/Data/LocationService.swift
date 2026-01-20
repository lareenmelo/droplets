//
//  LocationService.swift
//  droplets
//
//  Created by Lareen Melo on 12/2/25.
//

import CoreLocation

@Observable
class LocationService: NSObject, CLLocationManagerDelegate {
    
    var coordinates: City?
    private var locationManager = CLLocationManager()
    
    override init() {
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
