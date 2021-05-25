//
//  Photo.swift
//  Virtual Tourist
//
//  Created by Ondrej Winter on 25/01/2021.
//

import Foundation
import UIKit

struct Photo: Codable {
    let id: String
    let owner: String
    let secret: String
    let server: String
    let farm: Int
    let title: String
    let ispublic: Int
    let isfriend: Int
    let isfamily: Int
}
