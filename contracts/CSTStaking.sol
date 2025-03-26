// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;

import {CSToken} from "./CSToken.sol";

contract CSTStaking {
    CSToken private csToken;
    address private rewardManager;

    uint256 public totalStakedTokes;
    uint256 private totalRewardedTokes;
    address[] public users;
    mapping(address user => uint256 stakedTokens) public balance;
    mapping(address user => uint256 rewardTokens) public reward;

    constructor(CSToken _csToken, address _rewardManager) {
        csToken = _csToken;
        rewardManager = _rewardManager;
    }

    function stack(uint256 _tokensToStak) public {
        require(
            csToken.balanceOf(msg.sender) > _tokensToStak,
            "Insufficient balance"
        );
        csToken.transferFrom(msg.sender, address(this), _tokensToStak);
        totalStakedTokes += _tokensToStak;
        balance[msg.sender] += _tokensToStak;
        _addUser(msg.sender);
    }

    function withdraw(uint256 _tokensToWithdraw) public {
        require(
            balance[msg.sender] >= _tokensToWithdraw,
            "Insufficient stacking"
        );
        csToken.transfer(msg.sender, _tokensToWithdraw);
        totalStakedTokes -= _tokensToWithdraw;
        balance[msg.sender] -= _tokensToWithdraw;
    }

    function claim() public {
        uint256 rewardsToClaim = reward[msg.sender];
        require(rewardsToClaim > 0, "No Reward to claim");
        totalRewardedTokes -= rewardsToClaim;
        csToken.transfer(msg.sender, rewardsToClaim);
        delete reward[msg.sender];
    }

    function distributeReward(uint256 _tokens) public onlyRewardManager {
        require(
            csToken.balanceOf(address(this)) >= _tokens,
            "Not enough rewards"
        );
        totalRewardedTokes += _tokens;
        for (uint256 idx; idx < users.length; idx++) {
            uint256 userBalance = balance[users[idx]];
            uint256 userReward = (userBalance * _tokens) / totalStakedTokes;
            reward[users[idx]] += userReward;
        }
    }

    function totalAvailableRewards() public view returns (uint256) {
        return
            csToken.balanceOf(address(this)) -
            totalRewardedTokes -
            totalStakedTokes;
    }

    function _addUser(address _address) internal {
        bool isToAdd = true;
        for (uint256 idx; idx < users.length; idx++) {
            if (users[idx] == _address) isToAdd = false;
        }
        if (isToAdd) users.push(_address);
    }

    modifier onlyRewardManager() {
        require(msg.sender == rewardManager, "Unauthorized");
        _;
    }
}
