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

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

    // Google Analytics
    let gai = GAI.sharedInstance()
    gai?.trackUncaughtExceptions = true
    gai?.dispatchInterval = 20
    gai?.tracker(withTrackingId: kOnAirLogGATrackingId)

    // AFNetworking
    AFNetworkActivityIndicatorManager.shared().isEnabled = true

    // Appearance
    UIView.appearance().tintColor = kOnAirLogTintColor

    // Setup view controllers
    let splitViewController = self.window!.rootViewController as! UISplitViewController
    let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
    navigationController.topViewController?.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
    splitViewController.delegate = self

    let masterNavigationController = splitViewController.viewControllers[0] as! UINavigationController
    let controller = masterNavigationController.topViewController as! MasterViewController
    self.masterViewController = controller
    return true
  }

  func application(_ application: UIApplication, handleOpen url: URL) -> Bool {
    let tracker = GAI.sharedInstance().defaultTracker
    let pc = url.pathComponents
    if url.host! == kOnAirLogAppHost && pc.count == 3 && pc[1] == "song" {
      let songID = pc[2] 
      if self.showSongDetail(songID) {
        tracker?.send(GAIDictionaryBuilder.createEvent(withCategory: "handleOpenURL", action: "song", label: songID, value: 1).build() as [AnyHashable: Any])
        return true
      } else {
        tracker?.send(GAIDictionaryBuilder.createEvent(withCategory: "handleOpenURL", action: "invalid", label: url.absoluteString, value: 1).build() as [AnyHashable: Any])
      }
    }
    return false
  }

  func applicationWillTerminate(_ application: UIApplication) {
    NSManagedObjectContext.mr_default().saveToPersistentStoreAndWait()
  }

  func application(_ application: UIApplication, handleWatchKitExtensionRequest userInfo: [AnyHashable: Any]?, reply: (([AnyHashable: Any]?) -> Void)!) {
    let tracker = GAI.sharedInstance().defaultTracker
    if(userInfo != nil) {
      let songID = userInfo!["songID"] as? String
      if songID != nil {
        if self.showSongDetail(songID!) {
          tracker?.send(GAIDictionaryBuilder.createEvent(withCategory: "handleWatchKitExtensionRequest", action: "song", label: songID!, value: 1).build() as [AnyHashable: Any])
        } else {
          tracker?.send(GAIDictionaryBuilder.createEvent(withCategory: "handleWatchKitExtensionRequest", action: "invalid", label: songID!, value: 1).build() as [AnyHashable: Any])
        }
      }
    }
  }

  func showSongDetail(_ songID: String) -> Bool {
    let song = Song.findFirst(byAttribute: "songID", withValue: songID)
    if song == nil {
      return false
    }
    self.masterViewController?.performSegue(withIdentifier: "showDetail", sender: song)
    return true
  }

  // MARK: - Split view

  func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController:UIViewController!, onto primaryViewController:UIViewController!) -> Bool {
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
      MagicalRecord.enableShorthandMethods()
      let dbURL = FileManager.default
        .containerURL(forSecurityApplicationGroupIdentifier: kOnAirLogDocumentContainerDomain)?
        .appendingPathComponent("OnAirLog.sqlite")
      MagicalRecord.setupCoreDataStackWithStore(at: dbURL)
      dbInitialized = true
    }
  }
  
}

