// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/ITaskToken.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TaskToken is ERC20, Ownable, ITaskToken {
    // All staking infos
    mapping(address => mapping(address => mapping(uint256 => StakingInfo)))
        private _stakingInfos;

    // All Rewards
    mapping(address => uint256) private _rewards;

    constructor() ERC20("TaskToken", "TTK") {}

    /// @inheritdoc	ITaskToken
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    /// @inheritdoc	ITaskToken
    function stake(
        address _nftContractAddress,
        uint256 _nftId
    ) external override {
        address holder = _msgSender();

        require(
            IERC721(_nftContractAddress).ownerOf(_nftId) == holder,
            "ERC20: Invalid Owner"
        );

        _stakingInfos[holder][_nftContractAddress][_nftId] = StakingInfo(
            holder,
            _nftId,
            block.timestamp,
            _nftContractAddress
        );

        IERC721(_nftContractAddress).transferFrom(
            holder,
            address(this),
            _nftId
        );

        emit Stake(holder, _nftId, block.timestamp, _nftContractAddress);
    }

    function unstake(
        address _nftContractAddress,
        uint256 _nftId
    ) external override {
        address holder = _msgSender();

        require(
            _stakingInfos[holder][_nftContractAddress][_nftId].holder == holder,
            "ERC20: Invalid staking Owner"
        );

        StakingInfo memory targetStaking = _stakingInfos[holder][
            _nftContractAddress
        ][_nftId];

        uint256 stakedDays = (block.timestamp - targetStaking.startDate) /
            1 days;

        if (stakedDays > 0 && stakedDays % 2 != 0) {
            stakedDays -= 1;
        }

        uint256 reward = stakedDays > 0
            ? stakedDays % 4 == 0
                ? (((stakedDays) / 4) * (10 ** decimals()))
                : (((stakedDays - 2) / 4) *
                    (10 ** decimals()) +
                    (10 ** (decimals() / 2)))
            : 0;

        _rewards[holder] += reward;

        IERC721(targetStaking.nftContractAddress).transferFrom(
            address(this),
            holder,
            targetStaking.nftId
        );

        delete _stakingInfos[holder][_nftContractAddress][_nftId];

        emit Unstake(holder, _nftId, _nftContractAddress);
    }

    /// @inheritdoc	ITaskToken
    function getStakingInfo(
        address _nftContractAddress,
        uint256 _nftId,
        address _owner
    ) external view override returns (StakingInfo memory) {
        return _stakingInfos[_owner][_nftContractAddress][_nftId];
    }
}
