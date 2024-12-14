// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract UserManagement {
    address public admin;
    address public auctionAddress;

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin access");
        _;
    }

    modifier onlyAuction() {
        require(msg.sender == auctionAddress, "Only auction contract access");
        _;
    }

    function setAuctionAddress(address _auctionAddress) public onlyAdmin {
        auctionAddress = _auctionAddress;
    }

    struct User {
        bool isSeller;
        uint256 deposit;
        uint256 debt;
        bool allowedToWithdraw;
    }

    mapping(address => User) public users;

    function registerUser(address _user, bool _isSeller) public onlyAuction {
        users[_user].isSeller = _isSeller;
        users[_user].allowedToWithdraw = true;
    }

    function updateDeposit(address _user, uint256 _amount, bool _increase) public onlyAuction {
        if (_increase) {
            users[_user].deposit += _amount;
        } else {
            require(users[_user].deposit >= _amount, "Insufficient deposit");
            users[_user].deposit -= _amount;
        }
    }

    function updateDebt(address _user, uint256 _amount) public onlyAuction {
        users[_user].debt = _amount;
    }

    function getUserInfo(address _user) public view returns (bool, uint256, uint256, bool) {
        User memory user = users[_user];
        return (user.isSeller, user.deposit, user.debt, user.allowedToWithdraw);
    }
}