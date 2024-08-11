// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Quiz{
    struct Quiz_item {
      uint id;
      string question;
      string answer;
      uint min_bet;
      uint max_bet;
   }
    uint public quiz_num = 0;
    mapping(bytes32 => Quiz_item) public quizs;
    mapping(address => uint256)[] public bets;
    mapping(address => uint256) public balances;
    uint public vault_balance;

    constructor () {
        Quiz_item memory q;
        q.id = 1;
        q.question = "1+1=?";
        q.answer = "2";
        q.min_bet = 1 ether;
        q.max_bet = 2 ether;
        addQuiz(q);
    }

    function addQuiz(Quiz_item memory q) public{
        require(msg.sender != address(1));
        bets.push();
        bytes32 slot = (keccak256(abi.encodePacked(q.id)));
        quizs[slot] = q;
        quiz_num += 1;
    }

    function getAnswer(uint quizId) public view returns (string memory){
        bytes32 slot = (keccak256(abi.encodePacked(quizId)));
        Quiz_item memory q = quizs[slot];
        return q.answer;
    }

    function getQuiz(uint quizId) public view returns (Quiz_item memory) {
        bytes32 slot = (keccak256(abi.encodePacked(quizId)));
        Quiz_item memory q = quizs[slot];
        q.answer = "";
        return q;
    }

    function getQuizNum() public view returns (uint){
        return quiz_num;
    }
    
    function betToPlay(uint quizId) public payable {
        bytes32 slot = keccak256(abi.encodePacked(quizId));
        Quiz_item memory q = quizs[slot];
        require(q.min_bet <= msg.value && msg.value <= q.max_bet);
        bets[quizId-1][msg.sender] += msg.value;
    }   
    
    function solveQuiz(uint quizId, string memory ans) public returns (bool) {
        bytes32 slot = keccak256(abi.encodePacked(quizId));
        Quiz_item memory q = quizs[slot];
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

    function claim() public {
        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        (success);
    }
    
    receive() external payable{}
}