//
//  WebViewTests.swift
//  RecipesTests
//
//  Created by Craig Boyce on 3/16/25.
//

import Testing
import XCTest
import WebKit
@testable import Recipes

struct WebViewTests {
    
    @Test func testWebViewErrorHandling() {
        // Given a WebView with an error callback
        var errorCalled = false
        var receivedError: Error? = nil
        var receivedResponse: HTTPURLResponse? = nil
        
        let errorHandler: (Error, HTTPURLResponse?) -> Void = { error, response in
            errorCalled = true
            receivedError = error
            receivedResponse = response
        }
        
        // When a navigation error occurs
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotFindHost, userInfo: nil)
        
        // Simulate the WebView delegate method being called
        let coordinator = MockWebViewCoordinator(onError: errorHandler)
        coordinator.simulateNavigationError(error)
        
        // Then the error handler should be called with the correct parameters
        #expect(errorCalled == true)
        #expect(receivedError != nil)
        
        // And the error should be of the correct type
        if let nsError = receivedError as NSError? {
            #expect(nsError.domain == NSURLErrorDomain)
            #expect(nsError.code == NSURLErrorCannotFindHost)
        } else {
            XCTFail("Expected NSError")
        }
    }
    
    @Test func testWebView404ErrorHandling() {
        // Given a WebView with an error callback
        var errorCalled = false
        var receivedError: Error? = nil
        var receivedResponse: HTTPURLResponse? = nil
        
        let errorHandler: (Error, HTTPURLResponse?) -> Void = { error, response in
            errorCalled = true
            receivedError = error
            receivedResponse = response
        }
        
        // When a 404 error occurs
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorFileDoesNotExist, userInfo: nil)
        let response = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 404, httpVersion: nil, headerFields: nil)
        
        // Simulate the WebView delegate method being called
        let coordinator = MockWebViewCoordinator(onError: errorHandler)
        coordinator.simulateNavigationError(error, response: response)
        
        // Then the error handler should be called with the correct parameters
        #expect(errorCalled == true)
        #expect(receivedError != nil)
        #expect(receivedResponse != nil)
        #expect(receivedResponse?.statusCode == 404)
    }
}

// Mock class for testing
class MockWebViewCoordinator {
    let onError: (Error, HTTPURLResponse?) -> Void
    
    init(onError: @escaping (Error, HTTPURLResponse?) -> Void) {
        self.onError = onError
    }
    
    func simulateNavigationError(_ error: Error, response: HTTPURLResponse? = nil) {
        onError(error, response)
    }
}
