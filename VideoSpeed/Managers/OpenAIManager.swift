//
//  OpenAIManager.swift
//  VideoSpeed
//
//  Created by Oren Shalev on 31/08/2025.
//

import Alamofire
import Foundation

class OpenAIManager {
    static func transcribeAudio(fileURL: URL, apiKey: String, languageCode: String? ,completion: @escaping (Result<Transcription, Error>) -> Void) {
        let url = "https://api.openai.com/v1/audio/transcriptions"

        AF.upload(
            multipartFormData: { multipart in
                // Add model parameter
//                multipart.append(Data("gpt-4o-transcribe".utf8), withName: "model")
                multipart.append(Data("whisper-1".utf8), withName: "model")

                // Add file by URL (streamed, not loaded into memory)
                multipart.append(fileURL,
                                 withName: "file",
                                 fileName: fileURL.lastPathComponent,
                                 mimeType: "audio/mpeg")
                multipart.append("word".data(using: .utf8)!, withName: "timestamp_granularities[]")
                multipart.append("verbose_json".data(using: .utf8)!, withName: "response_format")
                if let languageCode {
                    multipart.append(Data(languageCode.utf8), withName: "language")  // force Hebrew
                }
            },
            to: url,
            method: .post,
            headers: [
                "Authorization": "Bearer \(apiKey)"

            ]            
        )
        .validate()
//        .responseJSON { response in
//            switch response.result {
//            case .success(let json):
//                print("JSON response:", json)
//
//                // If you want Dictionary:
//                if let dict = json as? [String: Any] {
//                    print("Parsed dict:", dict)
//                }
//                
//            case .failure(let error):
//                print("Upload failed:", error)
//            }
//        }
        .responseDecodable(of: TranscriptionResponse.self) { response in
            switch response.result {
            case .success(let transcriptionResponse):
                print("response text: \(transcriptionResponse.text)")
               
                do {
                    // For debugging purposes, saving the transcription data to save time sending transcription requests
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = .prettyPrinted

                    let jsonData = try encoder.encode(transcriptionResponse)
                    UserDefaults.standard.set(jsonData, forKey: "transcriptionResponse")
                   
                } catch  {
                    print("Error saving JSON data: \(error)")
                }

                if let transcription = Transcription(transcriptionResponse: transcriptionResponse) {
                    completion(.success(transcription))
                }
                else {
                    completion(.failure(NSError(domain: "transcription", code: 1, userInfo: [NSLocalizedDescriptionKey: "Couldn't initialine Transcription object"])))
                }
               case .failure(let error):
                   completion(.failure(error))
               }
           }
    }
    
    
    static func transcribeAudioAsync(fileURL: URL, apiKey: String, languageCode: String?) async -> Result<Transcription, Error> {
        
        return await withCheckedContinuation { continuation in
            transcribeAudio(fileURL: fileURL, apiKey: apiKey, languageCode: languageCode) { trascriptionResult in
                continuation.resume(returning: trascriptionResult)

            }
        }
      
    }
    
    
}
