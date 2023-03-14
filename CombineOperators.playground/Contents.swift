import UIKit
import Combine

var subscriptions = Set<AnyCancellable>()

//使用prepend在消息队列之前插入消息 2023-03-14(Tue) 21:39:58
example(of: "prepend") {
    let numberPublisher = (3...5).publisher
    let passthroughPublisher = PassthroughSubject<Int,Never>()
    numberPublisher
        .prepend(1,2) //插入具体的消息数据
        .prepend(-1,0) //再次插入具体的消息数据
        .sink(receiveCompletion: { value in
            print("First prepend output number: \(value) \n")
        }, receiveValue: { value in
            print(value)
        })
        .store(in: &subscriptions)
    /*
     -1
     0
     1
     2
     3
     4
     5
     First prepend output number: finished
     */
    numberPublisher
        .prepend([1,2]) //插入消息队列
        .prepend(Set(-2...0)) //再次插入消息集合
        .sink(receiveCompletion: { value in
            print("Second prepend sequence number: \(value) \n")
        }, receiveValue: { value in
            print(value)
        })
        .store(in: &subscriptions)
    /*
     -2
     -1
     0
     1
     2
     3
     4
     5
     Second prepend sequence number: finished
     */
    numberPublisher
        .prepend([1,2].publisher) //插入消息队列的publisher
        .prepend(Set(-2...0).publisher) //再次插入消息集合的publisher
        .sink(receiveCompletion: { value in
            print("Third prepend publisher number: \(value) \n")
        }, receiveValue: { value in
            print(value)
        })
        .store(in: &subscriptions)
    /*
     -1
     0
     -2
     1
     2
     3
     4
     5
     Third prepend publisher number: finished
     */
    
    numberPublisher
        .prepend(passthroughPublisher) //插入手动消息队列
        .sink(receiveCompletion: { value in
            print("Forth prepend publisher number: \(value) \n")
        }, receiveValue: { value in
            print(value)
        })
        .store(in: &subscriptions)
    
    passthroughPublisher.send(1)
    passthroughPublisher.send(2) //手动消息队列发送消息
    passthroughPublisher.send(completion: .finished) //发送完毕
    /*
     1
     2
     3
     4
     5
     Forth prepend publisher number: finished
     */
}

// Copyright (c) 2021 Razeware LLC
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
// distribute, sublicense, create a derivative work, and/or sell copies of the
// Software in any work that is designed, intended, or marketed for pedagogical or
// instructional purposes related to programming, coding, application development,
// or information technology.  Permission for such use, copying, modification,
// merger, publication, distribution, sublicensing, creation of derivative works,
// or sale is expressly withheld.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
