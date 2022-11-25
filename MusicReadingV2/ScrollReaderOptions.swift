//
//  ScrollReaderOptionsView.swift
//  MusicReadingV2
//
//  Created by Luis Alfonso Contreras Maya on 23/11/22.
//

import SwiftUI

struct ScrollReaderRegularView: View {
    let funcToRun1: ()-> Void
    let funcToRun2:()-> Void
    var body: some View {
        ControlGroup{
            Button{
                withAnimation{
                    funcToRun1()
                }
            }label: {
                Text("Mandatory")
            }
            Button{
                funcToRun2()
            }label:{
                Text("Custom")
            }
        }
    }
}

struct ScrollreaderCompactView: View{
    let funcToRun1: ()-> Void
    let funcToRun2: ()-> Void
    var body: some View{
        Menu{
            Button{
                funcToRun1()
            }label: {
                Text("Mandatorty levels")
            }
            Button{
                funcToRun2()
            }label: {
                Text("Custom levels")
            }
        }label: {
            Image(systemName: "ellipsis.circle.fill")
        }
    }
}

struct ScrollReaderRegularView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollReaderRegularView(funcToRun1: {}, funcToRun2: {})
    }
}
