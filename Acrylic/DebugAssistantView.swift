//
//  DebugAssistantView.swift
//  Acrylic
//
//  Created by Anthony Li on 4/7/23.
//

import SwiftUI

struct DebugAssistantView: View {
    @State var result: Result<Data, Error>?
    @State var tries = 0
    
    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch result {
                case .none:
                    ProgressView("Fetching...")
                case .success(let data):
                    if let str = String(data: data, encoding: .utf8) {
                        ScrollView {
                            Text(str)
                                .font(.body.monospaced())
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                                .padding()
                                .textSelection(.enabled)
                        }
                    } else {
                        Text("Couldn't decode data").padding()
                    }
                case .failure(let error):
                    Text("Error: \(error.localizedDescription)")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }.frame(maxHeight: .infinity)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Base Host: \(API.baseHost ?? "none")").textSelection(.enabled)
                    Text("Token: \(TokenStorage.retrieveSessionCookie() != nil ? "set" :  "not set")").textSelection(.enabled)
                }.frame(maxWidth: .infinity, alignment: .topLeading).padding()
            }.frame(height: 120)
            Divider()
            Button("Reload") {
                tries += 1
            }.padding().frame(maxWidth: .infinity, alignment: .leading)
        }
        .task(id: tries) {
            result = nil
            
            do {
                let request = API.request(for: URL(string: "https://\(API.baseHost ?? "")/api/v1/courses?per_page=100")!)
                let (data, _) = try await URLSession.shared.data(for: request)
                result = .success(data)
            } catch let e {
                result = .failure(e)
            }
        }
    }
}
