// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./libs/RewardStruct.sol";

contract Staking {
    using RewardStruct for RewardStruct.Reward;

    struct Stake {
        uint256 amount;
        uint256 rewardedAmount;
    }

    IERC20 private token;
    RewardStruct.Reward public reward;

    address public rewardManager;
    uint256 public totalSupply;

    mapping(address stakeHolder => Stake stake) public stakeHolderToStake;

    constructor(address _token, address _rewardManager) {
        token = IERC20(_token);
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
        reward.updateRewardDetails(_account, totalSupply);
    }

    function _withdraw(address _account, uint256 _amount) private {
        totalSupply -= _amount;
        stakeHolderToStake[_account].amount -= _amount;
        token.transfer(_account, _amount);
    }

    function _claim(address _account) private {
        uint256 rewardedAmount = stakeHolderToStake[msg.sender].rewardedAmount;
        stakeHolderToStake[msg.sender].rewardedAmount = 0;
        token.transfer(_account, rewardedAmount);
    }

    /* ========== public user interactions ========== */

    function stake(uint256 _amount) public checkTokenBalance(_amount) {
        token.transferFrom(msg.sender, address(this), _amount);
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

    function getRewards() public view returns (uint256) {
        return
            stakeHolderToStake[msg.sender].rewardedAmount +
            reward.calculateReward(
                msg.sender,
                stakeHolderToStake[msg.sender].amount,
                totalSupply
            );
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
        reward.periodFinish = block.timestamp + _duration;
        reward.rewardPerSecond = _amount / _duration;
        reward.lastUpdated = block.timestamp;
        token.transferFrom(msg.sender, address(this), _amount);
    }

    modifier onlyRewardManager() {
        require(msg.sender == rewardManager, "Access Denied");
        _;
    }

    modifier checkTokenBalance(uint256 _amount) {
        uint256 userBalance = token.balanceOf(msg.sender);
        require(userBalance >= _amount, "Insufficient balance");
        _;
    }
}
