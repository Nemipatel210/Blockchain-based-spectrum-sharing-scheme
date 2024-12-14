// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./UserManagement.sol";
import "./SpectrumAuction.sol";
import "./SpectrumUtility.sol";

contract SpectrumSharing {
    UserManagement public userManagement;
    SpectrumAuction public spectrumAuction;
    SpectrumUtility public spectrumUtility;

    constructor(uint256 _biddingTime, uint256 _auctionEnd) {
        userManagement = new UserManagement();
        spectrumUtility = new SpectrumUtility();
        spectrumAuction = new SpectrumAuction(_biddingTime, _auctionEnd, address(userManagement), address(spectrumUtility));
        userManagement.setAuctionAddress(address(spectrumAuction));
    }

    function registerSeller(uint256 _bw, uint256 _price, uint256 total_bw, uint256 usage_bw, uint256 _p, uint256 _q) public payable {
        spectrumAuction.registerSeller{value: msg.value}(_bw, _price, total_bw, usage_bw, _p, _q);
    }

    function registerBuyer(uint256 _bw, uint256 _bid, uint256 _p, uint256 _q) public payable {
        spectrumAuction.registerBuyer{value: msg.value}(_bw, _bid, _p, _q);
    }

    function conductAuction() public {
        spectrumAuction.conductAuction();
    }

    function withdraw() public returns (bool) {
        return spectrumAuction.withdraw();
    }
}