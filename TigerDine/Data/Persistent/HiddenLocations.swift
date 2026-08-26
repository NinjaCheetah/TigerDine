//
//  HiddenLocations.swift
//  TigerDine
//
//  Created by Campbell Bagley on 8/25/26.
//

import SwiftUI

@Observable
class HiddenLocations {
    private var hiddenLocations: Set<Int>
    private let key = "Hidden"

    init() {
        let favorites = UserDefaults.standard.array(forKey: key) as? [Int] ?? [Int]()
        hiddenLocations = Set(favorites)
    }

    func contains(_ location: DiningLocation) -> Bool {
        hiddenLocations.contains(location.id)
    }

    func add(_ location: DiningLocation) {
        hiddenLocations.insert(location.id)
        save()
    }

    func remove(_ location: DiningLocation) {
        hiddenLocations.remove(location.id)
        save()
    }

    func save() {
        let hidden = Array(hiddenLocations)
        UserDefaults.standard.set(hidden, forKey: key)
    }
}
