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

class SongQuickSpec: QuickSpec {
  override func spec() {
    describe("test runs", { () -> () in
      it("true is true", { () -> () in
        expect(true).to(equal(true))
      })
    })
  }
}