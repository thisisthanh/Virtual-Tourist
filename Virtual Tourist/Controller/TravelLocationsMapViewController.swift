//
//  TravelLocationsMapViewController.swift
//  Virtual Tourist
//
//  Created by Thành Nguyễn on 8/5/24.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController {
    
    @IBOutlet var mapView: MKMapView!
    
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupFetchedResultsController()
        loadMapAnnotations()
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressedInMapView(sender:)))
        mapView.delegate = self
        mapView.addGestureRecognizer(longPressRecognizer)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        setupFetchedResultsController()
        loadMapAnnotations()
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        fetchedResultsController = nil
    }
    
    func setupView() {
        let mapRadius = CLLocationDistance(exactly: MKMapRect.world.size.height)!
        mapView.addOverlay(MKCircle(center: mapView.centerCoordinate, radius: mapRadius))
    }
    
    
    private func loadMapAnnotations() {
        if let pins = fetchedResultsController.fetchedObjects {
            mapView.addAnnotations(pins)
        }
    }
    
    private func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pins")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Error fetch data from core data \(error.localizedDescription)")
        }
    }
    
    @objc func longPressedInMapView(sender: UILongPressGestureRecognizer) {
        if sender.state != .began {
            return
        }
        
        let point = sender.location(in: mapView)
        let coordinates = mapView.convert(point, toCoordinateFrom: mapView)
        addPin(longitude: coordinates.longitude, latitude: coordinates.latitude)
    }

    func addPin(longitude: Double, latitude: Double) {
        let pin = Pin(context: dataController.viewContext)
        pin.longitude = longitude
        pin.latitude = latitude
        pin.creationDate = Date()
        try? dataController.viewContext.save()
    }
}

// MARK: - MKMapView Delegate

extension TravelLocationsMapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay.isKind(of: MKCircle.self) {
            let view = MKCircleRenderer(overlay: overlay)
            view.fillColor = UIColor.black.withAlphaComponent(0.2)
            return view
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        mapView.deselectAnnotation(view.annotation! , animated: true)
        let pin: Pin = view.annotation as! Pin
        let photoAlbumVC = storyboard?.instantiateViewController(withIdentifier: "PhotoAlbumViewController") as! PhotoAlbumViewController;
        
        photoAlbumVC.pin = pin
        photoAlbumVC.dataController = dataController
        
        navigationController?.pushViewController(photoAlbumVC, animated: true)
    }
}

// MARK: - NSFetchedResultsControlle rDelegate

extension TravelLocationsMapViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard let pin = anObject as? Pin else {
            preconditionFailure("Pin Error")
        }
        switch type {
        case .insert:
            mapView.addAnnotation(pin)
            break
        default: ()
        }
    }
}
