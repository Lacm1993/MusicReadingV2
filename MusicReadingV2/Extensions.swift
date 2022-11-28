//
//  Extensions.swift
//  MusicReadingV2
//
//  Created by Luis Alfonso Contreras Maya on 27/11/22.
//

import Foundation

extension Collection where Iterator.Element == String{
    func noteOrderSorting()-> [String]{
        let order = ["C", "D", "E", "F", "G", "A", "B"]
        return self.sorted{first, second in
            order.firstIndex(of: first)! < order.firstIndex(of: second)!
        }
    }
}
