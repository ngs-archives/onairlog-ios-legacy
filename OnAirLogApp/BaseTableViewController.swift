//
//  BaseTableViewController.swift
//  OnAirLog
//
//  Created by Atsushi Nagase on 10/19/14.
//
//

import UIKit
import CoreData

public class BaseTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
  var detailViewController: DetailViewController? = nil
  public func predicate() -> NSPredicate? {
    return nil
  }
  
  override public func awakeFromNib() {
    super.awakeFromNib()
    if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
      self.clearsSelectionOnViewWillAppear = false
      self.preferredContentSize = CGSize(width: 320.0, height: 600.0)
    }
  }

  public func updatePredicate() {
    self.fetchedResultsController.fetchRequest.predicate = predicate()
    self.fetchedResultsController.performFetch(nil)
    self.tableView.reloadData()
  }

  // MARK: - Table View

  override public func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    let sections = self.fetchedResultsController.sections
    if sections?.count < section + 1 {
      return nil
    }
    let s = sections![section] as! NSFetchedResultsSectionInfo
    let song = s.objects.first as! Song
    return song.sectionTitle()
  }

  override public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return self.fetchedResultsController.sections?.count ?? 0
  }

  override public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let sectionInfo = self.fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
    return sectionInfo.numberOfObjects
  }

  override public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! SongTableViewCell
    self.configureCell(cell, atIndexPath: indexPath)
    return cell
  }

  override public func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    return false
  }

  func configureCell(cell: SongTableViewCell, atIndexPath indexPath: NSIndexPath) {
    let object = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Song
    cell.configureSong(object)
  }

  // MARK: - Fetched results controller

  var fetchedResultsController: NSFetchedResultsController {
    if (_fetchedResultsController == nil) {
      var appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
      appDelegate.initializeDB()
      _fetchedResultsController = Song.fetchAllSortedBy("songID", ascending: false, withPredicate: predicate(), groupBy: "sectionIdentifier", delegate: self, inContext: NSManagedObjectContext.MR_defaultContext())
      }
      return _fetchedResultsController!
  }
  var _fetchedResultsController: NSFetchedResultsController? = nil

  public func controllerWillChangeContent(controller: NSFetchedResultsController) {
    self.tableView.beginUpdates()
  }

  public func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
    switch type {
    case .Insert:
      self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
    case .Delete:
      self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
    default:
      return
    }
  }

  public func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?,
    forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
    switch type {
    case .Insert:
      tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
    case .Delete:
      tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
    case .Update:
      let cell = tableView.cellForRowAtIndexPath(newIndexPath!)
      if cell != nil {
        self.configureCell(cell! as! SongTableViewCell, atIndexPath: newIndexPath!)
      }
    case .Move:
      tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
      tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
    default:
      return
    }
  }

  public func controllerDidChangeContent(controller: NSFetchedResultsController) {
    self.tableView.endUpdates()
  }

}
