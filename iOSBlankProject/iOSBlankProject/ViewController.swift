//
//  ViewController.swift
//  iOSBlankProject
//
//  Created by vinicius.custodio on 04/05/22.
//

import UIKit

protocol ViewControllerProtocol: class {
    func failed(error: Error) // fieldEmpty / notNumber
    func presentFact(fact: String?)
}

class ViewController: UIViewController, ViewControllerProtocol {

    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var factLabel: UILabel!
    @IBOutlet weak var sendButton: UIButton!

    var viewModel: ViewModelProtocol = ViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        (self.viewModel as? ViewModel)?.viewController = self

        // Do any additional setup after loading the view.
    }


    @IBAction func didPressButton(_ sender: Any) {
        viewModel.sendNumber(number: textField.text)
    }

    func failed(error: Error) {

    }

    func presentFact(fact: String?) {
        factLabel.text = fact
    }

}

protocol ViewModelProtocol {
    func sendNumber(number: String?)
}
//
// numbersapi.com/42
// 42 is the number of little squares forming the left side trail of Microsoft's Windows 98 logo.

class ViewModel: ViewModelProtocol {

    weak var viewController: ViewControllerProtocol?
    var networkLayer: NetworkLayer = NetworkLayer()

    func sendNumber(number: String?) {
        guard let number = number else {
            viewController?.failed(error: NSError())
            return
        }

        guard let numberInt = Int(number) else {
            return
        }

        networkLayer.requestFact(number: numberInt) { result in
            switch result {
            case .success(let fact):
                self.viewController?.presentFact(fact: fact.text)

            case .failure:
                break
            }

        }
    }
}

class NetworkLayer {
    let api = "http://numbersapi.com"
    func get(number: Int,  completion: @escaping (Result<APIReturn, Error>) -> ()) {
        guard let url = URL(string: "\(self.api)/\(number)?json") else { return }

        let request = URLRequest(url: url)

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let data = data,
               let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                do {
                    let decoder = JSONDecoder()

                    let model: APIReturn = try decoder.decode(APIReturn.self, from: data)
                    DispatchQueue.main.async {
                        completion(.success(model))
                    }

                } catch {
                    print(error)
                    DispatchQueue.main.async {
//                        callback(.failure(GithubAPIError.decodingError))
                    }
                }
            } else {
                print(response, error)
                DispatchQueue.main.async {
//                    callback(.failure(GithubAPIError.requestError))
                }
            }

        }

        task.resume()
    }

    func requestFact(number: Int, completion: @escaping (Result<APIReturn, Error>) -> ()) {
        self.get(number: number, completion: completion)
    }
}

struct APIReturn: Decodable {
    let text: String?
    let number: Int
}
