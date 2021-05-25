//
//  Alert.swift
//  Virtual Tourist
//
//  Created by Ondrej Winter on 25/02/2021.
//

import Foundation
import UIKit

class Alert {
    
    public static func showAlert(viewController: UIViewController, title: String, message: String, actionTitleOne:String, actionTitleTwo: String?, style: UIAlertAction.Style ) {

    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

    alert.addAction(UIAlertAction(title: actionTitleOne, style: style, handler: nil))
    
    if let actionTitleTwo = actionTitleTwo {
        alert.addAction(UIAlertAction(title: actionTitleTwo, style: style, handler: nil))
    }

    viewController.present(alert, animated: true)
        
    }
    
}
