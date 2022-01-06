// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";

contract Lottery {
    enum AutomaticPayoutConditions {
        Always,
        ParticipantsCountReached,
        TimeLimitReached
    }

    bool lottery_open = false;
    uint ticket_price = 0.1 ether;
    uint max_participants = 0;
    uint timestamp_start = block.timestamp;
    uint time_limit = 0;
    uint auto_payout_on = 0;
    address owner = msg.sender;
    mapping (address => bool) participants;
    address payable[] participants_list;

    constructor() {
    }

    function openLottery() public {
        require(msg.sender == owner, "You must be the owner to open the lottery");
        require(lottery_open == false, "Lottery is already opened");
        lottery_open = true;
        timestamp_start = block.timestamp;
    }

    function setTicketPrice(uint _ticket_price) public {
        require(msg.sender == owner, "You must be the owner to change this setting");
        require(lottery_open == false, "You can't change the ticket price of an opened lottery");
        ticket_price = _ticket_price;
    }

    function setMaxParticipants(uint _max_participants) public {
        require(msg.sender == owner, "You must be the owner to change this setting");
        require(lottery_open == false, "You can't change the amount of participants of an opened lottery");
        max_participants = _max_participants;
    }

    function setTimeLimit(uint _time_limit) public {
        require(msg.sender == owner, "You must be the owner to change this setting");
        require(lottery_open == false, "You can't change the time limit of an opened lottery");
        time_limit = _time_limit;
    }

    function enableAutoPayoutOn(uint8 flags) public {
        require(msg.sender == owner, "You must be the owner to change this setting");
        require(lottery_open == false, "You can't change the auto payout settings of an opened lottery");
        auto_payout_on = flags;
    }

    function checkAutoPayout(AutomaticPayoutConditions check_for) internal view returns (bool) {
        uint8 flag = uint8(1 << uint8(check_for));
        return (flag & auto_payout_on) > 0;
    }

    function participate() payable public returns (string memory) {
        string memory error_msg;

        // Checking if lottery is open
        require(lottery_open, "Lottery is closed for the moment");

        // Checking for participants count
        error_msg = string(abi.encodePacked("Max participants count reached (", max_participants, ")"));
        require(participants_list.length < max_participants, error_msg);

        // Checking for ticket price
        error_msg = string(abi.encodePacked("Ticket costs exactly ", (ticket_price / 1 gwei), " gwei"));
        require(msg.value == ticket_price, error_msg);

        // Checking for people already participating
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
        if (checkAutoPayout(AutomaticPayoutConditions.Always)) {

        }
        else if (checkAutoPayout(AutomaticPayoutConditions.ParticipantsCountReached)) {
            if (participants_list.length < max_participants) {
                string memory error_msg = string(abi.encodePacked("Max participants count not reached (", participants_list.length, " / ", max_participants, ")"));
                revert(error_msg);
            }
        }
        else if (checkAutoPayout(AutomaticPayoutConditions.TimeLimitReached)) {
            if (block.timestamp < timestamp_start + time_limit) {
                string memory error_msg = string(abi.encodePacked("Time limit not reached (", block.timestamp - timestamp_start, " / ", time_limit, ")"));
                revert(error_msg);
            }
        }
        else if (msg.sender != owner) {
            revert("Only the owner can trigger payment to winner");
        }

        address payable winner = participants_list[random() % participants_list.length];
        winner.transfer(ticket_price * participants_list.length);
        for (uint i = 0; i < participants_list.length; i++) {
            delete participants[participants_list[i]];
        }
        delete participants_list;
        lottery_open = false;
    }
}