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
  var dbInitialized = false

  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

    // Google Analytics
    let gai = GAI.sharedInstance()
    gai.trackUncaughtExceptions = true
    gai.dispatchInterval = 20
    gai.trackerWithTrackingId(kOnAirLogGATrackingId)

    // AFNetworking
    AFNetworkActivityIndicatorManager.sharedManager().enabled = true

    // Appearance
    UIView.appearance().tintColor = kOnAirLogTintColor

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

  func application(application: UIApplication, handleOpenURL url: NSURL) -> Bool {
    let tracker = GAI.sharedInstance().defaultTracker
    let pc = url.pathComponents
    if url.host! == kOnAirLogAppHost && pc?.count == 3 && pc![1] as String == "song" {
      let songID = pc![2] as String
      let song = Song.findFirstByAttribute("songID", withValue: songID)
      if song == nil {
        tracker.send(GAIDictionaryBuilder.createEventWithCategory("handleOpenURL", action: "invalid", label: url.absoluteString, value: 1).build())
        return false
      }
      tracker.send(GAIDictionaryBuilder.createEventWithCategory("handleOpenURL", action: "song", label: songID, value: 1).build())
      self.masterViewController?.performSegueWithIdentifier("showDetail", sender: song)
      return true
    }
    return false
  }

  func applicationWillTerminate(application: UIApplication) {
    NSManagedObjectContext.MR_defaultContext().saveToPersistentStoreAndWait()
  }

  // MARK: - Split view

  func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController:UIViewController!, ontoPrimaryViewController primaryViewController:UIViewController!) -> Bool {
    if let secondaryAsNavController = secondaryViewController as? UINavigationController {
      if let topAsDetailController = secondaryAsNavController.topViewController as? DetailViewController {
        if topAsDetailController.song == nil {
          return true
        }
      }
    }
    return false
  }

  // MARK: - Magical Record

  func initializeDB() {
    if !dbInitialized {
      let dbURL = NSFileManager.defaultManager()
        .containerURLForSecurityApplicationGroupIdentifier(kOnAirLogDocumentContainerDomain)?
        .URLByAppendingPathComponent("OnAirLog.sqlite")
      MagicalRecord.setupCoreDataStackWithStoreAtURL(dbURL)
      dbInitialized = true
    }
  }
  
}

