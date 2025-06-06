//
//  ChatTextDisplayView.swift
//  Offroad-iOS
//
//  Created by 김민성 on 2/9/25.
//

import UIKit

import Lottie
import RxSwift
import RxCocoa
import SnapKit

public class ChatTextDisplayView: UIView {
    
    //MARK: - Properties
    
    private let userChatDisplayViewHeightAnimator = UIViewPropertyAnimator(duration: 0.3, dampingRatio: 1)
    private let showingAnimator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 1)
    private let hidingAnimator = UIViewPropertyAnimator(duration: 0.3, dampingRatio: 1)
    
    private var disposeBag = DisposeBag()
    private var displayTextRelay = BehaviorRelay<String>(value: "")
    
    private lazy var userChatDisplayViewHeightConstraint = userChatDisplayView.heightAnchor.constraint(equalToConstant: 24)
    
    //MARK: - UI Properties
    
    private let meLabel = UILabel()
    private let loadingAnimationView = LottieAnimationView(name: "loading2")
    private let userChatDisplayView = UITextView()
    
    //MARK: - Life Cycle
    
    init() {
        super.init(frame: .zero)
        
        setupStyle()
        setupHierarchy()
        setupLayout()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

//MARK: - Private Extensions

private extension ChatTextDisplayView {
    
    //MARK: - Layout Func
    
    private func setupLayout() {
        meLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        meLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(16)
            make.leading.equalToSuperview().inset(38)
        }
        
        loadingAnimationView.snp.makeConstraints { make in
            make.centerY.equalTo(meLabel)
            make.leading.equalTo(meLabel).offset(4.2)
            make.height.equalTo(50)
            make.width.equalTo(100)
        }
        
        userChatDisplayView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        userChatDisplayViewHeightConstraint.isActive = true
        userChatDisplayView.snp.makeConstraints { make in
            make.top.equalTo(meLabel)
            make.leading.equalTo(meLabel.snp.trailing).offset(10)
            make.trailing.equalToSuperview().inset(24)
            make.bottom.equalToSuperview()
        }
    }
    
    //MARK: - Private Func
    
    private func setupStyle() {
        backgroundColor = .primary(.white)
        
        meLabel.do { label in
            label.textColor = .main(.main2)
            label.font = .pretendardFont(ofSize: 16, weight: .regular)
            label.text = "나 :"
            label.highlightText(targetText: " ", font: .pretendardFont(ofSize: 16, weight: .medium))
            label.highlightText(targetText: "나", font: .pretendardFont(ofSize: 16, weight: .bold))
            label.setLineHeight(percentage: 150)
        }
        
        loadingAnimationView.do { animationView in
            animationView.isHidden = true
            animationView.contentMode = .scaleAspectFit
            animationView.loopMode = .loop
        }
        
        userChatDisplayView.do { textView in
            textView.textColor = .main(.main2)
            textView.font = .offroad(style: .iosText)
            textView.backgroundColor = .clear
            textView.isSelectable = false
            textView.textContainerInset = .zero
            textView.textContainer.lineFragmentPadding = 0
            textView.indicatorStyle = .black
        }
    }
    
    private func setupHierarchy() {
        addSubviews(meLabel, userChatDisplayView, loadingAnimationView)
    }
    
    private func setupActions() {
        userChatDisplayView.rx.text.orEmpty.subscribe(onNext: { [weak self] displayText in
            guard let self else { return }
            self.updateChatDisplayViewHeight(
                height: self.userChatDisplayView.textInputView.frame.height
            )
        }).disposed(by: disposeBag)
        
        displayTextRelay.subscribe(onNext: { [weak self] displayText in
            guard let self else { return }
            self.stopDisplayLoading()
            self.userChatDisplayView.text = displayText
            // userChatDisplayView에 텍스트를 띄울 때 아래에서 올라오도록 구현
            self.userChatDisplayView.bounds.origin.y = -(self.bounds.height)
            UIView.animate(
                withDuration: 0.3,
                delay: 0,
                usingSpringWithDamping: 1,
                initialSpringVelocity: 1
            ) { [weak self] in
                self?.userChatDisplayView.bounds.origin.y = 0
                self?.layoutIfNeeded()
            }
        }).disposed(by: disposeBag)
    }
    
    private func updateChatDisplayViewHeight(height: CGFloat, animated: Bool = true) {
        userChatDisplayViewHeightAnimator.stopAnimation(true)
        userChatDisplayViewHeightAnimator.addAnimations { [weak self] in
            self?.userChatDisplayViewHeightConstraint.constant = height >= 30 ? 40 : 20
            self?.superview?.layoutIfNeeded()
        }
        userChatDisplayViewHeightAnimator.startAnimation()
    }
    
}

//MARK: - Public Extensions

public extension ChatTextDisplayView {
    
    //MARK: - Func
    
    
    /// 표시창에 주어진 텍스트를 표시함.
    /// 표시창에 텍스트를 띄울 때 아래에서 올라오는 애니메이션이 적용됨.
    /// - Parameter text: 표시할 텍스트
    func display(text: String) {
        displayTextRelay.accept(text)
    }
    
    /// 현재 표시중이 텍스트를 가리고 로딩 애니메이션을 띄움
    func startDisplayLoading() {
        userChatDisplayView.isHidden = true
        userChatDisplayView.text = ""
        loadingAnimationView.isHidden = false
        loadingAnimationView.play()
    }
    
    /// 현재 로딩중인 애니메이션을 중지 및 숨기고 기존에 표시되었던 텍스트를 표시.
    /// 이 때에는 아래에서 위로 올라오는 애니메이션이 적용되지 않음.
    func stopDisplayLoading() {
        loadingAnimationView.currentProgress = 0
        loadingAnimationView.pause()
        loadingAnimationView.isHidden = true
        userChatDisplayView.text = displayTextRelay.value
        userChatDisplayView.isHidden = false
    }
    
    /// 화면에 표시창을 나타내는 함수. `animated` 매개변수에 `true`를 할당할 경우, fade-in 애니메이션이 적용됨.
    /// - Parameter animated: fade-in 애니메이션 적용 여부
    func show(animated: Bool = true) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.hidingAnimator.stopAnimation(true)
            self.showingAnimator.stopAnimation(true)
            if animated {
                self.showingAnimator.addAnimations { [weak self] in self?.alpha = 1 }
                self.showingAnimator.startAnimation()
            } else {
                self.alpha = 1
            }
        }
    }
    
    /// 화면에서 표시창을 숨기는 함수.
    /// - Parameters:
    ///   - erase: 화면에서 숨겨진 후 표시하고 있던 텍스트를 제거할 지 여부. `true`를 할당하면 완전히 숨겨진 후 텍스트를 지우고, `false`를 할당하면 숨겨진 후에도 텍스트를 유지하여 다음 표시 때 텍스트를 여전히 띄움.
    ///   - animated: 숨겨질 때 fade-out 애니메이션을 적용할 지 여부.
    ///   - completion: 숨겨진 후 실행할 콜백 함수. 매개변수가 없는 클로저 타입임.
    func hide(erase: Bool = false, animated: Bool = true, completion: (() -> Void)? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.showingAnimator.stopAnimation(true)
            self.hidingAnimator.stopAnimation(true)
            if animated {
                hidingAnimator.addAnimations { [weak self] in self?.alpha = 0 }
                hidingAnimator.addCompletion { [weak self] _ in
                    if erase { self?.displayTextRelay.accept("") }
                    completion?()
                }
                hidingAnimator.startAnimation()
            } else {
                if erase { displayTextRelay.accept("") }
                self.alpha = 0
            }
        }
    }
    
}
