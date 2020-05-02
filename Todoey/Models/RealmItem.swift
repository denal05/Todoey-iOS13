//
//  RealmItem.swift
//  Todoey-Realm
//
//  Originally created by Angela Yu on 12/12/2017.
//  Created by Denis Aleksandrov on 2020-05-02.
//  Copyright © 2020 App Brewery. All rights reserved.
//

#if Realm
import Foundation
import RealmSwift

class RealmItem: Object {
    @objc dynamic var title: String = ""
    @objc dynamic var done: Bool   = false
    @objc dynamic var dateCreated: Date?
    var parentCategory = LinkingObjects<RealmCategory>(fromType: RealmCategory.self, property: "items")
}
#endif
