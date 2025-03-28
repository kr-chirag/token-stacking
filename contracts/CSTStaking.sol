// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;

import {CSToken} from "./CSToken.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {RewardUtils} from "./utils/RewardUtils.sol";

contract CSTStaking {
    using EnumerableSet for EnumerableSet.AddressSet;
    using RewardUtils for RewardUtils.Reward;

    struct Stake {
        uint256 amount;
        uint256 rewardedAmount;
    }

    CSToken private csToken;
    RewardUtils.Reward private reward;

    address public rewardManager;
    uint256 public totalSupply;

    // EnumerableSet.AddressSet private stakeHolders;
    mapping(address stakeHolder => Stake stake) public stakeHolderToStake;

    constructor(CSToken _csToken, address _rewardManager) {
        csToken = _csToken;
        rewardManager = _rewardManager;
    }

    /* ========== Private utility functions ========== */

    function _updateReward(address _account) private {
        uint256 rewardedAmount = reward.calculateReward(
            _account,
            stakeHolderToStake[_account].amount,
            totalSupply
        );
        stakeHolderToStake[_account].rewardedAmount += rewardedAmount;
    }

    function _withdraw(address _account, uint256 _amount) private {
        totalSupply -= _amount;
        stakeHolderToStake[_account].amount -= _amount;
        csToken.transfer(_account, _amount);
    }

    function _claim(address _account) private {
        uint256 rewardedAmount = stakeHolderToStake[msg.sender].rewardedAmount;
        stakeHolderToStake[msg.sender].rewardedAmount = 0;
        csToken.transfer(_account, rewardedAmount);
    }

    /* ========== public user interactions ========== */

    function stake(uint256 _amount) public checkTokenBalance(_amount) {
        csToken.transferFrom(msg.sender, address(this), _amount);
        // update rewardedAmount for already staked tokens
        _updateReward(msg.sender);
        // add new tokens to stakeholder account
        stakeHolderToStake[msg.sender].amount += _amount;
        totalSupply += _amount;
    }

    function withdraw(uint256 _amount) public {
        // check is stakeholder has enough stakes
        uint256 userBalance = stakeHolderToStake[msg.sender].amount;
        require(userBalance >= _amount, "Insufficient balance");
        // update rewardedAmount for already staked tokens before withdraw
        _updateReward(msg.sender);
        // withdraw amount
        _withdraw(msg.sender, _amount);
    }

    function claim() public {
        // update rewardedAmount for already staked tokens before claim
        _updateReward(msg.sender);
        // claim the rewards
        _claim(msg.sender);
    }

    function exit() public {
        // update rewardedAmount for already staked tokens before claim
        _updateReward(msg.sender);
        // claim the rewards
        _claim(msg.sender);
        // withdraw amount
        _withdraw(msg.sender, stakeHolderToStake[msg.sender].amount);
        // remove stakeholder
        delete stakeHolderToStake[msg.sender];
    }

    function getRewards() public returns (uint256) {
        _updateReward(msg.sender);
        return stakeHolderToStake[msg.sender].rewardedAmount;
    }

    /* ========== public onlyRewardManager interactions ========== */

    function addReward(
        uint256 _amount,
        uint256 _duration
    ) public onlyRewardManager checkTokenBalance(_amount) {
        require(
            reward.periodFinish < block.timestamp,
            "distribution is in process"
        );
        reward.amount = _amount;
        reward.durationToDistribute = _duration;
        reward.periodFinish = block.timestamp + _duration;
        reward.rewardPerSecond = _amount / _duration;
        reward.lastUpdated = block.timestamp;
        csToken.transferFrom(msg.sender, address(this), _amount);
    }

    modifier onlyRewardManager() {
        require(msg.sender == rewardManager, "Access Denied");
        _;
    }

    modifier checkTokenBalance(uint256 _amount) {
        uint256 userBalance = csToken.balanceOf(msg.sender);
        require(userBalance >= _amount, "Insufficient balance");
        _;
    }
}
