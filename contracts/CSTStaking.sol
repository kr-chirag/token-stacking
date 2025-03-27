// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;

import {CSToken} from "./CSToken.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract CSTStaking {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Stake {
        uint256 amount;
        uint256 lastUpdated;
        uint256 reward;
    }

    CSToken private csToken;
    address public rewardManager;

    uint256 public totalStakedTokes;
    EnumerableSet.AddressSet private stakeHolders;
    mapping(address stakeHolder => Stake stake) public stakeHolderToStake;

    uint256 public rewardRate; // fixed reward rate per hour

    constructor(CSToken _csToken, address _rewardManager, uint256 _rewardRate) {
        csToken = _csToken;
        rewardManager = _rewardManager;
        rewardRate = _rewardRate;
    }

    function _calculateReward(address _account) private view returns (uint256) {
        uint256 lastUpdated = stakeHolderToStake[_account].lastUpdated;
        uint256 amount = stakeHolderToStake[_account].amount;
        return ((block.timestamp - lastUpdated) * amount * rewardRate) / 3600;
    }

    function _updateReward(address _account) private {
        uint256 reward = _calculateReward(_account);
        stakeHolderToStake[_account].lastUpdated = block.timestamp;
        stakeHolderToStake[_account].reward += reward;
    }

    function _withdraw(address _account, uint256 _amount) private {
        // check is stakeholder has enough stakes
        uint256 userBalance = stakeHolderToStake[_account].amount;
        require(userBalance >= _amount, "Insufficient balance");

        totalStakedTokes -= _amount;
        stakeHolderToStake[_account].amount -= _amount;

        csToken.transfer(_account, _amount);
    }

    function _claim(address _account) private {
        uint256 reward = stakeHolderToStake[msg.sender].reward;
        stakeHolderToStake[msg.sender].reward = 0;
        csToken.transfer(_account, reward);
    }

    function stake(uint256 _amount) public {
        uint256 userBalance = csToken.balanceOf(msg.sender);
        require(userBalance >= _amount, "Insufficient balance");
        csToken.transferFrom(msg.sender, address(this), _amount);

        // update reward for already staked tokens
        _updateReward(msg.sender);

        // add new tokens to stakeholder account
        stakeHolderToStake[msg.sender].amount += _amount;
        totalStakedTokes += _amount;
        stakeHolders.add(msg.sender);
    }

    function withdraw(uint256 _amount) public {
        // update reward for already staked tokens before withdraw
        _updateReward(msg.sender);
        // withdraw amount
        _withdraw(msg.sender, _amount);
    }

    function claim() public {
        // update reward for already staked tokens before claim
        _updateReward(msg.sender);
        // claim the rewards
        _claim(msg.sender);
    }

    function exit() public {
        // update reward for already staked tokens before claim
        _updateReward(msg.sender);
        // claim the rewards
        _claim(msg.sender);
        // withdraw amount
        _withdraw(msg.sender, stakeHolderToStake[msg.sender].amount);
        // remove stakeholder
        delete stakeHolderToStake[msg.sender];
    }

    function getRewards() public view returns (uint256) {
        return
            stakeHolderToStake[msg.sender].reward +
            _calculateReward(msg.sender);
    }

    function setRewardRate(uint256 _rewardRate) public onlyRewardManager {
        for (uint256 idx = 0; idx < stakeHolders.length(); idx++)
            _updateReward(stakeHolders.at(idx));
        rewardRate = _rewardRate;
    }

    modifier onlyRewardManager() {
        require(msg.sender == rewardManager, "Access Denied");
        _;
    }
}
