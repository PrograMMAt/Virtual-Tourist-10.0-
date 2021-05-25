//
//  Photos.swift
//  Virtual Tourist
//
//  Created by Ondrej Winter on 25/01/2021.
//

import Foundation
import UIKit

struct Photos: Codable {
    let page: Int
    let pages: Int
    let perpage: Int
    let total: String
    let photo: [Photo]
}
