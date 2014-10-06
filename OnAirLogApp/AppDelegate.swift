//
//  AppDelegate.swift
//  OnAirLog813
//
//  Created by Atsushi Nagase on 10/2/14.
//
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

  var window: UIWindow?
  var masterViewController: MasterViewController?

  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    // Magical Record
    let dbURL = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier(kOnAirLogDocumentContainerDomain)?.URLByAppendingPathComponent("OnAirLog.sqlite")
    MagicalRecord.setupCoreDataStackWithiCloudContainer(nil, contentNameKey: "OnAirLog", localStoreAtURL: dbURL, cloudStorePathComponent: "OnAirLog")
    NSNotificationCenter.defaultCenter().addObserverForName(kMagicalRecordDidMergeChangesFromiCloudNotification, object: nil, queue: nil) { (note: NSNotification!) -> Void in
      let inserted = note.userInfo![NSInsertedObjectsKey] as NSSet?
      let updated = note.userInfo![NSUpdatedObjectsKey] as NSSet?
      MagicalRecord.saveUsingCurrentThreadContextWithBlock({ (context: NSManagedObjectContext!) -> Void in
        if inserted?.count > 0 {
          Song.deleteDuplicatesWithSet(inserted, inContext: context)
        }
        if updated?.count > 0 {
          Song.deleteDuplicatesWithSet(updated, inContext: context)
        }
        }, completion: { (success: Bool, error: NSError!) -> Void in })
    }
    // Google Analytics
    let gai = GAI.sharedInstance()
    gai.trackUncaughtExceptions = true
    gai.dispatchInterval = 20
    gai.trackerWithTrackingId(kOnAirLogGATrackingId)

    // AFNetworking
    AFNetworkActivityIndicatorManager.sharedManager().enabled = true

    // Setup view controllers
    let splitViewController = self.window!.rootViewController as UISplitViewController
    let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as UINavigationController
    navigationController.topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem()
    splitViewController.delegate = self

    let masterNavigationController = splitViewController.viewControllers[0] as UINavigationController
    let controller = masterNavigationController.topViewController as MasterViewController
    self.masterViewController = controller
    return true
  }

  func applicationWillTerminate(application: UIApplication) {
    NSManagedObjectContext.contextForCurrentThread().saveToPersistentStoreAndWait()
  }

  // MARK: - Split view

  func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController:UIViewController!, ontoPrimaryViewController primaryViewController:UIViewController!) -> Bool {
    if let secondaryAsNavController = secondaryViewController as? UINavigationController {
      if let topAsDetailController = secondaryAsNavController.topViewController as? DetailViewController {
        if topAsDetailController.detailItem == nil {
          return true
        }
      }
    }
    return false
  }
  
}

