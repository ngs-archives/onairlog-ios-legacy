//
//  BaseTableViewController.swift
//  OnAirLog
//
//  Created by Atsushi Nagase on 10/19/14.
//
//

import UIKit
import CoreData
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


open class BaseTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
  var detailViewController: DetailViewController? = nil
  open func predicate() -> NSPredicate? {
    return nil
  }
  
  override open func awakeFromNib() {
    super.awakeFromNib()
    if UIDevice.current.userInterfaceIdiom == .pad {
      self.clearsSelectionOnViewWillAppear = false
      self.preferredContentSize = CGSize(width: 320.0, height: 600.0)
    }
  }

  open func updatePredicate() {
    self.fetchedResultsController.fetchRequest.predicate = predicate()
    self.fetchedResultsController.performFetch(nil)
    self.tableView.reloadData()
  }

  // MARK: - Table View

  override open func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    let sections = self.fetchedResultsController.sections
    if sections?.count < section + 1 {
      return nil
    }
    let s = sections![section] as! NSFetchedResultsSectionInfo
    let song = s.objects.first as! Song
    return song.sectionTitle()
  }

  override open func numberOfSections(in tableView: UITableView) -> Int {
    return self.fetchedResultsController.sections?.count ?? 0
  }

  override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let sectionInfo = self.fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
    return sectionInfo.numberOfObjects
  }

  override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! SongTableViewCell
    self.configureCell(cell, atIndexPath: indexPath)
    return cell
  }

  override open func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return false
  }

  func configureCell(_ cell: SongTableViewCell, atIndexPath indexPath: IndexPath) {
    let object = self.fetchedResultsController.object(at: indexPath) as! Song
    cell.configureSong(object)
  }

  // MARK: - Fetched results controller

  var fetchedResultsController: NSFetchedResultsController {
    if (_fetchedResultsController == nil) {
      var appDelegate = UIApplication.shared.delegate as! AppDelegate
      appDelegate.initializeDB()
      _fetchedResultsController = Song.fetchAllSorted(by: "songID", ascending: false, with: predicate(), groupBy: "sectionIdentifier", delegate: self, in: NSManagedObjectContext.mr_default())
      }
      return _fetchedResultsController!
  }
  var _fetchedResultsController: NSFetchedResultsController? = nil

  open func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    self.tableView.beginUpdates()
  }

  open func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
    switch type {
    case .insert:
      self.tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
    case .delete:
      self.tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
    default:
      return
    }
  }

  open func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?,
    for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
    switch type {
    case .insert:
      tableView.insertRows(at: [newIndexPath!], with: UITableViewRowAnimation.fade)
    case .delete:
      tableView.deleteRows(at: [indexPath!], with: UITableViewRowAnimation.fade)
    case .update:
      let cell = tableView.cellForRow(at: newIndexPath!)
      if cell != nil {
        self.configureCell(cell! as! SongTableViewCell, atIndexPath: newIndexPath!)
      }
    case .move:
      tableView.deleteRows(at: [indexPath!], with: UITableViewRowAnimation.fade)
      tableView.insertRows(at: [newIndexPath!], with: UITableViewRowAnimation.fade)
    default:
      return
    }
  }

  open func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    self.tableView.endUpdates()
  }

}
