//
//  SongTests.swift
//  OnAirLog
//
//  Created by Atsushi Nagase on 10/11/14.
//
//

import UIKit
import XCTest

class SongTests: XCTestCase {

  let FAKE_TIME = 1412544120.0

  var _song: Song? = nil
  var song: Song {
    if _song == nil {
      _song = Song.createEntity() as Song
      }
      return _song!
  }

  override func tearDown() {
    _song = nil
  }

  func testUpdateAttributes() {
    song.updateAttributes(fixtureData("song01"))
    XCTAssert(song.artist == "CORNELIUS")
    XCTAssert(song.title == "STAR FRUITS SURF RIDER")
    XCTAssert(song.sectionIdentifier == "2014100606")
    XCTAssert(song.songID == 253807)
    XCTAssert(song.timeStamp == NSDate(timeIntervalSince1970: FAKE_TIME))
    XCTAssertFalse(song.isFavorited)
    XCTAssertNil(song.favoritedAt)
  }

  func testTimeStampFormatted() {
    song.timeStamp = NSDate(timeIntervalSince1970: FAKE_TIME)
    XCTAssert(song.timeFormatted() == "06:22")
  }

  func testSectionTitle() {
    song.timeStamp = NSDate(timeIntervalSince1970: FAKE_TIME)
    XCTAssert(song.sectionTitle() == "2014/10/06 06:00 -")
  }

}
