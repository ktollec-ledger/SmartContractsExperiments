// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";

contract Lottery {
    uint constant ticket_price = 0.1 ether;
    address owner = msg.sender;
    mapping (address => bool) participants;
    address payable[] participants_list;

    constructor() {
    }

    function participate() payable public returns (string memory) {
        string memory amount_as_str = Strings.toString(ticket_price / 1 gwei);
        string memory error_msg = string(abi.encodePacked("Ticket costs exactly ", amount_as_str, " gwei"));
        require(msg.value == ticket_price, error_msg);
        require(participants[msg.sender] == false, "You are already participating in this Lottery round");
        participants[msg.sender] = true;
        participants_list.push(payable(msg.sender));
        string memory participants_amount_as_str = Strings.toString(participants_list.length);
        string memory response = string(abi.encodePacked("There is ", participants_amount_as_str, " participants (including you), good luck !"));
        return response;
    }

    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, participants_list)));
        
    }

    function payWinner() payable public {
        require(msg.sender == owner, "Only the owner can trigger payment to winner");
        address payable winner = participants_list[random() % participants_list.length];
        winner.transfer(ticket_price * participants_list.length);
        for (uint i = 0; i < participants_list.length; i++) {
            delete participants[participants_list[i]];
        }
        delete participants_list;
    }
}
