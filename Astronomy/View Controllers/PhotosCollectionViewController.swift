//
//  PhotosCollectionViewController.swift
//  Astronomy
//
//  Created by Andrew R Madsen on 9/5/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import UIKit

class PhotosCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        client.fetchMarsRover(named: "curiosity") { (rover, error) in
            if let error = error {
                NSLog("Error fetching info for curiosity: \(error)")
                return
            }
            
            self.roverInfo = rover
        }
    }
    
    // UICollectionViewDataSource/Delegate
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoReferences.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as? ImageCollectionViewCell ?? ImageCollectionViewCell()
   
        loadImage(forCell: cell, forItemAt: indexPath)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let photoReference = photoReferences[indexPath.item]
        let imageTask = fetchDictionary[photoReference.id]
        imageTask.cancel()
        
    }
    
    // Make collection view cells fill as much available width as possible
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        var totalUsableWidth = collectionView.frame.width
        let inset = self.collectionView(collectionView, layout: collectionViewLayout, insetForSectionAt: indexPath.section)
        totalUsableWidth -= inset.left + inset.right
        
        let minWidth: CGFloat = 150.0
        let numberOfItemsInOneRow = Int(totalUsableWidth / minWidth)
        totalUsableWidth -= CGFloat(numberOfItemsInOneRow - 1) * flowLayout.minimumInteritemSpacing
        let width = totalUsableWidth / CGFloat(numberOfItemsInOneRow)
        return CGSize(width: width, height: width)
    }
    
    // Add margins to the left and right side
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 10.0, bottom: 0, right: 10.0)
    }
    
    // MARK: - Private
    
    private func loadImage(forCell cell: ImageCollectionViewCell, forItemAt indexPath: IndexPath) {
        
        let photoReference = photoReferences[indexPath.item]
        
        if cache.value(for: photoReference.id) != nil {
            guard let dataValue = cache.value(for: photoReference.id) else { return }
            let image = UIImage(data: dataValue)
            cell.imageView.image = image
            return
        }
        
        let fetchedPhotoOperation = FetchPhotoOperation(photoReference: photoReferences[indexPath.item])
        fetchedPhotoOperation.photoReference = photoReferences[indexPath.item]
        // TODO: Update the following line; it is clearly wrong
        fetchDictionary.updateValue("\(fetchedPhotoOperation.photoReference)", forKey: photoReference.id)
        print(photoReferences[indexPath.item])
        
        let photoFetchOperation = BlockOperation {
            fetchedPhotoOperation.currentImageTask()
        }
        let cacheNewImageData = BlockOperation {
            guard let imageData = fetchedPhotoOperation.imageData else { return }
            self.cache.cache(value: imageData, key: photoReference.id)
        }
        let checkCellReuse = BlockOperation {
            DispatchQueue.main.async {
                if cell == self.collectionView.cellForItem(at: indexPath) {
                    guard let dataValue = self.cache.value(for: photoReference.id) else { return }
                    let image = UIImage(data: dataValue)
                    cell.imageView.image = image
                }
            }
        }
        cacheNewImageData.addDependency(photoFetchOperation)
        checkCellReuse.addDependency(cacheNewImageData)
        
        photoFetchQueue.addOperations([photoFetchOperation, cacheNewImageData, checkCellReuse], waitUntilFinished: false)
        
        
        
        
        let photoURL = photoReference.imageURL
        let secureURL = photoURL.usingHTTPS
        var requestURL = URLRequest(url: secureURL!)
        requestURL.httpMethod = "GET"


//        URLSession.shared.dataTask(with: requestURL) { (imageData, _, error) in
//            if error != nil {
//                print("Error in retrieving image data: \(error!)")
//                return
//            }
//
//            guard let data = imageData else {
//                print("Bad data in image data result \(error!)")
//                return
//            }
//            self.cache.cache(value: data, key: photoReference.id)
//            let image = UIImage(data: data)
//            DispatchQueue.main.async {
//                if cell == self.collectionView.cellForItem(at: indexPath) {
//                cell.imageView.image = image
//                }
//            }
//        }.resume()
    }
    
    // MARK: - Properties
    
    private let client = MarsRoverClient()

    var cache = Cache<Int, Data>()
    var fetchDictionary: [Int:String] = [:]
    private var photoFetchQueue = OperationQueue()
    private var roverInfo: MarsRover? {
        didSet {
            solDescription = roverInfo?.solDescriptions[3]
        }
    }
    private var solDescription: SolDescription? {
        didSet {
            if let rover = roverInfo,
                let sol = solDescription?.sol {
                client.fetchPhotos(from: rover, onSol: sol) { (photoRefs, error) in
                    if let e = error { NSLog("Error fetching photos for \(rover.name) on sol \(sol): \(e)"); return }
                    self.photoReferences = photoRefs ?? []
                }
            }
        }
    }
    private var photoReferences = [MarsPhotoReference]() {
        didSet {
            DispatchQueue.main.async { self.collectionView?.reloadData() }
        }
    }
    
    @IBOutlet var collectionView: UICollectionView!
}
