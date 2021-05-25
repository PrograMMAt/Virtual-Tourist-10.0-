//
//  DataController.swift
//  Virtual Tourist
//
//  Created by Ondrej Winter on 29/01/2021.
//

import Foundation
import CoreData

class DataController {
    let persistentContainer:NSPersistentContainer
    
    var viewContext:NSManagedObjectContext {
        return persistentContainer.viewContext 
    }
    
    init(modelName:String) {
        persistentContainer = NSPersistentContainer(name: modelName )
    }
    
    func load(completion: (() -> Void)? = nil) {
        persistentContainer.loadPersistentStores { (storeDescription, error) in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            completion?()
        }
    }
    
}
