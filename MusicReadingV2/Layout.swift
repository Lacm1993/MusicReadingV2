//
//  ButtonInputSubView.swift
//  MusicReading
//
//  Created by Luis Alfonso Contreras Maya on 28/10/22.
//

import SwiftUI

struct ButtonLayout : Layout{
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        var cgSize = CGSize.zero
        for i in 0..<min(4, subviews.count){
            cgSize.width += subviews[i].sizeThatFits(.unspecified).width
        }
        if subviews.count < 4{
            cgSize.height = subviews.first!.sizeThatFits(.unspecified).height
        }else{
            for i in 0...1{
                cgSize.height += subviews[i].sizeThatFits(.unspecified).height
            }
        }
        return cgSize
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let allSizes = subviews.map{ $0.sizeThatFits(.unspecified)}
        var x = bounds.minX
        var y = bounds.minY
        for subView in 0..<subviews.count{
            
            if subView == 4{
                y = bounds.midY
                if subviews.count == 5{
                    let fullSize = allSizes[subView].width
                    let halfSize = allSizes[subView].width / 2
                    x = bounds.minX + (fullSize + halfSize)
                }else if subviews.count == 6{
                    x = bounds.minX + allSizes[subView].width
                }else{
                    let halfSize = allSizes[subView].width / 2
                    x = bounds.minX + halfSize
                }
            }
            let subViewSize = allSizes[subView]
            let proposal = ProposedViewSize(width: subViewSize.width, height: subViewSize.height)
            subviews[subView]
                .place(at: CGPoint(x: x, y: y), proposal: proposal)
            x += subViewSize.width
        }
    }
}
