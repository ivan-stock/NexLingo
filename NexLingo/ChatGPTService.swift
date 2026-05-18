//
//  ChatGPTService.swift
//  NexLingo
//
//  Created by 胖鱼头 on 2026/5/15.
//

import Foundation

///自定义错误类型，方便查错
enum APIError: Error, LocalizedError {
    case noAPIKey
    case invalidURL
    case networkError(String)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .noAPIKey: return String(localized: "请先在设置中填写并保存 API Key。")
        case .invalidURL: return String(localized: "请求的 URL 格式不正确。")
        case .networkError(let message): return String(localized: "网络错误：\(message)")
        case .decodingError: return String(localized: "解析翻译结果失败，请稍后再试。")
        }
    }
    
}

//MARK: - OpenAI API 数据模型
//这些结构体（Struct）对应了 ChatGPT要求的输入和输出数据格式
struct ChatRequest: Codable {
    let model: String
    let messages: [ChatMessage]
}

struct ChatMessage: Codable {
    let role: String
    let content: String
}

struct ChatResponse: Codable {
    let choices: [ChatChoice]
}

struct ChatChoice: Codable {
    let message: ChatMessage
}

//MARK: - 核心服务类
///专门负责与ChatGPT API进行网络通讯的类
class ChatGPTService {
    //单例模式
    static let shared = ChatGPTService()
    private init(){}
    
    ///发送翻译请求的异步方法
    ///- Parameters：
    /// - text: 需要翻译的原文
    /// - targetLanguage: 目标语言
    /// - isCasualTone: 是否为口语模式，默认false，口语模式
    ///- Returns:翻译后的文本字符串
    func translate(text: String, targetLanguage: String, isCasualTone: Bool = false) async throws -> String {
        //1.从Keychain中读取API Key
        guard let apiKey = KeychainHelper.shared.read(), !apiKey.isEmpty else {
            throw APIError.noAPIKey
        }
        
        //2.准备请求的网址（OpenAI的聊天接口）
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw APIError.invalidURL
        }
        
        //3.构建提示词（prompt）
        //System: 告诉ChatGPT它的角色是专业翻译器，并且要求它只返回翻译结果，不要说废话
        let promptText: String
        if isCasualTone {
            promptText = """
                        You are a highly expressive native speaker of \(targetLanguage). Your task is to localize the user's text for a casual messaging app (like WhatsApp or iMessage).
                        STRICT RULES:
                        1. SOUND NATIVE & PUNCHY: Use everyday vocabulary, natural phrasing, and appropriate text-message slang or contractions. Prioritize brevity.
                        2. CONVEY VIBE OVER STRUCTURE: Capture the exact emotion and core intent of the original text. You MUST break or completely rewrite the original sentence structure if it makes the output sound more natural in \(targetLanguage).
                        3. NO OVER-TRANSLATING: Keep it conversational. Do not sound like a dictionary.
                        4. OUTPUT FORMAT: Return ONLY the final translated text. No quotes, no explanations, no introductory filler.
                        """
        } else {
            promptText = """
                        You are an elite, professional translator and localization expert. Your task is to translate the user's text into elegant, flawless, and formal \(targetLanguage), suitable for business correspondence or official documents.
                        STRICT RULES:
                        1. DYNAMIC EQUIVALENCE: Translate the underlying intent, not the literal words. Completely adapt idioms, metaphors, and cultural nuances into professional standard phrasing in \(targetLanguage).
                        2. PROFESSIONAL TONE: Maintain a polite, objective, and sophisticated voice. Avoid colloquialisms, slang, and overly dramatic expressions.
                        3. NATIVE ELEGANCE: Ensure flawless grammar, smooth transitions, and high readability. Absolutely NO "machine-translation" flavor or rigid, robotic syntax.
                        4. OUTPUT FORMAT: Return ONLY the final translated text. No quotes, no explanations, no introductory filler.
                        """
        }
        let systemMessage = ChatMessage(role: "system", content: promptText)
        //User: 填入用户想翻译的文字
        let userMessage = ChatMessage(role: "user", content: "Translate this into \(targetLanguage):\n\n\(text)")
        
        //模型：gpt-4o-mini
        let requestBody = ChatRequest(model: "gpt-4o-mini", messages: [systemMessage, userMessage])
        //4.配置网络请求（URLRequest）
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        //将构建的结构体转为成网络传输需要的JSON数据
        request.httpBody = try? JSONEncoder().encode(requestBody)
        
        //5.发送请求并等待响应
        let (data, response) = try await URLSession.shared.data(for: request)
        
        //6.检查服务器返回状态码
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.networkError(String(localized: "请求被拒绝或网络异常，请检查 API Key是否有效。"))
        }
        
        //7.将服务器返回的 JSON 数据解析成Swift结构体
        do {
            let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
            //提取最终的翻译文字，并去除可能多余的换行符和空格
            if let translatedText = chatResponse.choices.first?.message.content {
                return translatedText.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                throw APIError.decodingError
            }
        } catch {
            throw APIError.decodingError
        }
    }
}
