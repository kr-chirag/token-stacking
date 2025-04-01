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
        Reward storage reward
    ) private view returns (uint256) {
        if (block.timestamp > reward.periodFinish) {
            if (reward.periodFinish < reward.lastUpdated) return 0;
            return reward.periodFinish - reward.lastUpdated;
        } else {
            return block.timestamp - reward.lastUpdated;
        }
    }

    function _rewardPerTokenAccumulated(
        Reward storage reward,
        uint256 _totalSupply
    ) private view returns (uint256) {
        if (_totalSupply == 0) return 0;
        return reward.rewardPerTokenAccumulated + (reward.rewardPerSecond *
            _duration(reward) * 1e18 ) / _totalSupply;
    }

    function calculateReward(Reward storage reward, address _account, uint256 _stake, uint256 _totalSupply) internal view returns(uint256){
        uint256 applicable = _rewardPerTokenAccumulated(reward, _totalSupply) - reward.lastRewardPerTokenAccumulated[_account];
        return applicable * _stake / 1e18 ;
        
    }

    function updateRewardDetails(Reward storage reward, uint256 _totalSupply) internal {
        reward.rewardPerTokenAccumulated = _rewardPerTokenAccumulated(reward, _totalSupply);
        reward.lastUpdated = block.timestamp;
    }

}
