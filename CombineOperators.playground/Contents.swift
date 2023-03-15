import Combine
import Foundation
import UIKit

//https://github.com/hesperhu/CombineOperators/blob/main/CombineOperators.playground/Contents.swift

var subscriptions = Set<AnyCancellable>()



//switchToLatest可以处理最新的消息，取消没有处理完的消息 2023-03-15(Wed) 08:35:00
/* switchToLatest
This operator works with an upstream publisher of publishers, flattening the stream of elements to appear as if they were coming from a single stream of elements. It switches the inner publisher as new ones arrive but keeps the outer publisher constant for downstream subscribers.
 When this operator receives a new publisher from the upstream publisher, it cancels its previous subscription. Use this feature to prevent earlier publishers from performing unnecessary work, such as creating network request publishers from frequently updating user interface publishers.
 */
example(of: "switchToLatest -- networking") {
    let url = URL(string: "https://source.unsplash.com/random")!
    func getImage() -> AnyPublisher<UIImage?, Never> {
        URLSession.shared
            .dataTaskPublisher(for: url)
            .map { data, response in
                print(Date.now,"Network response:", response.suggestedFilename ?? " ")
                return UIImage(data: data)
            }
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }//用返回publisher的方式返回数据
    
    let taps = PassthroughSubject<Void, Never>()
    taps
        .map { _ in
            getImage() //这个转换func返回的是publisher
        } //map返回的是getImage func返回的publisher的publisher
        .switchToLatest()
        .compactMap({ image in
            image //unwrap optional
        })
        .sink { image in
            print(Date.now, "Image received: Size: ", image.size)
        }
        .store(in: &subscriptions)
    
    taps.send() //第一次获取图片，一般会成功处理，如果网络缓慢，会被第三次获取行为取消
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 5 ) {
        taps.send() //第二次获取图片，被0.1秒后的第三次获取的图片取消处理
    }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 5.1 ) {
        taps.send() //第三次获取图片，成功处理
    }
}
/*
 ——— Example of: switchToLatest -- networking ———
 2023-03-15 00:40:04 +0000 Network response: photo-1676807882792-1b47bbd603be.jpeg
 2023-03-15 00:40:04 +0000 Image received: Size:  (1080.0, 1620.0)
 2023-03-15 00:40:12 +0000 Network response: photo-1678297576263-b1be75fc72e3.jpeg
 2023-03-15 00:40:12 +0000 Image received: Size:  (1080.0, 1620.0)

 */


//switchToLatest用来处理多个消息队列中最新的的消息 2023-03-15(Wed) 08:01:01
example(of: "switchToLatest") {
    let publisher1 = PassthroughSubject<Int, Never>()
    let publisher2 = PassthroughSubject<Int, Never>()
    let publisher3 = PassthroughSubject<Int, Never>()
    
    let publishers = PassthroughSubject<PassthroughSubject<Int,Never>,Never>()
    
    publishers
        .switchToLatest() //切换到最新的消息队列中
        .sink { value in
            print("Complete: \(value)")
        } receiveValue: { value in
            print(value)
        }
        .store(in: &subscriptions)

    publishers.send(publisher1) //第一个消息队列激活
    publisher1.send(1)
    
    publishers.send(publisher2) //第二个消息队列激活
    publisher1.send(2) //第一个消息队列发送的消息被忽略
    publisher2.send(3) //第二个消息队列发送的消息被处理
    
    publishers.send(publisher3) //第三个消息队列激活
    publisher2.send(4) //第二个消息队列发送的消息被忽略
    publisher3.send(5) //第三个消息队列发送的消息被处理
    
    publisher3.send(completion: .finished)
    publishers.send(completion: .finished)
    
}
/*
 ——— Example of: switchToLatest ———
 1
 3
 5
 Complete: finished
 */

//使用append在队列之后补充信息 2023-03-15(Wed) 05:53:51
example(of: "append") {
    let numberPublisher = (3...5).publisher
    let publisher = PassthroughSubject<Int,Never>()
    let passthroughPublisher = PassthroughSubject<Int,Never>()
    
    numberPublisher
        .append(6,7) //补上具体的消息数据
        .append(8,9) //补上插入具体的消息数据
        .sink(receiveCompletion: { value in
            print("First append output number: \(value) \n")
        }, receiveValue: { value in
            print(value)
        })
        .store(in: &subscriptions)
    /*
     3
     4
     5
     6
     7
     8
     9
     First append output number: finished
     */
    
    publisher
        .append(3,4) //在手动publisher后面补上信息数据
        .sink(receiveCompletion: { value in
            print("Second append manual publisher output number: \(value) \n")
        }, receiveValue: { value in
            print(value)
        })
        .store(in: &subscriptions)
    publisher.send(1)
    publisher.send(2)
    publisher.send(completion: .finished)//发送完成之后，手动信息与补充的信息才发送
    /*
     1
     2
     3
     4
     Second append manual publisher output number: finished
     */
    
    
    numberPublisher
        .append([6,7]) //补充消息队列
        .append(Set(8...10)) //再次补充消息集合
        .sink(receiveCompletion: { value in
            print("Third append publisher number: \(value) \n")
        }, receiveValue: { value in
            print(value)
        })
        .store(in: &subscriptions)
    /*
     3
     4
     5
     6
     7
     10
     8
     9
     Third append publisher number: finished
     */
    
    
    numberPublisher
        .append([6,7].publisher) //补充消息队列的publisher
        .append(Set(8...9).publisher) //补充插入消息集合的publisher
        .sink(receiveCompletion: { value in
            print("Forth append publisher number: \(value) \n")
        }, receiveValue: { value in
            print(value)
        })
        .store(in: &subscriptions)
    /*
     3
     4
     5
     6
     7
     9
     8
     Forth append publisher number: finished
     */
    
    numberPublisher
        .append(passthroughPublisher) //补上手动消息队列
        .sink(receiveCompletion: { value in
            print("Fifth append publisher number: \(value) \n")
        }, receiveValue: { value in
            print(value)
        })
        .store(in: &subscriptions)
    
    passthroughPublisher.send(6)
    passthroughPublisher.send(7) //手动消息队列发送消息
    passthroughPublisher.send(completion: .finished) //发送完毕
    /*
     3
     4
     5
     6
     7
     Fifth append publisher number: finished
     */
    
}

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
