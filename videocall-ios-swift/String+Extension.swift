//
//  String+Extension.swift
//  videocall-ios-swift
//
//  Created by Lara Vertlberg on 19/12/2019.
//  Copyright © 2019 Lara Vertlberg. All rights reserved.
//

import Foundation

extension String {
    var path: String? {
        return Bundle.main.path(forResource: self, ofType: nil)
    }
}

