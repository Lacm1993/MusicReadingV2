//
//  ButtonInputSubView.swift
//  MusicReading
//
//  Created by Luis Alfonso Contreras Maya on 28/10/22.
//

import SwiftUI

struct ButtonInputSubView: View {
    let funcToRun: (Int)-> Void
    let level: Level
    let pauseGame: Bool
    let buttonSize: CGSize
    let font: CGFloat
    let theme: Theme
    var body: some View {
        if level.uniqueNoteCount <= 4{
            VStack(alignment: .center){
                HStack{
                    ForEach(0..<level.uniqueNoteCount, id: \.self){number in
                        Button{
                            funcToRun(number)
                        }label: {
                            Text(level.uniqueNoteNames[number])
                        }
                        .buttonStyle(GameButton(width: buttonSize.width, height: buttonSize.height, theme: theme, pauseGame: pauseGame))
                        .disabled(pauseGame)
                    }
                }
            }
            .font(.system(size: font))
        }else{
            VStack(alignment: .center){
                HStack{
                    ForEach(0..<4, id: \.self){number in
                        Button{
                            funcToRun(number)
                        }label: {
                            Text(level.uniqueNoteNames[number])
                        }
                        .buttonStyle(GameButton(width: buttonSize.width, height: buttonSize.height, theme: theme, pauseGame: pauseGame))
                        .disabled(pauseGame)
                    }
                }
                HStack{
                    ForEach(4..<level.uniqueNoteCount, id: \.self){number in
                        Button{
                            funcToRun(number)
                        }label: {
                            Text(level.uniqueNoteNames[number])
                        }
                        .buttonStyle(GameButton(width: buttonSize.width, height: buttonSize.height, theme: theme, pauseGame: pauseGame))
                        .disabled(pauseGame)
                    }
                }
            }
            .font(.system(size: font))
        }
    }
}

struct ButtonInputSubView_Previews: PreviewProvider {
    static var funcToPreview = {(int: Int) -> Void in }
    static var previews: some View {
        ButtonInputSubView(funcToRun: funcToPreview, level: Level( notes: []), pauseGame: true, buttonSize: CGSize.zero, font: 5, theme: .Dark)
    }
}

