//
//  ConcurrentOperation.swift
//  Astronomy
//
//  Created by Andrew R Madsen on 9/5/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import Foundation

class ConcurrentOperation: Operation {
    
    // MARK: Types
    
    enum State: String {
        case isReady, isExecuting, isFinished
    }
    
    // MARK: Properties
    
    private var _state = State.isReady
    
    private let stateQueue = DispatchQueue(label: "com.LambdaSchool.Astronomy.ConcurrentOperationStateQueue")
    var state: State {
        get {
            var result: State?
            let queue = self.stateQueue
            queue.sync {
                result = _state
            }
            return result!
        }
        
        set {
            let oldValue = state
            willChangeValue(forKey: newValue.rawValue)
            willChangeValue(forKey: oldValue.rawValue)
            
            stateQueue.sync { self._state = newValue }
            
            didChangeValue(forKey: oldValue.rawValue)
            didChangeValue(forKey: newValue.rawValue)
        }
    }
    
    // MARK: NSOperation
    
    override dynamic var isReady: Bool {
        return super.isReady && state == .isReady
    }
    
    override dynamic var isExecuting: Bool {
        return state == .isExecuting
    }
    
    override dynamic var isFinished: Bool {
        return state == .isFinished
    }
    
    override var isAsynchronous: Bool {
        return true
    }
    
}

// MARK: - FetchPhotoOperation Subclass
class FetchPhotoOperation: ConcurrentOperation {
    var photoReference: MarsPhotoReference
    var imageData: Data?
    var networkTask: URLSessionTask?
    
    init(photoReference: MarsPhotoReference) {
        self.photoReference = photoReference
    }
    
    override func start() {
        state = .isExecuting
        if isCancelled {
            state = .isFinished
            return
        }
        
        let photoURL = photoReference.imageURL
        let secureURL = photoURL.usingHTTPS
        var requestURL = URLRequest(url: secureURL!)
        requestURL.httpMethod = "GET"
        
        networkTask = URLSession.shared.dataTask(with: requestURL) { (data, _, error) in
            defer {
                self.state = .isFinished
            }
            if error != nil {
                print("Error in retrieving image data from fetchPhotoDataTask: \(error!)")
                return
            }
            guard let data = data else {
                print("Bad data returned in fetchPhotoDataTask: \(error!)")
                return
            }
            self.imageData = data
        }
        networkTask!.resume()
    }

    override func cancel() {
        networkTask?.cancel()
        super.cancel()
    }
}
