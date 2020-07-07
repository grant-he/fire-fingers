//
//  Project: Fire-Fingers
//  Filename: StringProtocol.swift
//  EID: gh22593 + gwe272
//  Course: CS371L
//
//  Created by Grant He & Garrett Egan on 7/7/20.
//  Copyright © 2020 G + G. All rights reserved.
//

import Foundation

extension StringProtocol {
    subscript(offset: Int) -> Character {
        self[index(startIndex, offsetBy: offset)]
    }
}
