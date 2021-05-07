//
//  ViewController.swift
//  MapKitGetAddress
//
//  Created by Luis Genaro Arvizu Vega on 06/05/21.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {

    lazy var mapView: MKMapView = {
        let map = MKMapView()
        map.translatesAutoresizingMaskIntoConstraints = false
        map.delegate = self
//        map.showsUserLocation = true
        return map
    }()
    
    lazy var mapButton: MKUserTrackingButton = {
        MKUserTrackingButton(mapView: mapView)
    }()
    
    lazy var locationManager: CLLocationManager = {
       let manager = CLLocationManager()
        manager.delegate = self
        return manager
    }()
    
    lazy var gesture: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(userLongPressedMap))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        if CLLocationManager.locationServicesEnabled() {
            manageAuthorizationStatus(status: locationManager.authorizationStatus)
        }
        // Do any additional setup after loading the view.
    }
    
    private func setupUI() {
        let safeArea = view.safeAreaLayoutGuide
        
        view.addSubview(mapView)
        
        let constraints: [NSLayoutConstraint] = [mapView.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 0),
                                                 mapView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 0),
                                                 mapView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: 0),
                                                 mapView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: 0)]
        
        NSLayoutConstraint.activate(constraints)
        
        view.addSubview(mapButton)
        gesture.minimumPressDuration = 1.2
        gesture.allowableMovement = 10
        
        view.addGestureRecognizer(gesture)
    }
    
    private func manageAuthorizationStatus(status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse: locationManager.requestLocation()
        case .denied, .restricted: presentSettingsAlert()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            fatalError("New status added, please add it in the switch section")
        }
    }
    
    private func getAddress(from: CLLocation, completionHandler: @escaping(CLPlacemark?,Error?) -> Void ) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(from) { [weak self](marks: [CLPlacemark]?, error: Error?) in
            guard let self = self, let mark = marks?.first else {
                return
            }
            print(mark.debugDescription)
            self.presentAlert(country: mark.country!, locality: mark.locality!, sublocality: mark.subLocality, name: mark.name)
        }
    }
    
    private func presentSettingsAlert() {
        let alert: UIAlertController = UIAlertController(title: "Error",
                                                         message: "Change location app settings",
                                                         preferredStyle: .alert)
        let openSettingsAction: UIAlertAction = UIAlertAction(title: "Open settings", style: .default) {  _ in
            guard let url: URL = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(openSettingsAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    private func presentAlert(country: String, locality: String, sublocality: String?, name: String?) {
        let alert: UIAlertController = UIAlertController(title: "Location",
                                                         message: """
                                                            Country: \(country)
                                                            Locality: \(locality)
                                                            Sublocality: \(sublocality ?? "Null")
                                                            Name: \(name ?? "Null")
                                                            """,
                                                         preferredStyle: .alert)
        let okAction: UIAlertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    @objc func userLongPressedMap(_ sender: UILongPressGestureRecognizer) {
        
        let point:CGPoint = sender.location(in: mapView)
        let annotation = MKPointAnnotation()
        
        mapView.removeAnnotations(mapView.annotations)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
                
        annotation.coordinate = coordinate
        
        mapView.addAnnotation(annotation)
    }
    
}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        guard let annotation = views.first else {
            return
        }
        let location = CLLocation(latitude: annotation.annotation!.coordinate.latitude, longitude: annotation.annotation!.coordinate.longitude)
        getAddress(from: location) { (mark: CLPlacemark?, error: Error?) in
            // TODO
        }
        
    }
}

extension ViewController: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        manageAuthorizationStatus(status: manager.authorizationStatus)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let location = locations.first else {
            return
        }
        
        getAddress(from: location) { (mark: CLPlacemark?, error: Error?) in
            // do whatever you need here
        }
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = location.coordinate
        
        self.mapView.removeAnnotations(self.mapView.annotations)
        
        self.mapView.addAnnotation(annotation)
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        fatalError(error.localizedDescription)
    }
}
