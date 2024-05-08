//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Thành Nguyễn on 8/5/24.
//

import UIKit
import CoreData
import MapKit
import Kingfisher

class PhotoAlbumViewController: UIViewController {
    
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    var pin: Pin!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let photosPerRow: CGFloat = 3
    let insets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    let reuseId = "PhotoAlbumCell"
    
    @IBOutlet weak var newCollectionButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        setupFetchedResultsController()
        
        setButtonState(false)
        activityIndicator.hidesWhenStopped = true
        if (fetchedResultsController.sections?[0].numberOfObjects ?? 0 == 0) {
            fetchPhotosFromAPI()
        } else {
            setButtonState(true)
        }
        
        mapView.addAnnotation(pin)
        mapView.showAnnotations([pin], animated: true)
        mapView.isUserInteractionEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: true)
        super.viewWillAppear(animated)
        setupFetchedResultsController()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    private func setButtonState(_ state: Bool) {
        newCollectionButton.isEnabled = state
    }
    
    private func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.predicate = predicate
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "\(pin!.creationDate!)-photos")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Error fetch data from core data \(error.localizedDescription)")
        }
    }
    
    private func fetchPhotosFromAPI() {
        setButtonState(false)
        activityIndicator.startAnimating()
        VirtualTouristClient.fetchPhotos(lat: pin.latitude, lon: pin.longitude) { (error, photosURL) in

            switch error {
            case .notConnected:
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "Sorry", message:
                                                                "Please connect a internet connection", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Dismiss", style: .default))
                    self.present(alertController, animated: true, completion: nil)
                    self.activityIndicator.stopAnimating()
                }
                break
            case .connected:
                for photoURL in photosURL! {
                    self.addPhoto(url: photoURL)
                }
                self.activityIndicator.stopAnimating()
                break
            case .other:
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "Sorry..", message:
                                                                "Something bad occured. Please, try again.", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Dismiss", style: .default))
                    self.present(alertController, animated: true, completion: nil)
                    self.activityIndicator.stopAnimating()
                }
                break
            }
            
            DispatchQueue.main.async {
                self.setButtonState(true)
                self.collectionView.reloadData()
            }
        }
    }
    
    func addPhoto(url: String) {
        let photo = Photo(context: dataController.viewContext)
        photo.creationDate = Date()
        photo.url = url
        photo.pin = pin
        try? dataController.viewContext.save()
    }
    
    func deletePhoto(_ photo: Photo) {
        dataController.viewContext.delete(photo)
        do {
            try dataController.viewContext.save()
        } catch {
            print("Error")
        }
        
    }
    
    @IBAction func getNewCollection() {
        if let photos = fetchedResultsController.fetchedObjects {
            for photoToDelete in photos {
                dataController.viewContext.delete(photoToDelete)
                do {
                    try dataController.viewContext.save()
                } catch {
                    print("Error")
                }
            }
        }
        fetchPhotosFromAPI()
    }
    
}

// MARK: - NSFetchedResultsController Delegate
extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            collectionView.insertItems(at: [newIndexPath!])
            break
        case .delete:
            collectionView.deleteItems(at: [indexPath!])
            break
        default: ()
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension PhotoAlbumViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding = insets.right * (photosPerRow + 1)
        let availableWidth = view.frame.width - padding
        let widthOfItem = availableWidth / photosPerRow
        
        return CGSize(width: widthOfItem, height: widthOfItem)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return insets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return insets.right
    }
}

// MARK: - UICollectionView Data Source

extension PhotoAlbumViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (fetchedResultsController.sections?[section].numberOfObjects ?? 0 == 0) {
//            collectionView.setEmptyPhotoMessage("TRY TO GET NEW COLLECTION AGAIN!")
        } else {
            collectionView.backgroundView = nil
        }
        
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let photo = fetchedResultsController.object(at: indexPath)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseId, for: indexPath) as! PhotoAlbumCell
        
        if let data = photo.image {
            cell.photoImageView.image = UIImage(data: data)
        } else if let photoURL = photo.url {
            guard let url = URL(string: photoURL) else {
                return cell
            }
            cell.photoImageView.kf.setImage(with: url, placeholder: UIImage(named: "Placeholder"), options: nil, progressBlock: nil) { (img, err, cacheType, url) in
                if ((err) != nil) {
                    
                } else {
                    photo.image = img?.pngData()
                    try? self.dataController.viewContext.save()
                }
            }
        }
        
        return cell
    }
}
// MARK: - UICollectionView Delegate
extension PhotoAlbumViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photoToDelete = fetchedResultsController.object(at: indexPath)
        deletePhoto(photoToDelete)
    }
}

