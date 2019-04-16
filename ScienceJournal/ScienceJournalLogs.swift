/*
 *  Copyright 2019 Google LLC. All Rights Reserved.
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

import os

/// Categories to differentiate console logs.
public enum ScienceJournalLogCategory: String {
  /// A category for Core Data logs.
  case coreData
  /// A category for Drive sync logs.
  case drive
  /// A category for Drive API request/response logs.
  case driveAPI
  /// A category for Science Journal server logs.
  case server
  /// A catch-all category.
  case general
}

/// Logs an informational message.
///
/// - Parameters:
///   - message: A string message.
///   - category: The Science Journal category.
///   - file: The file that called this function, populated by default.
public func sjlog_info(_ message: String,
                       category: ScienceJournalLogCategory,
                       file: String = #file) {
  sjlog(message, category: category, file: file, type: .info)
}

/// Logs an error message.
///
/// - Parameters:
///   - message: A string message.
///   - category: The Science Journal category.
///   - file: The file that called this function, populated by default.
public func sjlog_error(_ message: String,
                        category: ScienceJournalLogCategory,
                        file: String = #file) {
  sjlog(message, category: category, file: file, type: .error)
}

/// Logs a debug message.
///
/// - Parameters:
///   - message: A string message.
///   - category: The Science Journal category.
///   - file: The file that called this function, populated by default.
public func sjlog_debug(_ message: String,
                        category: ScienceJournalLogCategory,
                        file: String = #file) {
  sjlog(message, category: category, file: file, type: .debug)
}

/// Logs a fault message. Use only for fatal errors.
///
/// - Parameters:
///   - message: A string message.
///   - category: The Science Journal category.
///   - file: The file that called this function, populated by default.
public func sjlog_fault(_ message: String,
                        category: ScienceJournalLogCategory,
                        file: String = #file) {
  sjlog(message, category: category, file: file, type: .fault)
}

/// A base log function used by the other log functions. Outputs a log that includes the class
/// name of the file that called the log function.
///
/// - Parameters:
///   - message: A string message.
///   - category: The Science Journal category.
///   - file: The file that called this function, populated by default.
///   - type: The OS Log type.
fileprivate func sjlog(_ message: String,
                       category: ScienceJournalLogCategory,
                       file: String,
                       type: OSLogType) {
  let log = OSLog(subsystem: "com.google.ScienceJournal.app", category: category.rawValue)
  let className = String(file.split(separator: "/").last ?? "Unknown")
  os_log("[%@] %@", log: log, type: type, className, message)
}
