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
    
    @State private var levelToEdit : Int?
    @State private var levelToDelete = -1
    @State private var isShowingNewLevelSheet = false
    @State private var isShowingSheet = false
    @State private var isShowingAlert = false
    @State private var isRemainderToSaveNeeded = false
    
    @AppStorage("InputMethod") var inputMethod : InputMethod = .Buttons
    @AppStorage("Theme") var theme: Theme = .Dark

    var body: some View {
        NavigationStack(path: $navigationHistory.stack){
            GeometryReader{geo in
                
                let space = geo.frame(in: .global)
                let vStackWidth = geo.size.width * 0.85
                let hStackWidth = space.width * 0.45
                let navigationLinkLabelWidth = space.width * 0.30
                
                ScrollViewReader{scrollManager in
                    ScrollView(.vertical, showsIndicators: false){
                        VStack(spacing: 10){
                            ForEach($data.levels){$level in
                                VStack{
                                    HStack(spacing: hStackWidth){
                                        NavigationLink(value: level){
                                            navigationLinkLabel(level.id)
                                            .navigationLinkBackgroundLabel(preferedScheme: theme, width: navigationLinkLabelWidth)
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
                                        Stepper("Questions:\t\(level.numberOfQuestions)", value: $level.numberOfQuestions, in: 90...500, step: 1)
                                        Stepper("Seconds:\t\(level.timer)", value: $level.timer, in: 30...500, step: 1)
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
                                                    deleteLevel(level: level)
                                                }label: {
                                                    Image(systemName: "trash.fill")
                                                        .foregroundColor(.red)
                                                }
                                            }
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                }
                                .frame(width: vStackWidth)
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
                            }
                            .navigationDestination(for: Level.self){level in
                                LevelView(id: level.id, inputMethod: inputMethod, theme: theme)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.vertical)
                    }
                    .theme(preferedScheme: theme)
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
                                let func1 = {
                                    withAnimation{
                                        scrollManager.scrollTo(data.firstMandatoryLevelID, anchor: UnitPoint(x: space.midX, y: space .minY))
                                    }
                                }
                                let func2 = {
                                    withAnimation{
                                        scrollManager.scrollTo(data.firstCustomLevelID, anchor: .top)
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
            }
        }
        .preferredColorScheme(theme == .Dark ? .dark : .light)
        .environmentObject(data)
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
}


extension ContentView{
    func navigationLinkLabel(_ id: Int)-> some View{
        if horizontalSizeClass == .compact && dynamicTypeSize >= .xxLarge{
            return HStack(spacing: 20){
                Text("L\(id)")
                Image(systemName: "play.fill")
                    .font(.largeTitle)
            }
        }else{
            return HStack(spacing: 20){
                Text("Level \(id)")
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
