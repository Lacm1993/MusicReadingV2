//
//  LevelView.swift
//  MusicReading
//
//  Created by Luis Alfonso Contreras Maya on 24/09/22.
//

import SwiftUI
import CoreHaptics

struct LevelView: View {
    let id: Int
    let inputMethod: InputMethod
    let timerAnimation = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()
    let timerGamePlay = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    let alertTitle = "Strange note!!"
    let alertMessage = "You pressed on a note that's not included in this level"
    let theme: Theme
    
    @EnvironmentObject var data: AppProgress
    @EnvironmentObject var midiManager: MIDIModule
    
    @Environment(\.scenePhase) var scenePhase
    
    @State private var level = Level()
    @State private var score = ScoreInstance()
    @State private var solution = 0
    @State private var questionsRemaining = 0
    @State private var isShowingSheet = false
    @State private var isShowingAlert = false
    @State private var answerAnimation : Image?
    @State private var answerAnimationColor : Color = .green
    @State private var answerAnimationOpacity = 1.0
    @State private var timeRemaining = 0
    @State private var timeScaleEffect = 0.25
    @State private var pauseGame = false
    @State private var isNextLevelUnlocked : NextLevelUnlocked = .False
    @State private var haptics : CHHapticEngine?

    
    var rightAnswers: Int{
        score.scorePerNote.values.map{ $0.right }.reduce(0, +)
    }
    var wrongAnswers: Int{
        score.scorePerNote.values.map{ $0.wrong }.reduce(0, +)
    }
    var waitingForInputMessage: String{
        switch inputMethod {
        case .Buttons:
            return "Press on a note name to start the game"
        case .MIDI:
            return "Press a note on your keyboard to start the game"
        case .Audio:
            return "Press on the mic and say the name of the note to start the game"
        }
    }
    
    var body: some View {
        GeometryReader{geo in
            
            let vStackSpacing = geo.size.height * 0.08
            let imageFrame = CGSize(width: geo.size.width * 0.10, height: geo.size.height * 0.10)
            let waitForInputFrameWidth = geo.size.width * 0.85
            let buttonSize = CGSize(width: geo.size.width * 0.18, height: geo.size.height * 0.10)
            let buttonFont = geo.size.height > geo.size.width ? geo.size.height * 0.03 : geo.size.height * 0.045
            
            ScrollView(.vertical){
                VStack(spacing: vStackSpacing){
                    Text("Time: \(timeRemaining)")
                        .font(.system(size: 80))
                        .scaleEffect(timeScaleEffect)
                    if questionsRemaining > 0{
                        if let validAnswerAnimation = answerAnimation{
                            validAnswerAnimation
                                .statusImage(width: imageFrame.width, height: imageFrame.height, color: answerAnimationColor, opacity: answerAnimationOpacity)
                        }else{
                            Text(waitingForInputMessage)
                                .multilineTextAlignment(.center)
                                .frame(width: waitForInputFrameWidth, height: imageFrame.height)
                        }
                        Text(level.note(at: solution)?.id ?? "")
                            .padding()
                    }
                    switch inputMethod {
                    case .Buttons:
                        ButtonInputSubView(funcToRun: judge, level: level, pauseGame: pauseGame, buttonSize: buttonSize, font: buttonFont, theme: theme)
                    case .MIDI:
                        if let event = midiManager.midiEventNoteNumber{
                            Text("Note number: \(event)")
                                .foregroundColor(.primary)
                        }else{
                            Text("Waiting For input...")
                                .foregroundColor(.primary)
                        }
                    case .Audio:
                        Text("Audio")
                    }
                    
                    Text("Remaining questions: \(questionsRemaining)")

                    HStack(spacing: 20){
                        VStack(alignment: .center){
                            Text("Right answers:")
                            Text("\(rightAnswers)")
                        }
                        VStack(alignment: .center){
                            Text("Wrong answers:")
                            Text("\(wrongAnswers)")
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .textAndSystemImagesColor(preferedScheme: theme)
            }
            .navigationTitle(Text("Level \(id)"))
            .navigationBarTitleDisplayMode(.inline)
            .theme(preferedScheme: theme)
            .customToolbarApperance()
            .sheet(isPresented: $isShowingSheet, onDismiss: {reset()}){
                StatisticsView(level: level, score: score.scorePerNote, theme: theme, isNextLevelUnlocked: isNextLevelUnlocked)
            }
            .alert(alertTitle, isPresented: $isShowingAlert){
                Button{
                    pauseGame = false
                }label: {
                    Text("Ok")
                }
            }message: {
                Text(alertMessage)
            }
            .toolbar{
                ToolbarItemGroup(placement: .navigationBarTrailing){
                    Button{
                        withAnimation(.default){
                            pauseGame.toggle()
                        }
                    }label: {
                        pauseGame ? Image(systemName: "play.fill") : Image(systemName: "pause.fill")
                    }
                    Button{
                        reset()
                    }label: {
                        Text("Reset")
                    }
                }
            }
            .onAppear{
                level = data.level(withID: id)
                solution = Int.random(in: 0..<level.notes.count)
                questionsRemaining = level.numberOfQuestions
                timeRemaining = level.timer
                timeScaleEffect = 1.0
                for i in level.notes{
                    score.scorePerNote[i] = ScoreInstance.ScorePerNote()
                }
            }
            .onChange(of: questionsRemaining){number in
                if number == 0{
                    saveToDataModel()
                    isShowingSheet = true
                }
            }
            .onChange(of: timeRemaining){time in
                if time == 0{
                    saveToDataModel()
                    isShowingSheet = true
                }
                if time < 10{
                    withAnimation{
                        timeScaleEffect += 0.05
                    }
                }else{
                    timeScaleEffect = 0.25
                }
            }
            .onChange(of: solution){_ in
                prepareHaptics()
            }
            .onChange(of: midiManager.midiEvent){_ in
                guard let event = midiManager.midiEventNoteNumber else{
                    return
                }
                judgeAnswerInMIDI(forNoteNumber: event)
            }
            .onReceive(timerAnimation){_ in
                if answerAnimationOpacity > 0{
                    withAnimation(.default){
                        answerAnimationOpacity -= 0.25
                    }
                }
            }
            .onReceive(timerGamePlay){_ in
                guard scenePhase == .active else{ return }
                guard !pauseGame else {return}
                if timeRemaining > 0{
                    timeRemaining -= 1
                }
            }
        }
    }
}


extension LevelView{
    func reset(){
        level = data.level(withID: id)
        solution = Int.random(in: 0..<level.notes.count)
        questionsRemaining = level.numberOfQuestions
        timeRemaining = level.timer
        score = ScoreInstance()
        for i in level.notes{
            score.scorePerNote[i] = ScoreInstance.ScorePerNote()
        }
    }
    func saveToDataModel(){
        level.updateMaxScoreAndNumberOfTries(with: rightAnswers)
        data.updateLevelInfo(with: level)
        isNextLevelUnlocked = data.unlockNextLevel(fromLevelAtIndex: level.id)
        data.saveData()
    }
}


extension LevelView{
    func performActions(withCorrectNote correctNote: Note, status: AnswerStatus){
        switch status {
        case .Right:
            hapticRightAnswer()
            score.scorePerNote[correctNote]!.right += 1
            level.updateStatistics(for: correctNote, status: .Right)
            answerAnimation = Image(systemName: "checkmark.circle.fill")
            answerAnimationColor = .green
        case .Wrong:
            hapticWrongAnswer()
            score.scorePerNote[correctNote]!.wrong += 1
            level.updateStatistics(for: correctNote, status: .Wrong)
            answerAnimation = Image(systemName: "xmark.circle.fill")
            answerAnimationColor = .red
        }
        answerAnimationOpacity = 1
        questionsRemaining -= 1
        solution = Int.random(in: 0..<level.noteCount)
    }
    func judge(answer: Int){
        let correctNote = level.note(at: solution)
        guard let correctNote else{
            return
        }
        let submittedNote = level.uniqueNoteNames[answer]
        let decision = correctNote.name.rawValue == submittedNote || correctNote.simpleLabel() == submittedNote
        switch decision{
        case true:
            performActions(withCorrectNote: correctNote, status: .Right)
        case false:
            performActions(withCorrectNote: correctNote, status: .Wrong)
        }
    }
    func judgeAnswerInMIDI(forNoteNumber number: Int){
        let correctNote = level.note(at: solution)
        guard let correctNote else{
            return
        }
        let submittedNote = level.notes.first{note in note.MIDINoteNumber == number}
        guard let submittedNote else{
            performActions(withCorrectNote: correctNote, status: .Wrong)
            pauseGame = true
            isShowingAlert = true
            return
        }
        let decision = correctNote == submittedNote
        switch decision{
        case true:
            performActions(withCorrectNote: correctNote, status: .Right)
        case false:
            performActions(withCorrectNote: correctNote, status: .Wrong)
        }
    }
}


extension LevelView{
    func prepareHaptics(){
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else{
            print("Device does not support haptics")
            return
        }
        do{
            haptics = try CHHapticEngine()
            try haptics?.start()
        }catch{
            print("Something went wrong with the haptics")
        }
    }
    func hapticRightAnswer(){
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else{
            return
        }
        var events = [CHHapticEvent]()
        let parameter1 : CHHapticEventParameter = .init(parameterID: .hapticIntensity, value: 1)
        let parameter2 : CHHapticEventParameter = .init(parameterID: .hapticSharpness, value: 1)
        let event : CHHapticEvent = .init(eventType: .hapticTransient, parameters: [parameter1, parameter2], relativeTime: 0)
        events.append(event)
        do{
            let pattern : CHHapticPattern = try .init(events: events, parameters: [])
            let player = try haptics?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        }catch{
            print("Something went wrong with the haptics")
        }
    }
    func hapticWrongAnswer(){
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else{
            return
        }
        var events = [CHHapticEvent]()
        let parameter1 : CHHapticEventParameter = .init(parameterID: .hapticIntensity, value: 1)
        let parameter2 : CHHapticEventParameter = .init(parameterID: .hapticSharpness, value: 1)
        let parameter3 : CHHapticEventParameter = .init(parameterID: .hapticIntensity, value: 0.5)
        let parameter4 : CHHapticEventParameter = .init(parameterID: .hapticSharpness, value: 0.5)
        let event1 : CHHapticEvent = .init(eventType: .hapticTransient, parameters: [parameter1, parameter2], relativeTime: 0.0)
        let event2 : CHHapticEvent = .init(eventType: .hapticTransient, parameters: [parameter3, parameter4], relativeTime: 0.5)
        events.append(event1)
        events.append(event2)
        do{
            let pattern : CHHapticPattern = try .init(events: events, parameters: [])
            let player = try haptics?.makePlayer(with: pattern)
            try player?.start(atTime: 0.0)
        }catch{
            print("Something went wrong with the haptics")
        }
    }
}

struct LevelView_Previews: PreviewProvider {
    static var previews: some View {
        LevelView(id: 0, inputMethod: .Buttons, theme: .Dark)
    }
}


