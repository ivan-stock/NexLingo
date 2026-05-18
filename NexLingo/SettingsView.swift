//
//  SettingsView.swift
//  NexLingo
//
//  Created by 胖鱼头 on 2026/5/15.
//

import SwiftUI

struct SettingsView: View {
    @State private var apiKeyInput: String = ""
    @State private var showSuccessAlert: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                //1. API: 配置
                Section {
                    SecureField("请输入 ChatGPT API Key （sk-...）", text: $apiKeyInput)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                } header: {
                    Text("API 设置")
                } footer: {
                    Text("您的 API Key 将使用最高安全级别加密存储在您设备的 Keychain （钥匙串）中，绝不会上传至任何服务器。")
                }
                
                //2. 保存按钮
                Section {
                    Button(action: saveKeyToKeychain) {
                        Text("保存并应用")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundColor(apiKeyInput.isEmpty ? .gray : .blue)
                    }
                    .disabled(apiKeyInput.isEmpty)
                }
                
                //3.隐私政策与使用说明
                Section {
                    Link(destination: URL(string: "https://ivan-stock.github.io/NexLingo/privacy.html")!) {
                        HStack {
                            Text("隐私政策")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.forward.app")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://ivan-stock.github.io/NexLingo/guide.html")!) {
                        HStack {
                            Text("使用说明")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.forward.app")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                } header: {
                    Text("支持与法律")
                }
            }
            .navigationTitle("设置")
            //当这个页面出现时，检查一下是否已经保存过 Key
            .onAppear {
                loadExistingKey()
            }
            //弹窗提示，当showSuccessAlert变成true时弹出
            .alert(isPresented: $showSuccessAlert) {
                Alert(
                    title: Text("保存成功"),
                    message: Text("您的 API Key 已经安全存储"),
                    dismissButton: .default(Text("好的"))
                )
            }
        }
    }
    
    //MARK: - 逻辑方法
    ///读取已经保存的Key
    private func loadExistingKey() {
        if let savedKey = KeychainHelper.shared.read() {
            //如果读取到就赋值给输入框，为了测试方便，暂时显示出来
            apiKeyInput = savedKey
        }
    }
    
    private func saveKeyToKeychain() {
        KeychainHelper.shared.save(apiKey: apiKeyInput)
        showSuccessAlert = true
    }
}

#Preview("设置界面预览") {
    SettingsView()
}

