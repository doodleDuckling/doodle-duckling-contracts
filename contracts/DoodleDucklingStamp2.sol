// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract DoodleDucklingStamp2 is ERC1155Upgradeable, OwnableUpgradeable {
    using StringsUpgradeable for uint;

    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenId;

    struct Stamp {
        uint totalAmount;
        uint remainAmount;
        uint8 rarity;
    }

    struct User {
        uint lastDrawTime;
        bool isWhitelisted;
    }

    mapping(address => User) public userList;
    mapping(uint => Stamp) public stampList;
    uint[] public stamps;

    bool public isStopped;
    bool public nonWhitelistIsActive;

    //------------stamp2------------//
    struct CommonClaimCardRule {
        uint startTime;
        uint endTime;
        uint[] stampIds;
        uint[] probabilities;
    }

    struct SpecialClaimCardRule {
        uint startTime;
        uint endTime;
        uint stampId;
        bytes32 merkleRoot;
    }

    CommonClaimCardRule public commonClaimCardRule;
    mapping(uint => SpecialClaimCardRule) public specialClaimCardRuleList;
    mapping(address => mapping(uint => bool)) specialClaimCardClaimedList;
    using MerkleProof for *;
    mapping(address => uint) userClaimTimes;
    uint public totalCommonClaimed;

    function initialize(string memory _name, string memory _symbol, string memory _baseURI) public initializer {
        name = _name;
        symbol = _symbol;
        __ERC1155_init(_baseURI);
        __Ownable_init();
        nonWhitelistIsActive = true;
    }


    function updateCommonClaimCardRule(uint _startTime, uint _endTime, uint[] memory _stampIds, uint[] memory _probabilities) public onlyOwner {
        require(_stampIds.length == _probabilities.length, "length not match");
        if (commonClaimCardRule.startTime == 0) {
            commonClaimCardRule = CommonClaimCardRule(_startTime, _endTime, _stampIds, _probabilities);
        } else {
            commonClaimCardRule.startTime = _startTime;
            commonClaimCardRule.endTime = _endTime;
            commonClaimCardRule.stampIds = _stampIds;
            commonClaimCardRule.probabilities = _probabilities;
        }
    }

    function updateSpecialClaimCardRules(uint[] memory ruleIds, uint[] memory startTimes, uint[] memory endTimes, uint[] memory stampIds, bytes32[] memory merkleRoots) public onlyOwner {
        for (uint i = 0; i < ruleIds.length; i++) {
            specialClaimCardRuleList[ruleIds[i]] = SpecialClaimCardRule(startTimes[i], endTimes[i], stampIds[i], merkleRoots[i]);
        }
    }

    function claimCardWithCommonRule(uint seed) public onlyOpened {
        uint timeInterval = getTimeInterval(_msgSender());
        require(timeInterval > 24 * 3600, 'ec1');
        require(commonClaimCardRule.startTime > 0 && commonClaimCardRule.probabilities.length > 0, 'ec2');
        require(checkClaimTime(commonClaimCardRule.startTime, commonClaimCardRule.endTime), "ec3");

        uint index = random(timeInterval, seed, 1000);

        for (uint i = 0; i < commonClaimCardRule.probabilities.length; i++) {
            if (i == commonClaimCardRule.probabilities.length - 1 ||
            (index >= commonClaimCardRule.probabilities[i] && index < commonClaimCardRule.probabilities[i + 1])) {
                _mint(_msgSender(), commonClaimCardRule.stampIds[i], 1, 'common');
                userList[_msgSender()].lastDrawTime = block.timestamp;
                if (userClaimTimes[_msgSender()] == 0) {
                    totalCommonClaimed++;
                }
                userClaimTimes[_msgSender()]++;
                emit ClaimCardWithCommonRule(commonClaimCardRule.stampIds[i], _msgSender());
                break;
            }
        }
    }

    function claimCardWithSpecialRule(uint ruleId, bytes32[] memory proof) public onlyOpened {
        SpecialClaimCardRule memory specialClaimCardRule = specialClaimCardRuleList[ruleId];
        require(checkWhitelist(proof, specialClaimCardRule.merkleRoot), 'ec10');
        require(!specialClaimCardClaimedList[_msgSender()][ruleId], 'ec11');
        require(specialClaimCardRule.startTime > 0, 'ec12');
        require(checkClaimTime(specialClaimCardRule.startTime, specialClaimCardRule.endTime), "ec13");

        _mint(_msgSender(), specialClaimCardRule.stampId, 1, 'special');
        specialClaimCardClaimedList[_msgSender()][ruleId] = true;
        emit ClaimCardWithSpecialRule(specialClaimCardRule.stampId, _msgSender());
    }

    function checkClaimTime(uint startTime, uint endTime) public view returns (bool){
        return block.timestamp >= startTime && block.timestamp <= endTime;
    }

    function checkWhitelist(bytes32[] memory proof, bytes32 merkleRoot) public view returns (bool){
        return MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(_msgSender())));
    }

    function checkSpecialClaimed(address account, uint ruleId) public view returns (bool){
        return specialClaimCardClaimedList[account][ruleId];
    }

    function updateMerkleRoot(uint ruleId, bytes32 root) public onlyOwner {
        specialClaimCardRuleList[ruleId].merkleRoot = root;
    }

    function random(uint timeInterval, uint seed, uint length) internal pure returns (uint result) {
        result = (timeInterval + seed) % length;
    }

    function getTimeInterval(address user) public view returns (uint){
        return block.timestamp - userList[user].lastDrawTime;
    }

    function uri(uint id) public view override returns (string memory) {
        return string(abi.encodePacked(super.uri(id), id.toString()));
    }

    function changeUri(string memory _newUri) public onlyOwner {
        _setURI(_newUri);
    }

    function getStamps() public view returns (uint[] memory){
        return stamps;
    }

    modifier onlyOpened {
        require(!isStopped, "The contract is under maintenance");
        _;
    }

    function updateContractState(bool _isStopped) external onlyOwner {
        isStopped = _isStopped;
    }

    function mintBatch(address to, uint[] calldata ids, uint[] calldata amounts, bytes calldata data) external onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }

    function burnBatch(address account, uint[] calldata ids, uint[] calldata amounts) external onlyOwner {
        _burnBatch(account, ids, amounts);
    }

    function importStampRarities(uint[] memory tokenIds, uint8[] memory rarities) internal onlyOwner {
        for (uint i = 0; i < tokenIds.length; i++) {
            stampList[tokenIds[i]].rarity = rarities[i];
        }
    }

    function getStampRarities(uint[] memory tokenIds) public view returns (uint8[] memory) {
        uint8[] memory rarities = new uint8[](tokenIds.length);
        for (uint i = 0; i < tokenIds.length; i++) {
            rarities[i] = stampList[tokenIds[i]].rarity;
        }
        return rarities;
    }

    function mint(
        address account, uint id, uint amount, bytes calldata data
    ) external onlyOwner {
        _mint(account, id, amount, data);
    }

    event ClaimCardWithCommonRule(uint tokenId, address account);
    event ClaimCardWithSpecialRule(uint tokenId, address account);
}
