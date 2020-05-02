//
//  ItemPList.swift
//  Todoey
//
//  Created by Denis Aleksandrov on 4/27/20.
//  Copyright © 2020 App Brewery. All rights reserved.
//

import Foundation

// #TODO Refactor class: rename from ItemPList into PListItem
class ItemPList: Codable {
    var title: String = ""
    var done:  Bool   = false
}
