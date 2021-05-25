//
//  File.swift
//  Virtual Tourist
//
//  Created by Ondrej Winter on 03/02/2021.
//

import Foundation
import UIKit
import MapKit

extension UIViewController {
    
    
    //adds new annotation to map view and location to persistent store
    func addAnnotationAndLocation(coordinate: CLLocationCoordinate2D, dataController: DataController, mapView: MKMapView) {
        addAnnotationToMapView(locationCoordinate: coordinate, dataController: dataController, mapView: mapView)
        addLocationToPS(coordinate: coordinate, dataController: dataController)
    }
    
    
    // helper functions
    
    func addAnnotationToMapView(locationCoordinate: CLLocationCoordinate2D, dataController: DataController, mapView: MKMapView) {
        
        var annotations = [MKPointAnnotation]()
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = locationCoordinate
        annotations.append(annotation)
        
        DispatchQueue.main.async {
            mapView.addAnnotations(annotations)
        }
    }
    
    func addLocationToPS(coordinate: CLLocationCoordinate2D, dataController: DataController) {
        let location = Location(context: dataController.viewContext)
        location.creationDate = Date()
        location.latitude = coordinate.latitude
        location.longitude = coordinate.longitude
        try? dataController.viewContext.save()
    }

    
}
