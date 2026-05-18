//
//  ContentView.swift
//  NexLingo
//
//  Created by 胖鱼头 on 2026/5/15.
//

import SwiftUI
import Observation

// MARK: - 视图模型 (ViewModel - 负责所有业务逻辑)
@Observable
@MainActor //确保所有跟UI相关的变量修改都在主线程进行
class MainViewModel {
    //界面绑定数据
    var inputText: String = ""
    var translatedText: String = String(localized: "翻译结果将显示在这里...")
    var targetLanguage: String = "English"
    var isLoading: Bool = false
    
    var isCasualTone: Bool = false
    
    //错误状态
    var errorMessage: String = ""
    var showError: Bool = false
    
    //支持的目标语言列表
    let languages = ["English", "中文", "日本語", "한국어", "Français", "Español", "Deutsch"]
    
    //MARK: - 动作方法
    ///执行翻译网络请求
    func translate() {
        //防止空内容或重复点击
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        isLoading = true
        //开启一个最新的异步任务（Task）
        Task {
            do {
                let result = try await ChatGPTService.shared.translate(text: inputText, targetLanguage: targetLanguage, isCasualTone: isCasualTone)
                self.translatedText = result
                self.isLoading = false
                
                //成功后加入手机轻微震动反馈（Haptic Feedback）
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            } catch let error as APIError {
                self.errorMessage = error.localizedDescription
                self.showError = true
                self.isLoading = false
            } catch {
                //捕捉未知错误
                self.errorMessage = String(localized: "发生了未知错误：\(error.localizedDescription)")
                self.showError = true
                self.isLoading = false
            }
        }
    }
    
    func clearInput() {
        inputText = ""
    }
    
    ///复制翻译结果到剪贴板
    func copyResult() {
        UIPasteboard.general.string = translatedText
        //加入震动反馈
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

//MARK: - 主界面视图（View - 纯粹负责展示）
struct ContentView: View {
    //实例化视图模型
    @State private var viewModel = MainViewModel()
    //控制页面弹出状态
    @State private var showSettings = false
    
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                //1.结果展示区
                ZStack(alignment: .topTrailing) {
                    ScrollView {
                        Text(viewModel.translatedText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .foregroundColor(viewModel.translatedText == String(localized: "翻译结果将显示在这里...") ? .secondary: .primary)
                    }
                    .frame(height: 220)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(16)
                    
                    Button(action: viewModel.copyResult) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.blue)
                            .padding()
                    }
                }
                
                //2.控制栏（语言选择器）
                HStack {
                    Text("翻译为：")
                        .font(.headline)
                    Picker("选择目标语言", selection: $viewModel.targetLanguage) {
                        ForEach(viewModel.languages, id: \.self) { language in
                            Text(language).tag(language)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.blue)
                        
                    Spacer()
                    
                    Toggle(isOn: $viewModel.isCasualTone) {
                        Text(viewModel.isCasualTone ? "口语" : "正式")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .fixedSize()
                }
                .padding(.horizontal, 5)
                
                //3.输入区
                ZStack(alignment: .bottomTrailing) {
                    TextEditor(text: $viewModel.inputText)
                        .frame(height: 220)
                        .padding(8)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(16)
                        .focused($isInputFocused)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                    
                    //一键清空
                    if !viewModel.inputText.isEmpty {
                        Button(action: viewModel.clearInput) {
                            Image(systemName: "trash")
                                .font(.system(size: 18))
                                .foregroundColor(.red)
                                .padding()
                        }
                    }
                }
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("完成") {
                            isInputFocused = false
                        }
                        .font(.headline)
                    }
                }
                
                Spacer()
                
                //4.翻译提交按钮
                Button(action: viewModel.translate) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                                .padding(.trailing, 8)
                        }
                        Text(viewModel.isLoading ? String(localized: "翻译中...") : String(localized: "开始翻译"))
                            .font(.title3.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.inputText.isEmpty || viewModel.isLoading ? Color.gray.opacity(0.5) : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                }
                .disabled(viewModel.inputText.isEmpty || viewModel.isLoading)
                .padding(.bottom, 10)
            }
            .padding()
            .onTapGesture {
                isInputFocused = false
            }
            .navigationTitle("NexLingo")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { showSettings = true }) { Image(systemName:"gearshape.fill")
                        }
                    }
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView()
                }
                .alert(isPresented: $viewModel.showError) {
                    Alert(
                        title: Text("提示"),
                        message: Text(viewModel.errorMessage),
                        dismissButton: .default(Text("我知道了"))
                    )
                }
        }
    }
}
 
#Preview("主界面") {
    ContentView()
}
