// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/ITaskToken.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract TaskToken is ERC20, Ownable, ITaskToken {
    // All staking infos
    mapping(address => mapping(address => mapping(uint256 => StakingInfo)))
        private _stakingInfos;

    // All Rewards
    mapping(address => uint256) private _rewards;

    /**
     * @notice Merkle root hash for whitelist addresses
     */
    bytes32 public merkleRoot = 0x0;

    //Whitelist Daily Limit
    uint256 public constant WHITELIST_LIMIT = 1000 * 10 ** 18;

    //Non WhiteList Limit
    uint256 public constant NON_WHITELIST_LIMIT = 500 * 10 ** 18;

    //Daily Limit For Each User
    mapping(address => uint256) public dailyLimit;

    //Day Start For Each User
    mapping(address => uint256) public dayStart;

    modifier checkLimit(
        bytes32[] calldata _merkleProof,
        address _user,
        uint256 _amount
    ) {
        if (dayStart[_user] > 0) {
            if (block.timestamp - dayStart[_user] > 1 days) {
                dayStart[_user] = block.timestamp;
                dailyLimit[_user] = 0;
            }
        }
        if (verifyAddress(_merkleProof, _user)) {
            if (dailyLimit[_user] + _amount > WHITELIST_LIMIT) {
                revert("ERC20: Exceeds WhiteList Limit");
            }
        } else {
            if (dailyLimit[_user] + _amount > NON_WHITELIST_LIMIT) {
                revert("ERC20: Exceeds Daily Limit");
            }
        }

        if (dayStart[_user] == 0) {
            dayStart[_user] = block.timestamp;
        }

        _;
    }

    constructor(bytes32 _merkleRoot) ERC20("TaskToken", "TTK") {
        merkleRoot = _merkleRoot;
    }

    /// @inheritdoc ITaskToken
    function setMerkleRoot(bytes32 _merkleRootHash) external onlyOwner {
        merkleRoot = _merkleRootHash;
    }

    /**
     * @notice Verify merkle proof of the address
     */
    function verifyAddress(
        bytes32[] calldata _merkleProof,
        address user
    ) private view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(user));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
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

    /// @inheritdoc	ITaskToken
    function unstake(
        address _nftContractAddress,
        uint256 _nftId
    ) external override {
        address caller = _msgSender();

        require(
            _stakingInfos[caller][_nftContractAddress][_nftId].holder == caller,
            "ERC20: Invalid staking Owner"
        );

        StakingInfo memory targetStaking = _stakingInfos[caller][
            _nftContractAddress
        ][_nftId];

        uint256 stakedDays = (block.timestamp - targetStaking.startDate) /
            1 days;

        if (stakedDays > 0 && stakedDays % 2 != 0) {
            stakedDays -= 1;
        }

        uint256 reward = 0;

        if (stakedDays > 0) {
            if (stakedDays < 90) {
                stakedDays = stakedDays / 2;

                if (stakedDays % 2 != 0) {
                    stakedDays -= 1;
                    reward = 10 ** (decimals() / 4);
                }
            }
            reward = stakedDays > 0
                ? stakedDays % 4 == 0
                    ? reward > 1
                        ? (((stakedDays) / 4) * (10 ** decimals())) +
                            (10 ** (decimals() / 4))
                        : (((stakedDays) / 4) * (10 ** decimals()))
                    : reward > 1
                    ? (((stakedDays - 2) / 4) *
                        (10 ** decimals()) +
                        ((10 ** (decimals() / 2))) *
                        (10 ** (decimals() / 4)))
                    : (((stakedDays - 2) / 4) *
                        (10 ** decimals()) +
                        (10 ** (decimals() / 2)))
                : 10 ** (decimals() / 4);
        }

        _rewards[caller] += reward;

        IERC721(targetStaking.nftContractAddress).transferFrom(
            address(this),
            caller,
            targetStaking.nftId
        );

        delete _stakingInfos[caller][_nftContractAddress][_nftId];

        emit Unstake(caller, _nftId, _nftContractAddress);
    }

    /// @inheritdoc	ITaskToken
    function getStakingInfo(
        address _nftContractAddress,
        uint256 _nftId,
        address _owner
    ) external view override returns (StakingInfo memory) {
        return _stakingInfos[_owner][_nftContractAddress][_nftId];
    }

    /// @inheritdoc	ITaskToken
    function transfer(
        address to,
        uint256 amount,
        bytes32[] calldata _merkleProof
    )
        external
        override
        checkLimit(_merkleProof, msg.sender, amount)
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        dailyLimit[owner] += amount;

        return true;
    }

    /// @inheritdoc	ITaskToken
    function transferFrom(
        address from,
        address to,
        uint256 amount,
        bytes32[] calldata _merkleProof
    ) external override checkLimit(_merkleProof, from, amount) returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        dailyLimit[from] += amount;
        return true;
    }

    /// @inheritdoc	ITaskToken
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    /// @inheritdoc	ERC20
    function transfer(
        address to,
        uint256 amount
    ) public override onlyOwner returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /// @inheritdoc	ERC20
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override onlyOwner returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /// @inheritdoc ITaskToken
    function withdraw() external returns (bool) {
        address caller = _msgSender();
        if (_rewards[caller] > 0) {
            _mint(caller, _rewards[caller]);
            _rewards[caller] = 0;

            return true;
        }
        return false;
    }

    /// @inheritdoc ITaskToken
    function checkReward() external view returns (uint256) {
        return _rewards[msg.sender];
    }
}
