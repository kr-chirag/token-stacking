// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;

library RewardUtils {
    struct Reward {
        uint256 amount; // amount to distribute for the entire duration
        uint256 durationToDistribute; // duration in which the amount should be distributed
        uint256 periodFinish; // addedAt + durationToDistribute;
        uint256 rewardPerSecond; // reward to distribute per second = amount / durationToDistribute
        uint256 lastUpdated; // last time when rewardPerTokenAccumulated updated
        uint256 rewardPerTokenAccumulated; // accumulated value of rewardPerTokenAccumulated
        mapping(address => uint256) lastRewardPerTokenAccumulated; // last RewardPerTokenAccumulated when user calculated reward
    }

    function _min(uint256 n1, uint256 n2) private pure returns (uint256 min) {
        min = (n1 > n2) ? n2 : n1;
    }

    function _duration(
        Reward storage reward,
        uint256 _currentTime
    ) private view returns (uint256) {
        if (_currentTime > reward.periodFinish) {
            if (reward.periodFinish < reward.lastUpdated) return 0;
            return reward.periodFinish - reward.lastUpdated;
        } else {
            return _currentTime - reward.lastUpdated;
        }
    }

    function _rewardPerTokenAccumulated(
        Reward storage reward,
        uint256 _totalSupply,
        uint256 _currentTime
    ) private returns (uint256) {
        uint256 recent = reward.rewardPerTokenAccumulated;
        if (_totalSupply == 0) return recent;
        uint256 current = (reward.rewardPerSecond *
            _duration(reward, _currentTime)) / _totalSupply;
        reward.rewardPerTokenAccumulated = recent + current;
        return reward.rewardPerTokenAccumulated;
    }

    function calculateReward(
        Reward storage reward,
        address _account,
        uint256 _stakedAmount,
        uint256 _totalSupply
    ) internal returns (uint256) {
        uint256 _currentTime = block.timestamp;
        uint256 currentRewardPerToken = _rewardPerTokenAccumulated(
            reward,
            _totalSupply,
            _currentTime
        );
        uint256 applicableRewardPerToken = currentRewardPerToken -
            reward.lastRewardPerTokenAccumulated[_account];
        uint256 rewardedAmount = _stakedAmount * applicableRewardPerToken;
        reward.lastRewardPerTokenAccumulated[_account] = currentRewardPerToken;
        reward.lastUpdated = _currentTime;
        return rewardedAmount;
    }
}
