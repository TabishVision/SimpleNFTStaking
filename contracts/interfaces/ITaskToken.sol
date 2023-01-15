// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title interface for TaskToken logic
/// @author Tabish Shafi
interface ITaskToken {
    /// @notice Struct for staker's and token info
    /// @param holder Staking holder address
    /// @param tokenId Staked Token Id
    /// @param startDate start date of staking
    /// @param nftContractAddress Staked token contract Address
    struct StakingInfo {
        address holder;
        uint256 nftId;
        uint256 startDate;
        address nftContractAddress;
    }

    /// @dev Emitted when user stake
    /// @param _from Staker address
    /// @param _nftId Staked token Id
    /// @param _startDate start date of staking
    /// @param _nftContractAddress Staked token contract Address
    event Stake(
        address indexed _from,
        uint256 _nftId,
        uint256 _startDate,
        address _nftContractAddress
    );

    /// @dev Emitted when a stake holder unstakes
    /// @param _from address of the unstaking holder
    /// @param _nftId Staked token Id
    /// @param _nftContractAddress Staked token contract Address
    event Unstake(
        address indexed _from,
        uint256 _nftId,
        address _nftContractAddress
    );

    /**
     * @dev mint
     * @param _to mint tokens to
     * @param _amount amount of tokens to be minted
     *
     */
    function mint(address _to, uint256 _amount) external;

    /**
     * @notice Stake NFTS
     * @param _nftContractAddress contract Address of token to be stakked
     * @param _nftId nftId of token to be staked
     *
     * Requirements
     *
     * - Validate's Token Ownership
     *
     * Emits a {Stake} event
     */
    function stake(address _nftContractAddress, uint256 _nftId) external;

    /**
     * @dev Unstake
     * @param _nftContractAddress contract Address of token to be unstakked
     * @param _nftId nftId of token to be unstaked
     *
     * Emits a {Unstake} event
     */
    function unstake(address _nftContractAddress, uint256 _nftId) external;

    /**
     * @dev Returns staking infos of `_holder`
     * @param _nftContractAddress contract Address of token stakked
     * @param _nftId nftId of token staked
     * @param _owner holder of staking
     */
    function getStakingInfo(
        address _nftContractAddress,
        uint256 _nftId,
        address _owner
    ) external view returns (StakingInfo memory);
}
