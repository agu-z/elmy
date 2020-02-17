//
//  ContentView.swift
//
//  Created by Agustín Zubiaga on 2/13/20.
//  Copyright © 2020 Agustín Zubiaga. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    let content: String
    
    var body: some View {
        Text(self.content)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(content: "Test")
    }
}

