// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./UserManagement.sol";
import "./SpectrumUtility.sol";

contract SpectrumAuction {
    address public admin;
    uint256 public bidEnd;
    uint256 public aucEnd;
    UserManagement public userManagement;
    SpectrumUtility public spectrumUtility;

    constructor(uint256 _biddingTime, uint256 _auctionEnd, address _userManagement, address _spectrumUtility) {
        admin = msg.sender;
        bidEnd = block.timestamp + _biddingTime;
        aucEnd = block.timestamp + _auctionEnd;
        userManagement = UserManagement(_userManagement);
        spectrumUtility = SpectrumUtility(_spectrumUtility);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin access");
        _;
    }

    struct Seller {
        address id;
        uint256 bandwidth;
        uint256 price;
    }
    Seller[] public sellers;

    struct Buyer {
        address id;
        uint256 bandwidth;
        uint256 bid;
        bool allocated;
    }
    Buyer[] public buyers;

    function registerSeller(uint256 _bw, uint256 _price, uint256 total_bw, uint256 usage_bw, uint256 _p, uint256 _q) public payable {
        require(block.timestamp <= bidEnd, "Registration already ended.");
        require(msg.value >= 2e18, "Insufficient deposit");

        (uint256 _n, uint256 _d, uint256 _mesg, uint256 _c) = spectrumUtility.getAuth(_p, _q);
        uint256 m = spectrumUtility.modExp(_c, _d, _n);
        require(m == _mesg, "Seller authentication failed");

        require(_bw <= (total_bw - usage_bw - (usage_bw) / 10), "Seller should reserve 10% for uncertainty.");

        userManagement.registerUser(msg.sender, true);
        userManagement.updateDeposit(msg.sender, msg.value - 1e18, true);

        sellers.push(Seller(msg.sender, _bw, _price));
    }

    function registerBuyer(uint256 _bw, uint256 _bid, uint256 _p, uint256 _q) public payable {
        require(block.timestamp <= bidEnd, "Registration already ended.");
        require(msg.value >= 2e18, "Insufficient deposit");

        (uint256 _n, uint256 _d, uint256 _mesg, uint256 _c) = spectrumUtility.getAuth(_p, _q);
        uint256 m = spectrumUtility.modExp(_c, _d, _n);
        require(m == _mesg, "Buyer authentication failed");

        userManagement.registerUser(msg.sender, false);
        userManagement.updateDeposit(msg.sender, msg.value - 1e18, true);

        buyers.push(Buyer(msg.sender, _bw, _bid, false));
    }


    function conductAuction() public onlyAdmin {
        require(block.timestamp > bidEnd && block.timestamp <= aucEnd, "Not auction time");

        // Sort buyers by bid (highest to lowest)
        for (uint i = 0; i < buyers.length; i++) {
            for (uint j = i + 1; j < buyers.length; j++) {
                if (buyers[j].bid > buyers[i].bid) {
                    Buyer memory temp = buyers[i];
                    buyers[i] = buyers[j];
                    buyers[j] = temp;
                }
            }
        }

        // Allocate spectrum
        for (uint i = 0; i < buyers.length; i++) {
            for (uint j = 0; j < sellers.length; j++) {
                if (sellers[j].bandwidth >= buyers[i].bandwidth && buyers[i].bid >= sellers[j].price) {
                    uint256 transactionPrice = buyers[i].bandwidth * buyers[i].bid;
                    userManagement.updateDeposit(sellers[j].id, transactionPrice, true);
                    (, uint256 buyerDeposit, ,) = userManagement.getUserInfo(buyers[i].id);

                    if (buyerDeposit < transactionPrice) {
                        userManagement.updateDebt(buyers[i].id, transactionPrice - buyerDeposit);
                        userManagement.updateDeposit(buyers[i].id, buyerDeposit, false);
                    } else {
                        userManagement.updateDeposit(buyers[i].id, transactionPrice, false);
                    }

                    sellers[j].bandwidth -= buyers[i].bandwidth;
                    buyers[i].allocated = true;
                    break;
                } else if (sellers[j].bandwidth >= (buyers[i].bandwidth / 2) && buyers[i].bid >= sellers[j].price) {
                    // Partial allocation
                    uint256 partialBandwidth = buyers[i].bandwidth / 2;
                    uint256 partialTransactionPrice = partialBandwidth * buyers[i].bid;
                    userManagement.updateDeposit(sellers[j].id, partialTransactionPrice, true);
                    (, uint256 buyerDeposit, ,) = userManagement.getUserInfo(buyers[i].id);

                    if (buyerDeposit < partialTransactionPrice) {
                        userManagement.updateDebt(buyers[i].id, partialTransactionPrice - buyerDeposit);
                        userManagement.updateDeposit(buyers[i].id, buyerDeposit, false);
                    } else {
                        userManagement.updateDeposit(buyers[i].id, partialTransactionPrice, false);
                    }

                    sellers[j].bandwidth -= partialBandwidth;
                    buyers[i].bandwidth -= partialBandwidth;
                    buyers[i].allocated = true;
                    break;
                }
            }
        }
    }
    

    function withdraw() public returns (bool) {
        require(block.timestamp > aucEnd, "Auction not ended");
        (, uint256 deposit, uint256 debt, bool allowedToWithdraw) = userManagement.getUserInfo(msg.sender);

        require(allowedToWithdraw, "Not allowed to withdraw");

        if (deposit > 0) {
            uint256 amount = deposit + 1e18;
            userManagement.updateDeposit(msg.sender, deposit, false);
            (bool success, ) = payable(msg.sender).call{value: amount}("");
            return success;
        } else if (debt > 0) {
            emit LogNotice("Insufficient balance. Please add funds to the contract.");
            return false;
        } else {
            emit LogNotice("Nothing to withdraw");
            return true;
        }
    }

    event LogNotice(string message);
}