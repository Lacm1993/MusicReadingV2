//
//  LevelView.swift
//  MusicReading
//
//  Created by Luis Alfonso Contreras Maya on 24/09/22.
//

import SwiftUI
import CoreHaptics

struct LevelView: View {
    let id: UUID
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
    
    //If the level is a normal level
    @State private var solution = 0
    @State private var questionsRemaining = 0
    @State private var sequencesRemaining = 0
    
    @State private var answerAnimation : Image?
    @State private var answerAnimationColor : Color = .green
    @State private var answerAnimationOpacity = 1.0
    
    //If the level is a sequence
    @State private var currentSequence = [Note]()
    @State private var currentAnswers = [Int]()
    @State private var currentAnswersStatus = [Bool]()

    //For both types of level
    @State private var isShowingSheet = false
    @State private var isShowingAlert = false
    
    @State private var timeRemaining = 0
    @State private var timerScaleEffect = 0.25
    
    @State private var pauseGame = false
    
    //For mandatory levels
    @State private var isNextLevelUnlocked : NextLevelUnlocked = .False
    
    //For devices with Haptic engines
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
            
            let spacing = geo.size.height * 0.08
            let imageFrame = CGSize(width: geo.size.width * 0.10, height: geo.size.height * 0.10)
            let inputMessageWidth = geo.size.width * 0.85
            let buttonDimensions = CGSize(width: geo.size.width * 0.18, height: geo.size.height * 0.10)
            let fontSize = geo.size.height > geo.size.width ? geo.size.height * 0.03 : geo.size.height * 0.045
            
            ScrollView(.vertical){
                VStack(spacing: spacing){
                    //Timer
                    Text("Time: \(timeRemaining)")
                        .font(.system(size: 80))
                        .scaleEffect(timerScaleEffect)
                    
                    VisualFeedbackView(imageFrame: imageFrame, textWidth: inputMessageWidth)
                
                    QuestionView()
                    
                    InputView(fontSize: fontSize, buttonDimensions: buttonDimensions)
                    
                    MainCounterView()
                    
                    if !level.isSequence{
                        SecondaryCounterView()
                    }
                }
                .frame(maxWidth: .infinity)
                .textAndSystemImagesColor(preferedScheme: theme)
            }
            .navigationTitle(Text("Level \(data.indexOfLevel(withID: id) + 1)"))
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
            //For both types of level
            .onAppear{
                onAppearActions()
            }
            .onChange(of: timeRemaining){time in
                shouldEndGame(check: time)
                shouldAnimateTimer(check: time)
            }
            .onReceive(timerGamePlay){_ in
                guard scenePhase == .active else{ return }
                guard !pauseGame else { return }
                guard !isShowingSheet else { return }
                if timeRemaining > 0{
                    timeRemaining -= 1
                }
            }
            .onChange(of: midiManager.midiEvent){_ in
                guard let event = midiManager.midiEventNoteNumber else{
                    return
                }
                if !level.isSequence{
                    judgeAnswerInMIDI(forNoteNumber: event, correctNote: level.note(at: solution))
                }else{
                    currentAnswers.append(event)
                }
            }
            //For normal levels
            .onChange(of: questionsRemaining){counter in
                shouldEndGame(check: counter)
            }
            .onChange(of: solution){_ in
                prepareHaptics()
            }
            .onReceive(timerAnimation){_ in
                if answerAnimationOpacity > 0{
                    withAnimation(.default){
                        answerAnimationOpacity -= 0.25
                    }
                }
            }
            //For sequence mode
            .onChange(of: currentAnswers){answers in
                prepareHaptics()
                shouldDispatchAnswers(check: answers)
            }
            .onChange(of: sequencesRemaining){counter in
                shouldEndGame(check: counter)
            }
        }
    }
}


extension LevelView{
    
    func InputView(fontSize: CGFloat, buttonDimensions: CGSize)-> some View{
        @ViewBuilder var inputs: some View{
            switch inputMethod{
            case .Buttons:
                ButtonInputView(funcToRun1: judge, funcToRun2: storeAnswer, buttonDimensions: buttonDimensions, fontSize: fontSize)
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
        }
        return inputs
    }
    func ButtonInputView(funcToRun1: @escaping (Int, Note?)-> Void, funcToRun2:  @escaping (Int)-> Void, buttonDimensions: CGSize, fontSize: CGFloat)-> some View{
        ButtonLayout{
            ForEach(0..<level.uniqueNoteCount, id: \.self){number in
                Button{
                    if !level.isSequence{
                        funcToRun1(number, level.note(at: solution))
                    }else{
                        funcToRun2(number)
                        neutralHaptics()
                    }
                }label: {
                    Text(level.uniqueNoteNames[number])
                }
                .buttonStyle(GameButton(width: buttonDimensions.width, height: buttonDimensions.height, theme: theme, pauseGame: pauseGame))
                .disabled(pauseGame)
            }
        }
        .font(.system(size: fontSize))
    }
    func QuestionView()-> some View{
        @ViewBuilder var questions: some View{
            if level.isSequence{
                HStack(spacing: 10){
                    ForEach(currentSequence){note in
                        Text(note.simpleLabel())
                    }
                }
            }else{
                Text(level.note(at: solution)?.simpleLabel() ?? "")
                    .padding()
            }
        }
        return questions
    }
    func MainCounterView()-> some View{
        if level.isSequence{
            return Text("Remaining sequences: \(sequencesRemaining)")
        }else{
            return Text("Remaining questions \(questionsRemaining)")
        }
    }
    func SecondaryCounterView()-> some View{
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
}


extension LevelView{
    func VisualFeedbackView(imageFrame: CGSize, textWidth: CGFloat)-> some View{
        @ViewBuilder var animation: some View{
            if !level.isSequence{
                if let validAnswerAnimation = answerAnimation{
                    validAnswerAnimation
                        .statusImage(width: imageFrame.width, height: imageFrame.height, color: answerAnimationColor, opacity: answerAnimationOpacity)
                }else{
                    Text(waitingForInputMessage)
                        .multilineTextAlignment(.center)
                        .frame(width: textWidth, height: imageFrame.height)
                }
            }else{
                let startIndex = max(0, currentAnswersStatus.count - level.sequenceNoteCount)
                let latestAnswers = Array(currentAnswersStatus[startIndex..<currentAnswersStatus.count])
                HStack{
                    ForEach(0..<latestAnswers.count, id: \.self){num in
                        switch latestAnswers[num]{
                        case true:
                            Image(systemName: "checkmark.circle.fill")
                                .statusImage(width: 50, height: 50, color: .green, opacity: answerAnimationOpacity)
                        case false:
                            Image(systemName: "xmark.circle.fill")
                                .statusImage(width: 50, height: 50, color: .red, opacity: answerAnimationOpacity)
                        }
                    }
                }
            }
        }
        return animation
    }
}


extension LevelView{
    func onAppearActions(){
        level = data.level(withID: id)
        if !level.isSequence{
            solution = Int.random(in: 0..<level.notes.count)
            questionsRemaining = level.numberOfQuestions
        }else{
            var array = [Note]()
            while array.count < level.sequenceNoteCount{
                let note = level.notes[Int.random(in: 0..<level.noteCount)]
                if !array.contains(note){
                    array.append(note)
                }
            }
            currentSequence = array
            sequencesRemaining = level.sequenceCount
        }
        timeRemaining = level.timer
        score = ScoreInstance()
        for i in level.notes{
            score.scorePerNote[i] = ScoreInstance.ScorePerNote()
        }
    }
    func reset(){
        onAppearActions()
        if level.isSequence{
            currentAnswersStatus = []
            currentAnswers = []
        }
    }
    func saveToDataModel(){
        level.updateMaxScoreAndNumberOfTries(with: rightAnswers)
        data.updateLevelInfo(with: level)
        isNextLevelUnlocked = data.unlockNextLevel(fromLevelWithID: level.id)
        data.saveData()
    }
    func shouldEndGame(check counter: Int){
        if counter == 0{
            saveToDataModel()
            isShowingSheet = true
        }
    }
    func shouldAnimateTimer(check time: Int){
        if !level.isSequence{
            if time < 10{
                withAnimation{
                    timerScaleEffect += 0.05
                }
            }else{
                timerScaleEffect = 0.25
            }
        }else{
            if time < 4{
                withAnimation{
                    timerScaleEffect += 0.05
                }
            }else{
                timerScaleEffect = 0.25
            }
        }
    }
    func shouldDispatchAnswers(check answers: [Int]){
        if answers.count == currentSequence.count{
            dispatchAnswersAndCreateNextSequence()
        }
    }
}


extension LevelView{
    func performActions(withCorrectNote correctNote: Note, status: AnswerStatus){
        switch status {
        case .Right:
            if !level.isSequence{
                hapticRightAnswer()
                answerAnimation = Image(systemName: "checkmark.circle.fill")
                answerAnimationColor = .green
            }
            score.scorePerNote[correctNote]!.right += 1
            level.updateStatistics(for: correctNote, status: .Right)
            if level.isSequence{
                currentAnswersStatus.append(true)
            }
        case .Wrong:
            if !level.isSequence{
                hapticWrongAnswer()
                answerAnimation = Image(systemName: "xmark.circle.fill")
                answerAnimationColor = .red
            }
            score.scorePerNote[correctNote]!.wrong += 1
            level.updateStatistics(for: correctNote, status: .Wrong)
            if level.isSequence{
                currentAnswersStatus.append(false)
            }
        }
        answerAnimationOpacity = 1
        if !level.isSequence{
            questionsRemaining -= 1
            solution = Int.random(in: 0..<level.noteCount)
        }
    }
    func judgeAnswerInMIDI(forNoteNumber number: Int, correctNote: Note?){
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
    func judge(answer: Int, correctNote: Note?){
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
}


extension LevelView{
    func storeAnswer(answer: Int){
        currentAnswers.append(answer)
    }
    func dispatchAnswersAndCreateNextSequence(){
        guard currentAnswers.count == currentSequence.count else{
            return
        }
        sequencesRemaining -= 1
        for (a, b) in zip(currentAnswers, currentSequence){
            if inputMethod == .Buttons{
                judge(answer: a, correctNote: b)
            }else if inputMethod == .MIDI{
                judgeAnswerInMIDI(forNoteNumber: a, correctNote: b)
            }
        }
        let startIndex = currentAnswersStatus.count - level.sequenceNoteCount
        let rightAnswers = Array(currentAnswersStatus[startIndex..<currentAnswersStatus.count]).reduce(0){ $1 == false ? $0 + 1 : $0}
        if shouldEndGameBasedOnPerformance(check: rightAnswers){
            return
        }
        createNextSequence()
    }
    func shouldEndGameBasedOnPerformance(check rightAnswers: Int)-> Bool{
        let percentage = Double(rightAnswers) / Double(level.sequenceNoteCount)
        if percentage >= 0.20{
            saveToDataModel()
            isShowingSheet = true
            return true
        }
        return false
    }
    func createNextSequence(){
        var array = [Note]()
        while array.count < level.sequenceNoteCount{
            let note = level.notes[Int.random(in: 0..<level.noteCount)]
            if !array.contains(note){
                array.append(note)
            }
        }
        currentSequence = array
        currentAnswers = []
        timeRemaining = level.timer
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
    func neutralHaptics(){
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else{
            return
        }
        var events = [CHHapticEvent]()
        let parameter1 : CHHapticEventParameter = .init(parameterID: .hapticIntensity, value: 1)
        let parameter2 : CHHapticEventParameter = .init(parameterID: .hapticSharpness, value: 1)
        let event : CHHapticEvent = .init(eventType: .hapticTransient, parameters: [parameter1, parameter2], relativeTime: 0.0)
        events.append(event)
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
        LevelView(id: UUID(), inputMethod: .Buttons, theme: .Dark)
    }
}


