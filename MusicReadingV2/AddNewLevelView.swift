//
//  AddNewLevel.swift
//  MusicReadingV2
//
//  Created by Luis Alfonso Contreras Maya on 13/11/22.
//

import SwiftUI

struct AddNewLevelView: View {
    let theme: Theme
    let midiInfo = MIDIInfo()
    
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var data: AppProgress
    
    @State private var notes = Set<Note>()
    @State private var selectedNotes = Set<Note>()
    @State private var numberOfQuestions = 90
    @State private var timer = 120
    @State private var addAllNotesInRegister = false
    @State private var addTheSameNotesFromAllAvailableRegisters = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isShowingNoteAlert = false
    @State private var isEditingEnabled = false
    @State private var noteName : NoteName = .C
    @State private var register = 4
    @State private var clef : Clef = .G
    
    var isSaveButtonDisabled: Bool{
        notes.count < 2
    }
    var areMultipleNotesBeingAdded: Bool{
        addAllNotesInRegister || addTheSameNotesFromAllAvailableRegisters
    }
    var noteArray: [Note]{
        notes.sorted()
    }
    var notesInRegister : [NoteName]{
        var notesInRegister = [NoteName]()
        for register in midiInfo.list{
            let octave = register.octave
            if octave == self.register{
                notesInRegister.append(contentsOf: register.notes.compactMap{ NoteName(rawValue: $0.name)})
            }
        }
        return notesInRegister
    }
    var sameNoteInAllAvailableRegisters: [Int]{
        switch clefsBasedOnRegister{
        case [.G, .C(atLine: 1), .C(atLine: 2), .C(atLine: 3)]:
            return Array(4...8)
        default:
            return Array(0...4)
        }
    }
    var clefsBasedOnRegister: [Clef]{
        switch register{
        case 4...8:
            return [.G, .C(atLine: 1), .C(atLine: 2), .C(atLine: 3)]
        default:
            return [.F, .C(atLine: 2), .C(atLine: 3), .C(atLine: 4)]
        }
    }
    var addNotesLabel: String{
        switch areMultipleNotesBeingAdded{
        case true:
            return "Add notes"
        case false:
            return "Add note \(noteName.rawValue)\(register)"
        }
    }
    var selectedNotesLabel: String{
        switch selectedNotes.count{
        case 0:
            return ""
        case 1:
            return "Delete 1 item"
        case _ where selectedNotes.count == notes.count:
            return "Delete all items"
        default:
            return "Delete \(selectedNotes.count) items"
        }
    }

    
    var body: some View {
        NavigationStack{
            Form{
                Section{
                    
                    
                    Stepper(value: $numberOfQuestions, in: 10...200, step: 1){
                        Text("\(numberOfQuestions) questions")
                    }
                    .accessibilityElements(label: "Number of questions.", hint: "Set the number of questions for this level, the minimum number of questions is ninety.", childBehavior: .ignore, value: "\(numberOfQuestions) questions selected"){action in
                        switch action {
                        case .increment:
                            numberOfQuestions += 1
                        case .decrement:
                            if numberOfQuestions > 90{
                                numberOfQuestions -= 1
                            }
                        @unknown default:
                            fatalError("Accesibility adjustable action currently not handled")
                        }
                    }
                    
                    
                    Stepper(value: $timer, in: 10...200, step: 1){
                        Text("\(timer) seconds")
                    }
                    .accessibilityElements(label: "Timer.", hint: "Set the time limit for this level, the minimum number of seconds is thirty.", childBehavior: .ignore, value: "\(timer) seconds."){action in
                        switch action {
                        case .increment:
                            timer += 1
                        case .decrement:
                            if timer > 30{
                                timer -= 1
                            }
                        @unknown default:
                            fatalError("Accesibility adjustable action currently not handled")
                        }
                    }
                    
                    
                }header: {
                    Text("Number of questions & Time limit")
                }
                
                
                if !notes.isEmpty{
                    Section{
                        
                        
                        Button{
                            withAnimation{
                                isEditingEnabled.toggle()
                                selectedNotes = []
                            }
                        }label: {
                            Text(isEditingEnabled ? "Done" : "Edit")
                        }
                        .accessibilityHint(!isEditingEnabled ? "Remove notes from the custom level you're creating." : "Get out of edit mode without deleting any note.")
                        
                        
                        if !selectedNotes.isEmpty{
                            Button{
                                withAnimation{
                                    removeSelectedNotes()
                                }
                            }label: {
                                Text(selectedNotesLabel)
                            }
                            .accessibilityHint("Remove the selection from the custom level, current selection is:  \(selectedNotes.map({ $0.name.rawValue + String($0.register)}).joined(separator: ", ") )")
                        }
                        
                        
                        List{
                            ForEach(noteArray){note in
                                HStack{
                                    if isEditingEnabled{
                                        if !selectedNotes.contains(note){
                                            Image(systemName: "circle")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 25, height: 25)
                                        }else{
                                            Image(systemName: "checkmark.circle.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 25, height:  25)
                                                .foregroundColor(.blue)
                                        }
                                        
                                    }
                                    (Text(note.name.rawValue) + Text("\(note.register)"))
                                        .padding()
                                        .foregroundColor(.white)
                                        .background(Color(red: 0.212, green: 0.141, blue: 0.310, opacity: 1.000))
                                }
                                .swipeActions(edge: .trailing , allowsFullSwipe: true){
                                    Button{
                                        removeNote(note)
                                    }label: {
                                        Image(systemName: "trash.fill")
                                    }
                                    .tint(.red)
                                }
                                .onTapGesture {
                                    if isEditingEnabled{
                                        withAnimation{
                                            selectAndDiselectNote(note)
                                        }
                                    }
                                }
                                .accessibilityElement()
                                .accessibilityLabel("\(note.name.rawValue + String(note.register))")
                                .accessibilityHint(isEditingEnabled ? "Double tap to select" : "")
                                .accessibilityAction(named: "Select note"){
                                    selectAndDiselectNote(note)
                                }
                            }
                        }
                    }header: {
                        Text("Notes")
                    }
                }
                
                
                Section{
                    
                    
                    Stepper(value: $register, in: 0...8, step: 1){
                        Text("Register: \(register)")
                    }
                    .accessibilityElements(label: "Register.", hint: "Set how high or low the note is located in the staff, the range is between 0 and 9.", childBehavior: .ignore, value: "Register \(register) is selected."){action in
                        switch action {
                        case .increment:
                            if register < 8{
                                register += 1
                            }
                        case .decrement:
                            if register > 0{
                                register -= 1
                            }
                        @unknown default:
                            fatalError("Accesibility adjustable action currently not handled")
                        }
                        
                    }
                    
                    
                    Picker("Choose a clef", selection: $clef){
                        ForEach(clefsBasedOnRegister){clef in
                            Text(clef.stringValue()).tag(clef)
                        }
                    }
                    .accessibilityElements(label: "Clef.", hint: "Choose the clef on which the note will be displayed.", childBehavior: .ignore, value: "clef \(clef.stringValue()) is selected."){action in
                        var index = clefsBasedOnRegister.firstIndex(of: clef)!
                        switch action {
                        case .increment:
                            if index < clefsBasedOnRegister.count - 1{
                                index += 1
                                clef = clefsBasedOnRegister[index]
                            }
                        case .decrement:
                            if index > 0{
                                index -= 1
                                clef = clefsBasedOnRegister[index]
                            }
                        @unknown default:
                            fatalError("Accesibility adjustable action currently not handled")
                        }
                    }
                    
                    
                    Toggle("Add all notes in register \(register)", isOn: $addAllNotesInRegister.animation(.default))
                        .accessibilityElements(label: "Add all notes in register \(register).", hint: "Quickly add all notes in the selected register and displayed in the selected clef.", childBehavior: .ignore, value: "Currently \(addAllNotesInRegister ? "selected." : "Not selected.")"){action in
                            switch action {
                            case .increment:
                                if !addAllNotesInRegister{
                                    addAllNotesInRegister = true
                                }
                            case .decrement:
                                if addAllNotesInRegister{
                                    addAllNotesInRegister = false
                                }
                            @unknown default:
                                fatalError("Accesibility adjustable action currently not handled")
                            }
                        }
                }header: {
                    Text("Register and clef")
                }
                .disabled(addTheSameNotesFromAllAvailableRegisters)
                
                
                if !addAllNotesInRegister{
                    Section{
                        
                        
                        Picker("Choose a note", selection: $noteName){
                            ForEach(notesInRegister){noteName in
                                Text(noteName.rawValue)
                            }
                        }
                        .accessibilityElements(label: "Note.", hint: "Select a note from the selected register to be added and displayed in the selected clef", childBehavior: .ignore, value: "\(noteName.rawValue) is selected"){action in
                            var index = notesInRegister.firstIndex(of: noteName)!
                            switch action {
                            case .increment:
                                if index < notesInRegister.count - 1{
                                    noteName = notesInRegister[index]
                                }
                            case .decrement:
                                if index > 0{
                                    noteName = notesInRegister[index]
                                }
                            @unknown default:
                                fatalError("Accesibility adjustable action currently not handled")
                            }
                        }
                        
                        
                        Toggle("Add the note \(noteName.rawValue) for all available registers in the selected clef", isOn: $addTheSameNotesFromAllAvailableRegisters.animation(.default))
                            .accessibilityElements(label: "Add all notes in the register.", hint: "Quickly add the selected notes for all available registers in the selected clef.", childBehavior: .ignore, value: "Currently \(addTheSameNotesFromAllAvailableRegisters ? "selected." : "not selected.")"){action in
                                switch action {
                                case .increment:
                                    if !addTheSameNotesFromAllAvailableRegisters{
                                        addTheSameNotesFromAllAvailableRegisters = true
                                    }
                                case .decrement:
                                    if addTheSameNotesFromAllAvailableRegisters{
                                        addTheSameNotesFromAllAvailableRegisters = false
                                    }
                                @unknown default:
                                    fatalError("Accesibility adjustable action currently not handled")
                                }
                            }
                        
                        
                    }header: {
                        Text("Note")
                    }
                }
                
                
                Section{
                    Button{
                        withAnimation{
                            if areMultipleNotesBeingAdded{
                                addNotes()
                            }else{
                                addNote()
                            }
                        }
                    }label: {
                        Text(addNotesLabel)
                    }
                    .accessibilityHint("\(addNotesLabel) to the custom level you're creating")
                }
                
                
            }
            .navigationTitle("New custom level")
            .preferredColorScheme(theme == .Dark ? .dark : .light)
            .toolbar{
                ToolbarItem(placement: .navigationBarTrailing){
                    Button{
                        saveNewLevel()
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
            .alert(alertTitle, isPresented: $isShowingNoteAlert){
                Button{
                    resetNoteInputData()
                }label: {
                    Text("Ok")
                }
            }message: {
                Text(alertMessage)
            }
            .onChange(of: register){reg in
                switch reg{
                case 0...3:
                    if clef == .G || clef == .C(atLine: 1){
                        clef = .F
                    }
                default:
                    if clef == .F || clef == .C(atLine: 4){
                        clef = .G
                    }
                }
            }
        }
    }
}


extension AddNewLevelView{
    func saveNewLevel(){
        data.addLevel(withNumberOfQuestions: numberOfQuestions, timer: timer, notes: notes)
    }
    func resetNoteInputData(){
        addAllNotesInRegister = false
        addTheSameNotesFromAllAvailableRegisters = false
        noteName = .C
        register = 4
        clef = .G
    }
    func addNote(){
        guard !addAllNotesInRegister else{
            return
        }
        let note = data.note(with: noteName, register: register, and: clef, getMIDINumberFrom: midiInfo)
        guard !notes.contains(note) else{
            alertTitle = "There's a problem!"
            alertMessage = "You can't add the exact same note twice, add a different note."
            isShowingNoteAlert = true
            return
        }
        notes.insert(note)
        alertTitle = "Done!"
        alertMessage = "Note succesfully added!"
        isShowingNoteAlert = true
    }
    func addNotes(){
        let wasNotesEmpty = notes.isEmpty ? true : false
        guard areMultipleNotesBeingAdded else{
            return
        }
        if addAllNotesInRegister{
            for name in notesInRegister{
                notes.insert(data.note(with: name, register: register, and: clef, getMIDINumberFrom: midiInfo))
            }
        }
        if addTheSameNotesFromAllAvailableRegisters{
            for octave in sameNoteInAllAvailableRegisters{
                if let validOctave = midiInfo.list.first(where:{register in register.octave == octave}){
                    if let note = validOctave.notes.first(where: {innerNote in innerNote.name == noteName.rawValue}){
                        notes.insert(data.note(with: NoteName(rawValue: note.name)!, register: validOctave.octave, and: clef, getMIDINumberFrom: midiInfo))
                    }
                }
            }
        }
        if !wasNotesEmpty{
            alertMessage = "The notes that weren't included already where succesfully added!"
        }else{
            alertMessage = "The notes were succesfully added!"
        }
        alertTitle = "Done!"
        isShowingNoteAlert = true
    }
    func removeNote(_ note: Note){
        notes.remove(note)
    }
    func selectAndDiselectNote(_ note: Note){
        if !selectedNotes.contains(note){
            selectedNotes.insert(note)
        }else{
            selectedNotes.remove(note)
        }
    }
    func removeSelectedNotes(){
        for note in selectedNotes{
            notes.remove(note)
        }
        selectedNotes = []
        isEditingEnabled = false
    }
}



struct AddNewLevelView_Previews: PreviewProvider {
    static var previews: some View {
        AddNewLevelView(theme: .Dark)
    }
}
