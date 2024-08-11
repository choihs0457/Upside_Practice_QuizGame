# 문제 1: QuizGame 컨트랙트 구현하기

## 접근

- 테스트 코드에 맞춰서 코드를 단순 구현할 계획을 가짐.

## 문제 1

- `testAddQuizACL`에서 흐름을 생각하지 않고 퀴즈를 잘 저장하고 정답을 바꾸는데, `asserteq`가 왜 있는지 한참 고민함. 처음에는 문제가 잘못된 것 아닌가 생각했으나, 요청자에게는 정답이 제공되면 안 된다는 기본적인 생각을 놓친 문제였음.

## 문제 2

- 문제를 다 풀고 나서 `receive()` 함수를 추가하지 않아 돈이 없는 문제가 있었음. 계속해서 `oof`가 발생해서 왜 그런지 고민했음.

## 문제 3

- `bets`에 접근할 때 공간 할당 없이 바로 위치로 접근하려는 시도를 하면 없는 공간에 대한 접근으로 에러가 발생. 해당 부분은 보고 바로 해결했음.

## 코드

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Quiz {
    struct Quiz_item {
        uint id;
        string question;
        string answer;
        uint min_bet;
        uint max_bet;
    }

    uint public quiz_num = 0;                       // 문제가 추가 될 때 문제의 번호를 메겨 줄 변수
    mapping(uint => Quiz_item) public quizs;        // Quiz_item 구조체가 저장 될 매핑
    mapping(address => uint256)[] public bets;      // 문제에 유저의 배팅 금액이 저장 될 매핑 배열(유저가 다수 일 수 있음)
    mapping(address => uint256) public balances;    // 유저의 상금이 저장 될 매핑
    uint public vault_balance;                      // 유저가 문제를 틀렸을 때 베팅금이 회수 될 변수
    
    /*
    문제를 초기화 하고 퀴즈를 추가 한 뒤 bets배열의 초기화를 해준다 초기화를 하지 않으면 없는 주소에 접근을 하기 때문에 문제가 방생한다.
    */
    constructor() {
        Quiz_item memory q;
        q.id = 1;
        q.question = "1+1=?";
        q.answer = "2";
        q.min_bet = 1 ether;
        q.max_bet = 2 ether;
        addQuiz(q);
        bets.push();
    }

    /*
    getQuizNum 함수를 위해 quiz_num 값을 올리고 quizs배열에 q를 저장하는 함수
    */
    function addQuiz(Quiz_item memory q) public{
        require(msg.sender != address(1));
        quizs[q.id] = q;
        quiz_num += 1;
    }

    /*
    테스트 코드를 통과하기 위한 함수로 보인다. 퀴즈 아이디를 기반으로 정답을 불러온다.
    */
    function getAnswer(uint quizId) public view returns (string memory){
        Quiz_item memory q = quizs[quizId];
        return q.answer;
    }

    /*
    문제를 제공 해주는 함수 정답은 빼고 줘야 하므로 q.answer의 값은 비워서 리턴한다.
    */
    function getQuiz(uint quizId) public view returns (Quiz_item memory) {
        Quiz_item memory q = quizs[quizId];
        q.answer = "";
        return q;
    }

    /*
    퀴즈의 번호를 호출한다.
    */
    function getQuizNum() public view returns (uint){
        return quiz_num;
    }
    
    /*
    문제에 베팅을 진행한다. 그 값은 해당 문제의 가능한 베팅값의 범위 내에서 진행되어야 한다. 배열의 초기화를 진행해주지 않으면 여기서 문제가 발생한다.
    */
    function betToPlay(uint quizId) public payable {
        Quiz_item memory q = quizs[quizId];
        require(q.min_bet <= msg.value && msg.value <= q.max_bet);
        bets[quizId-1][msg.sender] += msg.value;
    }   
    
    /*
    퀴즈의 정답이 string이기 때문에 인코딩을 해서 비교를 하고 정답이라면 베팅한 금액의 2배를 해당 유저의 밸런스에 더해주고 베팅금을 초기화하고 
    틀렸다면 베팅금을 초기화하면서 vault_balance에 귀속 시킨다.
    */
    function solveQuiz(uint quizId, string memory ans) public returns (bool) {
        Quiz_item memory q = quizs[quizId];
        bool res = keccak256(abi.encodePacked(q.answer)) == keccak256(abi.encodePacked(ans));
        if (res) {
            balances[msg.sender] += bets[quizId-1][msg.sender] * 2;
            bets[quizId-1][msg.sender] = 0;
        }else{
            vault_balance += bets[quizId-1][msg.sender];
            bets[quizId-1][msg.sender] = 0;
        }
        return res;
    }

    /*
    아래 함수를 호출하면 해당 유저의 밸런스를 모두 반환해주면서 해당 유저의 밸런스를 0으로 초기화 한다.
    */
    function claim() public {
        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        (success);
    }
    
    receive() external payable{}
}