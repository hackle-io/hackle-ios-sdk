//
//  DatabaseDDL.swift
//  Hackle
//
//  Created by sungwoo.yeo on 3/19/25.
//


/// DDL 버전 및 SQL 쿼리를 포함하는 구조체
struct DatabaseDDL {
    /// DDL 버전
    let version: Int32
    /// 실행할 쿼리 구문 리스트
    let statements: [String]
}
