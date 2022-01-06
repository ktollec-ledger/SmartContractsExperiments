// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";

contract Lottery {
    enum AutomaticPayoutConditions {
        Always,
        MinParticipantsCountReached,
        MaxParticipantsCountReached,
        TimeLimitReached
    }

    bool lottery_open = false;
    uint256 ticket_price = 0.1 ether;
    uint256 min_participants = 0;
    uint256 max_participants = 0;
    uint256 timestamp_start = block.timestamp;
    uint256 time_limit = 0;
    uint256 auto_payout_on = 0;
    address owner = msg.sender;
    mapping(address => bool) participants;
    address payable[] participants_list;

    constructor() {}

    function openLottery() public {
        require(
            msg.sender == owner,
            "You must be the owner to open the lottery"
        );
        require(lottery_open == false, "Lottery is already opened");
        lottery_open = true;
        timestamp_start = block.timestamp;
    }

    function setTicketPrice(uint256 _ticket_price) public {
        require(
            msg.sender == owner,
            "You must be the owner to change this setting"
        );
        require(
            lottery_open == false,
            "You can't change the ticket price of an opened lottery"
        );
        ticket_price = _ticket_price;
    }

    function setMinParticipants(uint256 _min_participants) public {
        require(
            msg.sender == owner,
            "You must be the owner to change this setting"
        );
        require(
            lottery_open == false,
            "You can't change the amount of min participants of an opened lottery"
        );
        require(
            max_participants == 0 || max_participants > _min_participants,
            "max_participants must be higher than min_participants"
        );
        min_participants = _min_participants;
    }

    function setMaxParticipants(uint256 _max_participants) public {
        require(
            msg.sender == owner,
            "You must be the owner to change this setting"
        );
        require(
            lottery_open == false,
            "You can't change the amount of max participants of an opened lottery"
        );
        require(
            _max_participants == 0 || _max_participants > min_participants,
            "max_participants must be higher than min_participants"
        );
        max_participants = _max_participants;
    }

    function setTimeLimit(uint256 _time_limit) public {
        require(
            msg.sender == owner,
            "You must be the owner to change this setting"
        );
        require(
            lottery_open == false,
            "You can't change the time limit of an opened lottery"
        );
        time_limit = _time_limit;
    }

    function enableAutoPayoutOn(uint8 flags) public {
        require(
            msg.sender == owner,
            "You must be the owner to change this setting"
        );
        require(
            lottery_open == false,
            "You can't change the auto payout settings of an opened lottery"
        );
        auto_payout_on = flags;
    }

    function checkAutoPayout(AutomaticPayoutConditions check_for)
        internal
        view
        returns (bool)
    {
        uint8 flag = uint8(1 << uint8(check_for));
        return (flag & auto_payout_on) > 0;
    }

    function participate() public payable returns (string memory) {
        string memory error_msg;

        // Checking if lottery is open
        require(lottery_open, "Lottery is closed for the moment");

        // Checking for participants count
        string memory participants_amount_as_str = Strings.toString(
            participants_list.length
        );
        error_msg = string(
            abi.encodePacked(
                "Max participants count reached (",
                participants_amount_as_str,
                ")"
            )
        );
        require(
            max_participants == 0 ||
                (participants_list.length < max_participants),
            error_msg
        );

        // Checking for ticket price
        string memory ticket_price_as_str = Strings.toString(
            ticket_price / 1 gwei
        );
        error_msg = string(
            abi.encodePacked(
                "Ticket costs exactly ",
                ticket_price_as_str,
                " gwei"
            )
        );
        require(msg.value == ticket_price, error_msg);

        // Checking for people already participating
        require(
            participants[msg.sender] == false,
            "You are already participating in this Lottery round"
        );

        participants[msg.sender] = true;
        participants_list.push(payable(msg.sender));

        string memory response = string(
            abi.encodePacked(
                "There is ",
                participants_amount_as_str,
                " participants (including you), good luck !"
            )
        );
        return response;
    }

    function random() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        participants_list
                    )
                )
            );
    }

    function payWinner() public payable {
        require(lottery_open, "Lottery is closed for the moment");
        require(
            participants_list.length > min_participants,
            "Not enough participants to declare a winner"
        );

        // Auto-payout policies
        if (msg.sender != owner) {
            if (checkAutoPayout(AutomaticPayoutConditions.Always)) {} else if (
                checkAutoPayout(
                    AutomaticPayoutConditions.MinParticipantsCountReached
                )
            ) {
                if (participants_list.length < min_participants) {
                    string memory participants_amount_as_str = Strings.toString(
                        participants_list.length
                    );
                    string memory min_participants_as_str = Strings.toString(
                        min_participants
                    );
                    string memory error_msg = string(
                        abi.encodePacked(
                            "Max participants count not reached (",
                            participants_amount_as_str,
                            " / ",
                            min_participants_as_str,
                            ")"
                        )
                    );
                    revert(error_msg);
                }
            } else if (
                checkAutoPayout(
                    AutomaticPayoutConditions.MaxParticipantsCountReached
                )
            ) {
                if (participants_list.length < max_participants) {
                    string memory participants_amount_as_str = Strings.toString(
                        participants_list.length
                    );
                    string memory max_participants_as_str = Strings.toString(
                        max_participants
                    );
                    string memory error_msg = string(
                        abi.encodePacked(
                            "Max participants count not reached (",
                            participants_amount_as_str,
                            " / ",
                            max_participants_as_str,
                            ")"
                        )
                    );
                    revert(error_msg);
                }
            } else if (
                checkAutoPayout(AutomaticPayoutConditions.TimeLimitReached)
            ) {
                if (block.timestamp < timestamp_start + time_limit) {
                    string memory current_seconds_as_str = Strings.toString(
                        block.timestamp - timestamp_start
                    );
                    string memory time_limit_as_str = Strings.toString(
                        time_limit
                    );
                    string memory error_msg = string(
                        abi.encodePacked(
                            "Time limit not reached (",
                            current_seconds_as_str,
                            " / ",
                            time_limit_as_str,
                            ")"
                        )
                    );
                    revert(error_msg);
                }
            } else {
                revert("Only the owner can trigger payment to winner");
            }
        }

        if (participants_list.length > 0) {
            address payable winner = participants_list[
                random() % participants_list.length
            ];
            winner.transfer(ticket_price * participants_list.length);
        }

        for (uint256 i = 0; i < participants_list.length; i++) {
            delete participants[participants_list[i]];
        }
        delete participants_list;
        lottery_open = false;
    }
}
