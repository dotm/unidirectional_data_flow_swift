//: A UIKit based Playground for presenting user interface
  
import UIKit
import PlaygroundSupport

typealias UserData = (username: String, email: String)

enum UserDataStore {                                //Using enum to create namespace/module
    private static var state: [UserData] = [(username:"example1", email:"example1@yopmail.com")] {
        //State can only be set from dispatch(action:) method
        didSet {
            print(state)    //log state for debugging
            
            //notify all observers
            observers.forEach { (observer) in
                observer.handle_userStateChange(newState: state)
            }
        }
    }
    static var getState: [UserData] {return state}  //enum (as namespace) can only have static variable
    
    static func dispatch(action: UserDataStore.Action){
        //Dispatch only accepts predefined Action which provides better control on state change
        state = reducer(previousState: state, action: action)
    }
    enum Action {
        case addUser(data: UserData)    //enum case can store associated value (in this case: data)
        case removeAllUser
    }
    private static func reducer(previousState: [UserData], action: UserDataStore.Action) -> [UserData] {
        switch action {
        case let .addUser(data):        //We use pattern matching to get the associated value of an enumeration case
            let newState = previousState + [data]
            return newState
        case .removeAllUser:
            return []
        }
    }
    
    //Create Observer design pattern manually
    private static var observers: [UserDataStoreObserver] = []
    static func subscribe(_ observer: UserDataStoreObserver){
        observers.append(observer)
    }
    static func unsubscribe(_ removedObserver: UserDataStoreObserver){
        let observers_withoutRemovedObserver = observers.filter { (observer) -> Bool in
            return (observer as AnyObject) !== (removedObserver as AnyObject)
        }
        observers = observers_withoutRemovedObserver
    }
}

protocol UserDataStoreObserver {
    func handle_userStateChange(newState: [UserData])
}
class MyViewController : UIViewController, UserDataStoreObserver {
    //MARK: Outlets
    private weak var stackView: UIStackView!
    
    override func viewDidAppear(_ animated: Bool) {
        //Make view controller subscribed to state changes from store
        UserDataStore.subscribe(self)
        
        displayUserData(UserDataStore.getState)
        getFreshUserData_fromDB_afterTimerDelay()
    }
    override func viewDidDisappear(_ animated: Bool) {
        UserDataStore.unsubscribe(self)
    }
    
    //Dispatch method can be called by UI or system (e.g. scheduler)
    @objc private func removeAllUsers(){
        UserDataStore.dispatch(action: .removeAllUser)
    }
    private func getFreshUserData_fromDB_afterTimerDelay(){
        Timer.scheduledTimer(withTimeInterval: 4, repeats: false) { (_) in
            UserDataStore.dispatch(action: .addUser(data: (username: "joe", email: "joe@yopmail.com")))
            UserDataStore.dispatch(action: .addUser(data: (username: "jose", email: "jose@yopmail.com")))
        }
    }
    
    private func displayUserData(_ users: [UserData]){
        clearStackView()
        populateStackView(users: users)
    }
    //UI should be changed only when the state of the store changed
    func handle_userStateChange(newState: [UserData]){
        displayUserData(newState)
    }
    
    //Extra Details
    private func populateStackView(users: [UserData]){
        users.forEach { (user) in
            let label = createUserLabel(text: "\(user.username) (\(user.email))")
            stackView.addArrangedSubview(label)
        }
    }
    private func createUserLabel(text: String) -> UILabel{
        let label = UILabel()
        label.text = text
        label.textAlignment = .center
        label.backgroundColor = UIColor.cyan
        label.layer.borderColor = UIColor.blue.cgColor
        label.layer.borderWidth = CGFloat(1)
        
        return label
    }
    private func clearStackView(){
        stackView.subviews.forEach { (subview) in
            subview.removeFromSuperview()
        }
    }
    override func loadView() {
        let view = UIView()
        view.backgroundColor = .white
        self.view = view
        
        setupRemoveAllUserButton()
        setupStackView()
    }
    private func setupRemoveAllUserButton(){
        let button = UIButton()
        button.setTitle("Remove All Users", for: .normal)
        button.addTarget(self, action: #selector(removeAllUsers), for: .touchUpInside)
        button.backgroundColor = UIColor.red
        view.addSubview(button)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.topAnchor.constraint(equalTo: view.topAnchor, constant: 10).isActive = true
        button.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5).isActive = true
        button.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }
    private func setupStackView(){
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = CGFloat(3)
        view.addSubview(stackView)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9).isActive = true
        stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 50).isActive = true
        stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        self.stackView = stackView
    }
    deinit {
        print("view controller object removed from existence")
    }
}

// Present the view controller in the Live View window
PlaygroundPage.current.liveView = MyViewController()
Timer.scheduledTimer(withTimeInterval: 15, repeats: false) { (_) in
    PlaygroundPage.current.liveView = nil
}
