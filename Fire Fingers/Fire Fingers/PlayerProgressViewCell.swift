//
//  Project: Fire-Fingers
//  Filename: PlayerProgressViewCell.swift
//  EID: gh22593 + gwe272
//  Course: CS371L
//
//  Created by Grant He & Garrett Egan on 7/7/20.
//  Copyright © 2020 G + G. All rights reserved.
//

import UIKit

class PlayerProgressViewCell: UITableViewCell {
    
    let width: CGFloat = 190
    
    @IBOutlet weak var playerNameLabel: UILabel!
    @IBOutlet weak var playerProgress: UIProgressView!
    @IBOutlet weak var playerProgressImage: UIImageView!
    @IBOutlet weak var playerWPMLabel: UILabel!
    
}
