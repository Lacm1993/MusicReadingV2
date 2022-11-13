//
//  ButtonInputSubView.swift
//  MusicReading
//
//  Created by Luis Alfonso Contreras Maya on 28/10/22.
//

import SwiftUI

struct ButtonInputSubView: View {
    let maxNumber: Int
    let funcToRun: (Int)-> Void
    let level: Level
    let gridItems : [GridItem] = [.init(.flexible(minimum: 100, maximum: 300))]
    let pauseGame: Bool
    let width: CGFloat
    let height: CGFloat
    let theme: Theme
    var body: some View {
        LazyHGrid(rows: gridItems, spacing: 30){
            ForEach(0..<maxNumber, id: \.self){number in
                Button{
                    funcToRun(number)
                }label: {
                    Text(level.uniqueNoteNames[number].rawValue)
                }
                .buttonStyle(GameButton(width: width, height: height, theme: theme, pauseGame: pauseGame))
                .disabled(pauseGame)
            }
        }
    }
}

struct ButtonInputSubView_Previews: PreviewProvider {
    static var funcToPreview = {(int: Int) -> Void in }
    static var previews: some View {
        ButtonInputSubView(maxNumber: 10, funcToRun: funcToPreview, level: Level(id: -1, notes: []), pauseGame: true, width: 10, height: 10, theme: .Dark)
    }
}

