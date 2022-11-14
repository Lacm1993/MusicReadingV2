//
//  AddNewLevel.swift
//  MusicReadingV2
//
//  Created by Luis Alfonso Contreras Maya on 13/11/22.
//

import SwiftUI

struct AddNewLevelView: View {
    let theme: Theme
    
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var data: AppProgress
    
    @State private var notes = Set<Note>()
    @State private var numberOfQuestions = 0
    @State private var timer = 0
    var isSaveButtonDisabled: Bool{
        notes.count < 2 && numberOfQuestions < 10 && timer < 10
    }
    @State private var noteName : NoteName = .C
    @State private var register = 4
    @State private var clef : Clef = .G
    
    var body: some View {
        NavigationStack{
            GeometryReader{geo in
                ScrollView{
                    VStack{
                        
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("New custom level")
            .preferredColorScheme(theme == .Dark ? .dark : .light)
            .toolbar{
                ToolbarItem(placement: .navigationBarTrailing){
                    Button{
                        data.addLevel(withNumberOfQuestions: numberOfQuestions, timer: timer, notes: notes)
                        dismiss()
                    }label: {
                        Text("Save")
                    }
                    .disabled(isSaveButtonDisabled)
                }
                ToolbarItem(placement: .navigationBarLeading){
                    Button("Cancel"){dismiss()}
                }
            }
        }
    }
}
extension AddNewLevelView{
    func saveNewLevel(){
        
    }
    func addNote(){
        
    }
}

struct AddNewLevelView_Previews: PreviewProvider {
    static var previews: some View {
        AddNewLevelView(theme: .Dark)
    }
}
