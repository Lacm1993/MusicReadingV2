//
//  ContentView.swift
//  MusicReading
//
//  Created by Luis Alfonso Contreras Maya on 23/09/22.
//

import SwiftUI

struct ContentView: View {
    @StateObject var data = AppProgress()
    @StateObject var navigationHistory = NavigationHistory()
    
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    @State private var levelToEdit : UUID?
    @State private var isShowingNewLevelSheet = false
    @State private var isShowingSheet = false
    @State private var isShowingAlert = false
    @State private var isRemainderToSaveNeeded = false
    
    @AppStorage("InputMethod") var inputMethod : InputMethod = .Buttons
    @AppStorage("Theme") var theme: Theme = .Dark

    var body: some View {
        GeometryReader{geo in
            NavigationStack(path: $navigationHistory.stack){
                ScrollViewReader{scrollManager in
                    ScrollView(.vertical, showsIndicators: false){
                        VStack(spacing: 10){
                            ForEach($data.levels){$level in
                                VStack{
                                    HStack(spacing: geo.size.width * 0.45){
                                        NavigationLink(value: level){
                                            navigationLinkLabel(level.id)
                                                .navigationLinkBackgroundLabel(preferedScheme: theme, width: geo.size.width * 0.30)
                                        }
                                        .needsToSaveChangesToEnable(check: isRemainderToSaveNeeded)
                                        Button{
                                            withAnimation{
                                                if let levelToEdit, levelToEdit == level.id{
                                                    self.levelToEdit = nil
                                                }else{
                                                    levelToEdit = level.id
                                                }
                                            }
                                        }label: {
                                            Image(systemName: "gearshape.fill")
                                                .font(.largeTitle)
                                        }
                                        .needsToSaveChangesToEnable(check: isRemainderToSaveNeeded)
                                    }
                                    .textAndSystemImagesColor(preferedScheme: theme)
                                    if let levelToEdit, levelToEdit == level.id{
                                        if !level.isSequence{
                                            Stepper("\(level.numberOfQuestions) questions", value: $level.numberOfQuestions, in: 90...500, step: 1)
                                            Stepper("\(level.timer) seconds", value: $level.timer, in: 30...500, step: 1)
                                        }else{
                                            Stepper("\(level.sequenceCount) sequences", value: $level.sequenceCount, in: 10...200, step: 1)
                                            Stepper("\(level.timer) seconds per sequence", value: $level.timer, in: 4...12, step: 1)
                                            Stepper("\(level.sequenceNoteCount) notes per sequence", value: $level.sequenceNoteCount, in: 2...10, step: 1)
                                        }
                                        
                                        HStack(spacing: 100){
                                            Button{
                                                saveEdits(for: level)
                                            }label: {
                                                Text("Save")
                                            }
                                            .scaleEffect(isRemainderToSaveNeeded ? 1.4 : 1)
                                            .animation(.default.repeatForever(autoreverses: true), value: isRemainderToSaveNeeded)
                                            if level.isDeletable{
                                                Button{
                                                    withAnimation{
                                                        deleteLevelAndResetState(level: level)
                                                    }
                                                }label: {
                                                    Image(systemName: "trash.fill")
                                                        .foregroundColor(.red)
                                                }
                                            }
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                }
                                .frame(width: geo.size.width * 0.85)
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numberPad)
                                .disabled(!level.isEnabled)
                                .disabledAppearance(check: !level.isEnabled)
                                .id(level.id)
                                .onChange(of: level.numberOfQuestions){_ in
                                    isRemainderToSaveNeeded = true
                                }
                                .onChange(of: level.timer){_ in
                                    isRemainderToSaveNeeded = true
                                }
                                .onChange(of: level.sequenceCount){_ in
                                    isRemainderToSaveNeeded = true
                                }
                                .onChange(of: level.sequenceNoteCount){_ in
                                    isRemainderToSaveNeeded = true
                                }
                                .transition(AnyTransition.asymmetric(insertion: .opacity, removal: .slide).combined(with: .opacity))
                            }
                            .navigationDestination(for: Level.self){level in
                                LevelView(id: level.id, inputMethod: inputMethod, theme: theme)
                            }
                        }
                        .padding(.vertical)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .navigationTitle(Text("Music reading"))
                    .customToolbarApperance()
                    .alert("Done!", isPresented: $isShowingAlert){
                        Button(action: {}){Text("OK")}
                    }message: {
                        Text("Changes saved!")
                    }
                    .sheet(isPresented: $isShowingSheet){
                        SettingsView(inputMethod: $inputMethod, theme: $theme)
                            .presentationDetents([.fraction(0.38), .fraction(0.60)])
                    }
                    .sheet(isPresented: $isShowingNewLevelSheet){
                        AddNewLevelView(theme: theme)
                    }
                    .safeAreaInset(edge: .bottom, alignment: .leading){
                        Button{
                            isShowingSheet = true
                        }label: {
                            Image(systemName: "gearshape.fill")
                                .font(.largeTitle)
                                .textAndSystemImagesColor(preferedScheme: theme)
                        }
                        .padding()
                        .needsToSaveChangesToEnable(check: isRemainderToSaveNeeded)
                    }
                    .toolbar{
                        ToolbarItem(placement: .navigationBarTrailing){
                            HStack{
                                if let firstCustomLevel = data.firstCustomLevelID{
                                    let func1 = {
                                        withAnimation{
                                            scrollManager.scrollTo(data.firstMandatoryLevelID, anchor: .top)
                                        }
                                    }
                                    let func2 = {
                                        withAnimation{
                                            scrollManager.scrollTo(firstCustomLevel, anchor: .top)
                                        }
                                    }
                                    if horizontalSizeClass == .regular{
                                        ScrollReaderRegularView{
                                            func1()
                                        }funcToRun2: {
                                            func2()
                                        }
                                    }else{
                                        ScrollreaderCompactView{
                                            func1()
                                        }funcToRun2: {
                                            func2()
                                        }
                                    }
                                    Divider()
                                }
                                Button{
                                    isShowingNewLevelSheet = true
                                }label:{
                                    Image(systemName: "plus")
                                }
                            }
                            .disabled(isRemainderToSaveNeeded)
                            .animation(.default, value: isRemainderToSaveNeeded)
                        }
                    }
                    .onChange(of: scenePhase){phase in
                        if phase == .background || phase == .inactive{
                            navigationHistory.saveStackHistory()
                        }
                    }
                }
                .theme(preferedScheme: theme)
            }
            .preferredColorScheme(theme == .Dark ? .dark : .light)
            .environmentObject(data)
        }
    }
}


extension ContentView{
    //I could just call data.saveData every time the value changes, with an onChange but i think is kinda wasteful to call saveData everyTime
    func saveEdits(for level: Level){
        data.saveData()
        isRemainderToSaveNeeded = false
        isShowingAlert = true
        //So it goes to the original property, not to the binding
        withAnimation{
            self.levelToEdit = nil
        }
    }
    func deleteLevel(level: Level){
        levelToEdit = level.id
        data.delete(level: level)
    }
    func deleteLevelAndResetState(level: Level){
        data.delete(level: level)
        levelToEdit = nil
    }
}


extension ContentView{
    func navigationLinkLabel(_ id: UUID)-> some View{
        let index = data.indexOfLevel(withID: id) + 1
        if horizontalSizeClass == .compact && dynamicTypeSize >= .xxLarge{
            return HStack(spacing: 20){
                Text("L\(index)")
                Image(systemName: "play.fill")
                    .font(.largeTitle)
            }
        }else{
            return HStack(spacing: 20){
                Text("Level \(index)")
                Image(systemName: "play.fill")
                    .font(.largeTitle)
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
