//
//  Pointer.swift
//  music_game_demo
//
//  Created by Do Xuan Thanh on 9/9/19.
//  Copyright © 2019 monstar-lab. All rights reserved.
//

import Foundation
import UIKit
class Pointer: UIImageView{
    var position: CGFloat?
    override init(frame: CGRect) {
        super.init(frame: frame)
        let imageName = "pointer.png"
        self.image = UIImage(named: imageName)
        self.frame = frame
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
