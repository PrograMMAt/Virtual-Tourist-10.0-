//
//  TravelLocationsMapViewController.swift
//  Virtual Tourist
//
//  Created by Ondrej Winter on 19/01/2021.
//
import Foundation
import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    // MARK: Properties
    
    @IBOutlet weak var mapView: MKMapView!
    var dataController: DataController!
    var fetchedResultsController:NSFetchedResultsController<Location>!
    var secondFetchedResultsController:NSFetchedResultsController<Location>!
    var latitude: Double?
    var longitude: Double?
    let udKeyHasLaunchedBefore: String = "HasLaunchedBefore"
    let udKeyLatitude: String = "Latitude"
    let udKeyLongitude: String = "Longitude"
    let udKeyLatitudeDelta: String = "LatitudeDelta"
    let udKeyLongitudeDelta: String = "LongitudeDelta"
    let udValueLatitude = UserDefaults.standard.value(forKey: "Latitude")
    let udValueLongitude = UserDefaults.standard.value(forKey: "Longitude")
    let udValueLatitudeDelta = UserDefaults.standard.value(forKey: "LatitudeDelta")
    let udValueLongitudeDelta = UserDefaults.standard.value(forKey: "LongitudeDelta")
// ud = UserDefaults

    
    //set up fetchedResultsController for all locations
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Location> = Location.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "location")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    //set up fetchedResultsController for tapped location
    fileprivate func setupSecondFetchedResultsController(latitude: Double) {
        let fetchRequest:NSFetchRequest<Location> = Location.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true)
        let predicate = NSPredicate(format: "latitude = \(latitude)")
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        secondFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "location-one")
        do {
            try secondFetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
        
    }
    
    
        
    override func viewDidLoad() {
        super.viewDidLoad()
        setupFetchedResultsController()
        mapView.delegate = self
        
        // if the app has launched before show the last position of a map
        if UserDefaults.standard.bool(forKey: udKeyHasLaunchedBefore) {
            if let udlatitude = self.udValueLatitude as? Double, let udlongitude = self.udValueLongitude as? Double, let udLatitudeDelta = self.udValueLatitudeDelta as? CLLocationDegrees, let udLongitudeDelta = self.udValueLongitudeDelta as? CLLocationDegrees {
                let coordinate = CLLocationCoordinate2D(latitude: udlatitude, longitude: udlongitude)
                let span = MKCoordinateSpan(latitudeDelta: udLatitudeDelta, longitudeDelta: udLongitudeDelta)
                mapView.region = MKCoordinateRegion(center: coordinate, span: span)
            }
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        setupFetchedResultsController()
        addAnotationsFromPS()
        
        // delete all records from CoreData
        /*
        let fetchRequesto: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Location")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequesto)

        do {
            try dataController.persistentContainer.persistentStoreCoordinator.execute(deleteRequest, with: dataController.viewContext)
        } catch let error as NSError {
            // TODO: handle the error
        }
         */
    }
    
    
    // on long press - create an annotation for mapview and location for CoreData
    @IBAction func revealRegionDetailsWithLongPressOnMap(sender: UILongPressGestureRecognizer) {
        if sender.state != UIGestureRecognizer.State.began { return }
        let touchLocation = sender.location(in: mapView)
        let locationCoordinate = mapView.convert(touchLocation, toCoordinateFrom: mapView)
        
        addAnnotationAndLocation(coordinate: locationCoordinate, dataController: dataController, mapView: mapView)
    }
    

    func addAnotationsFromPS() {
        if mapView.annotations.count == 0 {
            var annotations = [MKPointAnnotation]()
            
            if let objects = fetchedResultsController.fetchedObjects {
                for location in objects {

                    let lat = Double(location.latitude)
                    let long = Double(location.longitude)
                    let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = coordinate
                    annotations.append(annotation)
                }
            }
            DispatchQueue.main.async {
                self.mapView.addAnnotations(annotations)
            }
        }
    }
    
    
    
    // MARK: - MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {

        let controller:PhotoAlbumViewController
        controller = storyboard?.instantiateViewController(identifier: "PhotoAlbumViewController") as! PhotoAlbumViewController
        
        if let coordinate = view.annotation?.coordinate {
            controller.coordinate = coordinate
            setupSecondFetchedResultsController(latitude: coordinate.latitude)
            mapView.deselectAnnotation(view.annotation, animated: true)
            if let fetchedObjectsFromSecondController = secondFetchedResultsController.fetchedObjects {
                controller.location = fetchedObjectsFromSecondController[0]
            }
            controller.dataController = dataController
            self.navigationController?.pushViewController(controller, animated: true)

        }
        
        
    }
    
    // if mapview's position of a map was changed, save the position to UserDefaults
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        savePositionOfAMapToUserDefaults(mapView: mapView)
    }
    
    // helper function
    func savePositionOfAMapToUserDefaults(mapView: MKMapView) {
        let region = mapView.region
        UserDefaults.standard.setValue(region.center.latitude, forKey: udKeyLatitude)
        UserDefaults.standard.setValue(region.center.longitude, forKey: udKeyLongitude)
        UserDefaults.standard.setValue(region.span.latitudeDelta, forKey: udKeyLatitudeDelta)
        UserDefaults.standard.setValue(region.span.longitudeDelta, forKey: udKeyLongitudeDelta)
    }
    
        


}
