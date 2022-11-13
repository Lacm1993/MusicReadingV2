//
//  ViewModifiers.swift
//  MusicReadingV2
//
//  Created by Luis Alfonso Contreras Maya on 12/11/22.
//

import Foundation
import SwiftUI

struct ThemeModifier: ViewModifier{
    let theme: Theme
    func body(content: Content) -> some View {
        let color = theme == .Dark ?
        Color(red: 0.004, green: 0.047, blue: 0.118, opacity: 1.000) :
        Color(red: 0.290, green: 0.427, blue: 0.533, opacity: 1.000)
        return ZStack(alignment: .center){
                color
                    .ignoresSafeArea(.all)
                content
               }
    }
}
extension View{
    func theme(preferedScheme theme: Theme)-> some View{
        self
            .modifier(ThemeModifier(theme: theme))
    }
}

extension View{
    func textAndSystemImagesColor(preferedScheme theme: Theme)-> some View{
        let color = theme == .Dark ?
        Color(red: 0.290, green: 0.427, blue: 0.533, opacity: 1.000) :
        Color(red: 0.835, green: 0.851, blue: 0.878, opacity: 1.000)
        return self
            .foregroundColor(color)
    }
}
extension View{
    func navigationLinkBackgroundLabel(preferedScheme theme: Theme, width: CGFloat)-> some View{
        let color = theme == .Dark ?
        Color(red: 0.212, green: 0.141, blue: 0.310, opacity: 1.000) :
        Color(red: 0.325, green: 0.329, blue: 0.992, opacity: 1.000)
        return self
            .frame(width: width, height: 50)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

extension Image{
    func statusImage(width: CGFloat, height: CGFloat, color: Color, opacity: Double)-> some View{
        self
            .resizable()
            .scaledToFill()
            .foregroundColor(color)
            .frame(width: width, height: height)
            .opacity(opacity)
    }
}
struct GameButton : ButtonStyle{
    var width : CGFloat
    var height: CGFloat
    var theme: Theme
    var pauseGame: Bool
    func makeBody(configuration: Configuration) -> some View{
        let color = theme == .Dark ?
        Color(red: 0.451, green: 0.020, blue: 0.090, opacity: 1.000) :
        Color(red: 0.945, green: 0.094, blue: 0.298, opacity: 1.000)
        configuration.label
            .frame(width: width, height: height)
            .background(color.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(color, lineWidth: 5)
            )
            .disabled(pauseGame)
            .overlay(
                pauseGame ?
                AnyView(RoundedRectangle(cornerRadius: 10)
                    .foregroundColor(.gray.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray, lineWidth: 5)
                    )) :
                AnyView(Color.clear)
            )
    }
}
