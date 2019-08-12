//
//  Task.swift
//  MusicPickerKit
//
//  Created by Jon Andersen on 8/11/19.
//  Copyright © 2019 Andersen. All rights reserved.
//

import Foundation

public typealias CompletionHandler<T> = (T?, Error?) -> ()

public class Task<T> {
    internal var isCancelled: Bool = false
    internal var onCancel: (() -> ())? = nil
    private var completionHandler: CompletionHandler<T>!
    
    public init(completionHandler: @escaping CompletionHandler<T>) {
        self.completionHandler = { [weak self] url, error in
            guard let self = self else { return }
            if(self.isCancelled){
                return
            }
            DispatchQueue.main.async {
                completionHandler(url, error)
            }
        }
    }
    
    public func complete(with result: T){
        completionHandler(result, nil)
    }
    
    public func fail(with error: Error){
        completionHandler(nil, error)
    }
    
    public func cancel() {
        isCancelled = true
        onCancel?()
    }
}
