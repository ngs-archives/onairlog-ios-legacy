//
//  SongSpec.swift
//  OnAirLog
//
//  Created by Atsushi Nagase on 10/5/14.
//
//

import UIKit
import Nimble
import Quick

class SongSpec: QuickSpec {
  override func spec() {
    let song = Song.createEntity() as Song
    describe("test runs", {
      it("true is true", {
        expect(true).to(equal(true))
      })
    })
    describe("#updateAttributes", {
      song.updateAttributes(fixtureData("song01"))
      it("updates attributes", {
        expect(song.artist).to(equal("CORNELIUS"))
        expect(song.title).to(equal("STAR FRUITS SURF RIDER"))
        expect(song.sectionIdentifier).to(equal("2014100606"))
        expect(song.songID).to(equal(253807))
        expect(song.timeStamp).to(equal(NSDate(timeIntervalSince1970: 1412544120)))
        expect(song.isFavorited).to(beFalsy())
        expect(song.favoritedAt).to(beNil())
      })
    })
    describe("#timeStampFormatted", {
      song.timeStamp = NSDate(timeIntervalSince1970: 1412544120)
      it("returns formatted timestamp", {
        expect(song.timeStampFormatted()).to(equal("06:22"))
      })
    })
    describe("#sectionTitle", {
      song.timeStamp = NSDate(timeIntervalSince1970: 1412544120)
      it("returns formatted timestamp for section title", {
        expect(song.sectionTitle()).to(equal("2014/10/06 06:00 -"))
      })
    })
  }
}