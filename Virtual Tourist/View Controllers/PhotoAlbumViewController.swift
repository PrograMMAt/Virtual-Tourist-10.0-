//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Ondrej Winter on 22/01/2021.
//

import Foundation
import UIKit
import MapKit
import CoreData


class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // MARK: Properties
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var subView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var newCollectionButton: UIButton!
    var coordinate: CLLocationCoordinate2D!
    var location: Location!
    var fetchedLocation: Location?
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<CorePhoto>!
    var urlsArray:Array<String> = []
    var imageCache = NSCache<NSString, UIImage>()
    var usedArrays:Array<String> = []
    
    enum imagesFrom {
        case url
        case coreData
    }
    var imagesTakenFrom: imagesFrom = .coreData

    // set up fetchedResultsController
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<CorePhoto> = CorePhoto.fetchRequest()
        let predicate = NSPredicate(format: "location == %@", location)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "\(location.id)")
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    // MARK: Body
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setDownloading(false)
        setupFetchedResultsController()
                
        // center the mapView around chosen location from TravelLocationsMapViewController
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        mapView.region = MKCoordinateRegion(center: coordinate, span: span)
        
        collectionView.delegate = self
        
        
        let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        addAnnotationToMapView(locationCoordinate: coordinate, dataController: dataController, mapView: mapView)
        
        
        // get list of json objects "photos" from Flickr for desired location and in handling - create array of urls (so that you can download images from there) and reload the collection data source
        if fetchedResultsController.sections?[0].numberOfObjects == 0 {
            setDownloading(true)
            VTClient.getPhotos(lat: coordinate.latitude, lon: coordinate.longitude, numberOfPhotos: 21, completion: handleGetPhotosResponse(jsonObject:error:))
        }
    }
    
    func handleGetPhotosResponse(jsonObject: PhotosResults?, error: Error?) {
        // create array of urls (so that you can download images from there) and reload the collection data source
        if let error = error {
            Alert.showAlert(viewController: self, title: "Alert", message: "We couldn't download the images. Please try again.", actionTitleOne: "OK", actionTitleTwo: nil, style: .cancel)
        }

        
        if let unwrappedPhotos = jsonObject?.photos?.photo {
            if unwrappedPhotos.count != 0 {
                
                self.urlsArray = []
                self.imageCache = NSCache<NSString, UIImage>()
                self.usedArrays = []
                
                var counter = -1
                for _ in unwrappedPhotos{
                    counter += 1
                    let urlString = "https://live.staticflickr.com/\(unwrappedPhotos[counter].server)/\(unwrappedPhotos[counter].id)_\(unwrappedPhotos[counter].secret)_q.jpg"
                    self.urlsArray.append(urlString)
                }
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
                
            } else {
                let label = UILabel()
                label.frame.size = CGSize(width: self.view.frame.width,height: 80)
                label.frame.origin.y = label.frame.origin.y + ((self.subView.frame.height / 2) - label.frame.height / 2)
                //label.frame.origin.y = self.subView.frame.height - label.frame.height
                label.text = "There are no images for this locaton..."
                label.textColor = .black
                label.frame.size = CGSize(width: label.intrinsicContentSize.width, height: 80)
                label.frame.origin.x = (self.subView.frame.width - label.intrinsicContentSize.width) / 2
                self.subView.addSubview(label)
            }
        }
        
    }
    
    // if it is downloading list of images disable button and show activity indicator
    func setDownloading(_ downloading: Bool) {
        if downloading {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
        newCollectionButton.isEnabled = !downloading
    }
    
    
    @IBAction func newCollectionButtonTapped(_ sender: Any) {
        
        setDownloading(true)
        
        // reset variables
        self.urlsArray = []
        self.imageCache = NSCache<NSString, UIImage>()
        self.usedArrays = []

        // delete Core Photos from Core Data
        let objects = fetchedResultsController.fetchedObjects
        if let objects = objects {
            for object in objects {
                dataController.viewContext.delete(object)
                try? dataController.viewContext.save()
            }
            
            // download the newest collection of images for the location
            VTClient.getPhotos(lat: coordinate.latitude, lon: coordinate.longitude, numberOfPhotos: 21, completion: handleGetPhotosResponse(jsonObject:error:))
        }
    }
    
        
        
        
    // MARK: Collection Views
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
    // if there are images in FRC, use them as a data source, else data source will downloaded urls from Flickr and then you'll make
       let numberOfObjects = self.fetchedResultsController.sections![0].numberOfObjects
            if numberOfObjects > 0 {
                self.imagesTakenFrom = .coreData
                return numberOfObjects
            } else {
                self.imagesTakenFrom = .url
            }
         return urlsArray.count
        //return fetchedResultController.sections?[0].numberOfObjects ?? self.urlsArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        //create a reusable cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCell", for: indexPath) as! CollectionViewCell
        
        switch imagesTakenFrom {
        case .url:
        
            let urlForPhoto = self.urlsArray[indexPath.row]
            
            // if you have already cached an image for this indexPath, use cached image for performance reasons,
            // else download an image for this cell
            if let imageFromCache = imageCache.object(forKey: urlForPhoto as NSString) {
                cell.imageView.image = imageFromCache
                return cell
            } else {
                    // download the image and save it to cache
                    downloadImage(urlString: urlForPhoto) { (imageData) in
                        guard let imageData = imageData else {
                            return
                        }
                        let image = UIImage(data: imageData)
                        self.imageCache.setObject(image!, forKey: urlForPhoto as NSString)
                        cell.imageView.image = image
                        cell.setNeedsLayout()
                        
                        // if the image for the url has been already saved to core data return, else save the url for the image
                        if self.usedArrays.contains(urlForPhoto) {
                            return
                        } else {
                            self.usedArrays.append(urlForPhoto)
                            let photo = CorePhoto(context: self.dataController.viewContext)
                            photo.img = imageData
                            photo.creationDate = Date()
                            photo.location = self.location
                            do {
                                try self.dataController.viewContext.save()
                            } catch {
                            }

                    }
                }
            }
            
            //if all newest images were downloaded and loaded into the viewCollection, enable NewCollection button
            if indexPath.row == urlsArray.count - 1 {
                setDownloading(false)
            }
            
            return cell
        
            
        // load images from Core Data
        case .coreData:
            let aPhoto = fetchedResultsController.object(at: indexPath)
            if let imgData = aPhoto.img {
                cell.imageView.image = UIImage(data: imgData)
                return cell
            }
        }
        return cell
    }
    
    
    func downloadImage(urlString: String, completion: @escaping(_ image: Data?) -> Void){
        
        DispatchQueue.global(qos: .userInitiated).async { () -> Void in
            
            if let url = URL(string: urlString), let imgData = try? Data(contentsOf: url) {

                DispatchQueue.main.async {
                    completion(imgData)
                }
               
            } else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let width = view.frame.size.width
        return CGSize(width: width * 0.32, height: width * 0.32)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        let width = view.frame.size.width
        let interimSpacing = width * 0.02
        return interimSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout
        collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        let width = view.frame.size.width
        let lineSpacing = width * 0.02

        return lineSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        deletePhoto(indexPath: indexPath)
    }
    
    func deletePhoto(indexPath: IndexPath) {
        let aPhotoToDelete = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(aPhotoToDelete)
        try? dataController.viewContext.save()
    }

}

// MARK: NSFetchedResultsController

extension PhotoAlbumViewController:NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .delete:
            collectionView.deleteItems(at: [indexPath!])
            break
        case .insert:
            break
        case .move:
            break
        case .update:
            break
        }
        
    }
    
    
    
    
    
}


