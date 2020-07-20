# Combine support for Amplify for iOS

<img src="https://s3.amazonaws.com/aws-mobile-hub-images/aws-amplify-logo.png" alt="AWS Amplify" width="550" >

The default Amplify library for iOS supports iOS 11 and higher, and ships with APIs that return results on `Result` callbacks, as in:

```swift
Amplify.DataStore.save(Post(title: "My Post", content: "My content", ...), completion: { result in
    switch result {
        case .success:
            print("Post saved")
        case .failure(let dataStoreError):
            print("An error occurred saving the post: \(dataStoreError)")
    }
})
```

If your project declares platform support of iOS 13 or higher, Amplify also provides APIs that expose Combine publishers, which allow developers to use familiar Combine patterns, as in:

```swift
Amplify.DataStore.save(Post(title: "My Post", content: "My content", ...))
    .sink(
        receiveCompletion: { completion in
            if case .failure(let dataStoreError) = completion {
                print("An error occurred saving the post: \(dataStoreError)")
            }
        }, receiveValue: { value in
            print("Post saved")
        }
    )
```

While this doesn't save much for a single invocation, it provides great readability benefits when chaining asynchronous calls, since you can use standard Combine publishers to compose complex functionality into readable chunks:

```swift
subscription = Publishers.Zip(
    Amplify.DataStore.save(Person(name: "Rey")),
    Amplify.DataStore.save(Person(name: "Kylo"))
).flatMap { hero, villain in
    Amplify.DataStore.save(EpicBattle(hero: hero, villain: villain))
}.flatMap { battle in
    Publishers.Zip(
        Amplify.DataStore.save(
            Outcome(of: battle)
        ),
        Amplify.DataStore.save(
            Checkpoint()
        )
    )
}.sink(receiveCompletion: { completion in
    if case .failure(let dataStoreError) = completion {
        print("An error occurred during one of the preceding operations: \(dataStoreError)")
    }
}, receiveValue: { _ in
    print("Everything completed successfully")
})
```

Compared to nesting these dependent calls in callbacks, this provides a much more readable pattern.

**NOTE**: Remember that Combine publishers do not retain `sink` subscriptions, so you must maintain a reference to the subscription in your code, such as in an instance variable of the enclosing type:

```swift
struct MyAppCode {
    var subscription AnyCancellable?

    ...

    func doSomething() {
        // Subscription is retained by the `self.subscription` instance
        // variable, so the `sink` code will be executed
        subscription = Amplify.DataStore.save(Person(name: "Rey"))
            .sink(...)
    }
}
```

## Installation

There is no additional work needed to enable Combine support. Projects that declare a deployment target of iOS 13.0 or higher will automatically see the appropriate method signatures or properties, depending on the Category you are using.

## API Comparison: APIs that return operations vs. listener-only APIs

Amplify strives to provide a consistent interface for APIs that expose Combine functionality by overloading the no-Combine API signature, minus the result callbacks. Thus, `Amplify.DataStore.save(_:where:completion:)` has an equivalent Combine-supporting API of `Amplify.DataStore.save(_:where:)`. Similarly, the Result callback `Success` and `Failure` types in standard Amplify APIs translate exactly to the `Output` and `Failure` types of `AnyPublisher`s returned from Combine-supporting APIs.

The way to get to Combine support for a given API varies depending on whether the asynchronous work can be cancelled or not:

- APIs that **do not** return an operation simply return a Combine `AnyPublisher` directly from the API call:
    ```swift
    let publisher = Amplify.DataStore.save(myPost)
    ```
- APIs that **do** return an operation for cancellability expose a `resultPublisher` property on the returned operation
    ```swift
    let publisher = Amplify.Predictions.convert(textToSpeech: text, options: options).resultPublisher
    ```
- APIs that return an operation and also accept an **in-process listener** expose both a `resultPublisher` and an `inProcessPublisher`:
    ```swift
    let uploadOperation = Amplify.Storage.uploadFile(key: fileNameKey, local: filename)
    let resultPublisher = uploadOperation.resultPublisher
    let progressPublisher = uploadOperation.inProcessPublisher
    ```

While this asymmetry increases the mental overhead of learning to Amplify with Combine, the ease of use at the call site should make up for the additional learning curve.

### Cancelling operations

Most Amplify APIs return a use-case specific Operation that you may use to cancel an in-progress operation. The Combine flavors of those APIs simply extend those operations with a `resultPublisher` and (if the API supports it) an `inProcessPublisher`.

Canceling a subscription to a publisher simply releases that publisher, but does not affect the work in the underlying operation. For example, say you start a file upload on a view in your app:

```swift
import Combine

class MyView: UIView {

// Declare instance properties to retain the operation and subscription cancellables
var uploadOperation: StorageUploadFileOperation?
var resultSink: AnyCancellable?
var progressSink: AnyCancellable?

// Then when you start the operation, assign those instance properties
func uploadFile() {
    uploadOperation = Amplify.Storage.uploadFile(key: fileNameKey, local: filename)

    resultSink = uploadOperation
        .resultPublisher
        .sink(
            receiveCompletion: { completion in
                if case .failure(let storageError) = completion {
                    handleUploadError(storageError)
                }
            }, receiveValue: { print("File successfully uploaded: \($0)") }
        )

    progressSink = uploadOperation
        .inProcessPublisher
        .sink{ print("\($0.fractionCompleted * 100)% completed") }
}
```

After you call `uploadFile()` as above, your containing class retains a reference to the operation that is actually performing the upload, as well as Combine `AnyCancellable`s that can be used to stop receiving result and progress events.

To cancel the upload (for example, in response to the user pressing a **Cancel** button), you simply call `cancel()` on the upload operation:

```swift
func cancelUpload() {
    // Automatically sends a completion to `resultPublisher` and `inProcessPublisher`
    uploadOperation.cancel()
}
```

If you navigate away from `MyView`, the `uploadOperation`, `resultSink`, and `progressSink` instance variables will be released, and you will no longer receive progress or result updates on those sinks, but Amplify will continue to process the upload operation.
