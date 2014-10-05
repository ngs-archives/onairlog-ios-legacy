//
//  SongManager.swift
//  OnAirLog
//
//  Created by Atsushi Nagase on 10/4/14.
//
//

import CoreData

class SongManager {

  // MARK: - Core Data stack

  lazy var applicationDocumentsDirectory: NSURL = {
    return NSFileManager.defaultManager()
      .containerURLForSecurityApplicationGroupIdentifier(kOnAirLogDocumentContainerDomain)!
    }()

  lazy var managedObjectModel: NSManagedObjectModel = {
    // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
    let modelURL = NSBundle.mainBundle().URLForResource("OnAirLog", withExtension: "momd")!
    return NSManagedObjectModel(contentsOfURL: modelURL)
    }()

  lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
    var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
    let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("OnAirLog.db")
    var error: NSError? = nil
    var failureReason = "There was an error creating or loading the application's saved data."
    if coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil, error: &error) == nil {
      coordinator = nil
      let dict = NSMutableDictionary()
      dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
      dict[NSLocalizedFailureReasonErrorKey] = failureReason
      dict[NSUnderlyingErrorKey] = error
      error = NSError.errorWithDomain("org.ngsdev.iphone.OnAirlog.error", code: 9999, userInfo: dict)
      abort()
    }
    return coordinator
    }()

  lazy var managedObjectContext: NSManagedObjectContext? = {
    let coordinator = self.persistentStoreCoordinator
    if coordinator == nil {
      return nil
    }
    var managedObjectContext = NSManagedObjectContext()
    managedObjectContext.persistentStoreCoordinator = coordinator
    return managedObjectContext
    }()

  // MARK: - Core Data Saving support

  func saveContext () {
    if let moc = self.managedObjectContext {
      var error: NSError? = nil
      if moc.hasChanges && !moc.save(&error) {
        abort()
      }
    }
  }

  func fetchedResultsControllerWithPredicate(predicate: NSPredicate?,
    delegate: NSFetchedResultsControllerDelegate) -> NSFetchedResultsController {
      let fetchRequest = NSFetchRequest()
      let entity = NSEntityDescription.entityForName("Song", inManagedObjectContext: self.managedObjectContext!)
      fetchRequest.entity = entity
      fetchRequest.fetchBatchSize = 20
      if predicate != nil {
        fetchRequest.predicate = predicate!
      }
      let sortDescriptor = NSSortDescriptor(key: "timeStamp", ascending: false)
      let sortDescriptors = [sortDescriptor]
      fetchRequest.sortDescriptors = [sortDescriptor]
      let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
        managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
      aFetchedResultsController.delegate = delegate
      var error: NSError? = nil
      if !aFetchedResultsController.performFetch(&error) {
        abort()
      }
      return aFetchedResultsController
  }
  
}