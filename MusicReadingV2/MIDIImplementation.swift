//
//  MIDI.swift
//  MusicReading
//
//  Created by Luis Alfonso Contreras Maya on 13/10/22.
//

import Foundation
import MIDIKit

class MIDIModule: ObservableObject{
    var midiManager = MIDIManager(clientName: "MusicReadingMIDI", model: "MusicReading", manufacturer: "MusicCompany")
    @Published var midiEvent : MIDIEvent?
    var midiEventNoteNumber: Int?{
        guard midiEvent != nil else{
            return nil
        }
        switch midiEvent{
        case .noteOn(let noteOn):
            return Int(noteOn.note.number)
        default:
            return nil
        }
    }
    init(){
        do{
            try midiManager.start()
            try midiManager.addInputConnection(toOutputs: [], tag: "InputConnection", mode: .allEndpoints, filter: .owned() ,receiver: .events{events in
                DispatchQueue.main.async {
                    events.forEach{[weak self] event in
                        switch event{
                        case .noteOn(_):
                            self?.midiEvent = event
                        default:
                            print("Not a NoteOn message")
                        }
                    }
                }
            })
        }catch{
            print("MIDI Setup Error")
        }
    }
}

