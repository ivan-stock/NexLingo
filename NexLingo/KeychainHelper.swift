//
//  KeychainHelper.swift
//  NexLingo
//
//  Created by 胖鱼头 on 2026/5/15.
//

import Foundation
import Security

///Keychain交互工具
class KeychainHelper {
    //创建实例
    static let shared = KeychainHelper()
    
    //Keychain中的存储名称
    private let account = "ChatGPTAPIKey"
    
    //获取APP的唯一标识符作为“服务”名称
    private let service = Bundle.main.bundleIdentifier ?? "com.NexLingo.service"
    
    //私有化初始方法，确保只通过KeychainHelper使用
    private init() {}
    
    ///保存API Key 到 Keychain
    ///- Parameter apiKey：用户输入的 API Key字符串
    func save(apiKey: String) {
        //1.转化字符串为Data格式
        let data = Data(apiKey.utf8)
        
        //2.配置Keychain查询字典
        let query = [
            kSecValueData: data, //要保存的数据
            kSecClass: kSecClassGenericPassword, //数据类型：通用密码
            kSecAttrService: service, //所属服务
            kSecAttrAccount: account, //账号标识
        ] as CFDictionary
        
        //3.保存前尝试删除旧的Key
        SecItemDelete(query)
        
        //4.将新Key存储至Keychain
        SecItemAdd(query, nil)
    }
    
    ///从Keychain中读取API Key
    ///- Returns: 如果保存过，返回字符串；如果没有，返回nil
    func read() -> String? {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true
        ] as CFDictionary
        
        var result: AnyObject?
        //在Keychain中执行搜索匹配
        SecItemCopyMatching(query, &result)
        //如果找到了数据，将其转换回字符串
        if let data = result as? Data{
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    ///从Keychain中彻底删除API Key
    func delete() {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ] as CFDictionary
        
        SecItemDelete(query)
    }
}
