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
    @State private var levelToEdit : Int?
    @State private var isAlertShowing = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isShowingSheet = false
    @AppStorage("InputMethod") var inputMethod : InputMethod = .Buttons
    @AppStorage("Theme") var theme: Theme = .Dark
    @FocusState var isKeypadFocused : Bool
    
    var body: some View {
        NavigationStack(path: $navigationHistory.stack){
            GeometryReader{geo in
                
                let space = geo.frame(in: .global)
                let vStackWidth = geo.size.width * 0.85
                let hStackWidth = space.width * 0.45
                let navigationLinkLabelWidth = space.width * 0.30
                
                ScrollView(.vertical, showsIndicators: false){
                    VStack(spacing: 10){
                        ForEach($data.levels){$level in
                            VStack{
                                HStack(spacing: hStackWidth){
                                    NavigationLink(value: level){
                                        HStack(spacing: 20){
                                            Text("Level \(level.id)")
                                            Image(systemName: "play.fill")
                                                .font(.largeTitle)
                                        }
                                        .navigationLinkBackgroundLabel(preferedScheme: theme, width: navigationLinkLabelWidth)
                                    }
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
                                }
                                .textAndSystemImagesColor(preferedScheme: theme)
                                if let levelToEdit, levelToEdit == level.id{
                                    TextField(value: $level.numberOfQuestions, format: .number){
                                        Text("Change number of questions")
                                    }
                                    .focused($isKeypadFocused)
                                    TextField(value: $level.timer, format: .number){
                                        Text("Change the time limit")
                                    }
                                    .focused($isKeypadFocused)
                                    Button{
                                        saveEdits(for: level)
                                    }label: {
                                        Text("Save")
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
                        }
                        .navigationDestination(for: Level.self){level in
                            LevelView(id: level.id, inputMethod: inputMethod, theme: theme)
                        }
                    }
                }
                .theme(preferedScheme: theme)
                .navigationTitle(Text("Music reading"))
                .alert(alertTitle, isPresented: $isAlertShowing){
                    Button(action: {}){
                        Text("OK")
                    }
                }message: {
                    Text(alertMessage)
                }
                .sheet(isPresented: $isShowingSheet){
                    SettingsView(inputMethod: $inputMethod, theme: $theme)
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
                }
                .toolbar{
                    ToolbarItemGroup(placement: .keyboard){
                        Spacer()
                        Button{
                            isKeypadFocused = false
                        }label: {
                            Text("Done")
                        }
                    }
                }
                .onChange(of: scenePhase){phase in
                    if phase == .background || phase == .inactive{
                        navigationHistory.saveStackHistory()
                    }
                }
            }
        }
        .preferredColorScheme(theme == .Dark ? .dark : .light)
        .environmentObject(data)
    }
}
extension ContentView{
    func saveEdits(for level: Level){
        guard level.numberOfQuestions >= 90 else{
            alertTitle = "Too few questions"
            alertMessage = "The minimum number of questions required is 90 for mandatory levels"
            isAlertShowing = true
            return
        }
        guard level.timer >= 30 else{
            alertTitle = "Choose a higher time limit"
            alertMessage = "Less than 30 seconds is not allowed in mandatory levels"
            isAlertShowing = true
                return
        }
        data.saveData()
        alertTitle = "Done!"
        alertMessage = "Changes saved"
        //So it goes to the original property, not to the binding
        withAnimation{
            self.levelToEdit = nil
        }
        isAlertShowing = true
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

