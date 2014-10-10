//
//  TestHelper.swift
//  OnAirLog
//
//  Created by Atsushi Nagase on 10/6/14.
//
//

import Foundation

func testBundle() -> NSBundle {
  return NSBundle(forClass: SongTests.self)
}

func fixturePath(name: String) -> String? {
  return testBundle().pathForResource(name, ofType: "json")
}

func fixtureData(name: String) -> NSDictionary {
  var error: NSError?
  var filePath = fixturePath(name)
  if filePath == nil { return NSDictionary() }
  var data: NSData? = NSData(contentsOfFile: filePath!, options: NSDataReadingOptions.DataReadingMappedAlways, error: &error)
  if data == nil { return NSDictionary() }
  let jsonData: AnyObject? = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments, error: &error)
  var dict: NSDictionary? = jsonData as? NSDictionary
  if dict == nil { return NSDictionary() }
  return dict!
}