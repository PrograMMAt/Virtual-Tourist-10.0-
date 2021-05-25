//
//  CollectionViewCell.swift
//  Virtual Tourist
//
//  Created by Ondrej Winter on 04/02/2021.
//

import Foundation
import UIKit

class CollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func prepareForReuse() {
            super.prepareForReuse()
            // Set the cell's imageView's image to nil
            self.imageView.image = nil
        }
    
}
