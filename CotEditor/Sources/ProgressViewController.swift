//
//  ProgressViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-06-07.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2020 1024jp
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  https://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Combine
import Cocoa

final class ProgressViewController: NSViewController {
    
    // MARK: Public Properties
    
    var closesAutomatically = true
    
    
    // MARK: Private Properties
    
    @objc private dynamic var progress: Progress?
    @objc private dynamic var message: String = ""
    
    private var progressSubscriptions: Set<AnyCancellable> = []
    private var completionSubscriptions: Set<AnyCancellable> = []
    
    @IBOutlet private weak var indicator: NSProgressIndicator?
    @IBOutlet private weak var descriptionField: NSTextField?
    @IBOutlet private weak var button: NSButton?
    
    
    
    // MARK: -
    // MARK: View Controller Methods
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        guard
            let progress = self.progress,
            let indicator = self.indicator,
            let descriptionField = self.descriptionField
            else { return assertionFailure() }
        
        self.progressSubscriptions.removeAll()
        
        progress.publisher(for: \.fractionCompleted, options: .initial)
            .throttle(for: 0.2, scheduler: DispatchQueue.main, latest: true)
            .assign(to: \.doubleValue, on: indicator)
            .store(in: &self.progressSubscriptions)
        
        progress.publisher(for: \.localizedDescription, options: .initial)
            .throttle(for: 0.1, scheduler: DispatchQueue.main, latest: true)
            .assign(to: \.stringValue, on: descriptionField)
            .store(in: &self.progressSubscriptions)
    }
    
    
    override func viewDidDisappear() {
        
        super.viewDidDisappear()
        
        self.progressSubscriptions.removeAll()
    }
    
    
    
    // MARK: Public Methods
    
    /// Initialize view with given progress instance.
    /// - Parameters:
    ///   - progress: The progress instance to indicate.
    ///   - message: The text to display as the message label of the indicator.
    func setup(progress: Progress, message: String) {
        
        assert(self.progress == nil)
        
        self.progress = progress
        self.message = message
        
        progress.publisher(for: \.isFinished, options: .initial)
            .filter { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.done() }
            .store(in: &self.completionSubscriptions)
        
        progress.publisher(for: \.isCancelled, options: .initial)
            .filter { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.dismiss(nil) }
            .store(in: &self.completionSubscriptions)
    }
    
    
    /// Change the state of progress to finished.
    func done() {
        
        if self.closesAutomatically {
            return self.dismiss(self)
        }
        
        guard let button = self.button else { return assertionFailure() }
        
        if let progress = self.progress {
            self.descriptionField?.stringValue = progress.localizedDescription
        }
        
        button.title = "OK".localized
        button.action = #selector(dismiss(_:) as (Any?) -> Void)
        button.keyEquivalent = "\r"
    }
    
    
    
    // MARK: Actions
    
    /// Cancel current process.
    @IBAction func cancel(_ sender: Any?) {
        
        self.progress?.cancel()
    }
    
}
