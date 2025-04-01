// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;

library RewardStruct {
    struct Reward {
        uint256 periodFinish; // addedAt + durationToDistribute;
        uint256 rewardPerSecond; // reward to distribute per second = amount / durationToDistribute
        uint256 lastUpdated; // last time when rewardPerTokenAccumulated updated
        uint256 rewardPerTokenAccumulated; // accumulated value of rewardPerTokenAccumulated
        mapping(address => uint256) lastRewardPerTokenAccumulated; // last RewardPerTokenAccumulated when user calculated reward
    }

    function _min(uint256 n1, uint256 n2) private pure returns (uint256 min) {
        min = (n1 > n2) ? n2 : n1;
    }

    function _duration(Reward storage reward) private view returns (uint256) {
        uint256 applibaleUptoTime = _min(block.timestamp, reward.periodFinish);
        if (applibaleUptoTime < reward.lastUpdated) return 0;
        return applibaleUptoTime - reward.lastUpdated;
    }

    function _rewardPerTokenAccumulated(
        Reward storage reward,
        uint256 _totalSupply
    ) private view returns (uint256) {
        if (_totalSupply == 0) return 0;
        return
            reward.rewardPerTokenAccumulated +
            (reward.rewardPerSecond * _duration(reward) * 1e18) /
            _totalSupply;
    }

    function calculateReward(
        Reward storage reward,
        address _account,
        uint256 _stake,
        uint256 _totalSupply
    ) internal view returns (uint256) {
        uint256 applicable = _rewardPerTokenAccumulated(reward, _totalSupply) -
            reward.lastRewardPerTokenAccumulated[_account];
        return (applicable * _stake) / 1e18;
    }

    function updateRewardDetails(
        Reward storage reward,
        address _account,
        uint256 _totalSupply
    ) internal {
        reward.rewardPerTokenAccumulated = _rewardPerTokenAccumulated(
            reward,
            _totalSupply
        );
        reward.lastRewardPerTokenAccumulated[_account] = reward
            .rewardPerTokenAccumulated;
        reward.lastUpdated = block.timestamp;
    }
}
