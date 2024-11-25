//
//  ContentView.swift
//  hedera-sdk-swift-examples
//
//  Created by Tom Bolton on 25/11/2024.
//

import SwiftUI
import Hedera

struct HederaAccountInfo {
    var accountId: AccountId
    var privateKey: PrivateKey
    var publicKey: PublicKey
}

// TODO: create inputs / use env vars
func getAccountDetails() -> HederaAccountInfo {
    return HederaAccountInfo(
        accountId: "",
        privateKey: "",
        publicKey: "")
}

func initClient(account: HederaAccountInfo) -> Client {
    let client = Client.forTestnet()
    client.setOperator(account.accountId, account.privateKey)
    return client
}

func createFile(client: Client, account: HederaAccountInfo, fileContents: String) async -> String {
    do {
        let response = try await FileCreateTransaction()
            .keys([.single(account.publicKey)])
            .contents(fileContents.data(using: .utf8)!)
            .maxTransactionFee(2)
            .execute(client)

        let receipt = try await response.getReceipt(client)

        let id = receipt.fileId?.toString() ?? "could not get fileId"
        print("file: \(id)")
        return id
    } catch let error {
        print("Error creating file: \(error.localizedDescription)")
        return "Error creating file"
    }
}

func getFileContent(client: Client, account: HederaAccountInfo, fileId: FileId) async -> String {
    do {
        let response = try await FileContentsQuery()
            .fileId(fileId)
            .execute(client)
        
        let text = String(data: response.contents, encoding: .utf8) ?? "File not found"
        
        print("File contents = \(text)")
        return text
    } catch let error {
        print("Error getting file: \(error)")
        return ""
    }
}

func getAccountBalance(account: HederaAccountInfo, client: Client) async {
    do {
        let balance = try await AccountBalanceQuery()
            .accountId(account.accountId)
            .execute(client)

        print("balance = \(balance)")
    } catch let error {
        print("Error getting balance for account: \(account.accountId): \(error)")
    }
}

struct ContentView: View {
    @State private var client: Client?
    @State private var accountId = ""
    @State private var publicKey = ""
    @State private var privateKey = ""
    
    @State private var newFileContent = ""
    @State private var createButtonDisabled = false
    @State private var createdFileId = ""
    
    @State private var getButtonDisabled = false
    @State private var fileId = ""
    @State private var fileContents = ""
    
    var body: some View {
        VStack {
            Text("New File Content:")
                .foregroundStyle(.white)
            
            TextField("File Content", text: $newFileContent)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.white, lineWidth: 2)
                )
                .foregroundStyle(.white)
                .padding([.leading, .trailing], 60)
            
            Button("Create File") {
                createButtonDisabled = true
                Task {
                    guard let hederaClient = client else {
                        print("Client is nil, unable to create file")
                        return
                    }
                    let account = getAccountDetails()
                    createdFileId = await createFile(client: hederaClient, account: account, fileContents: newFileContent)
                    await getAccountBalance(account: account, client: hederaClient)
                    createButtonDisabled = false
                }
            }
            
            Text("New fileId: \(createdFileId)")
                .foregroundStyle(.white)
            
            Spacer()
                .frame(height: 60)
            
            Text("File Id:")
                .foregroundStyle(.white)
            
            TextField("File Id", text: $fileId)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.white, lineWidth: 2)
                )
                .foregroundStyle(.white)
                .padding([.leading, .trailing], 60)
            
            Button("Get File") {
                getButtonDisabled = true
                Task {
                    guard let hederaClient = client else {
                        print("Client is nil, unable to get file")
                        return
                    }
                    let account = getAccountDetails()
                    fileContents = await getFileContent(client: hederaClient, account: account, fileId: FileId(stringLiteral: fileId))
                    await getAccountBalance(account: account, client: hederaClient)
                    getButtonDisabled = false
                }
            }
            Text("File contents: \(fileContents)")
                .foregroundStyle(.white)
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .background(.black)
        .edgesIgnoringSafeArea(.all)
        .task {
            client = initClient(account: getAccountDetails())
        }
    }
}

#Preview {
    ContentView()
}
