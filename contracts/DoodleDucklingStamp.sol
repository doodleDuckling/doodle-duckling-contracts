// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract DoodleDucklingStamp is ERC1155Upgradeable, OwnableUpgradeable {
    using StringsUpgradeable for uint256;

    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenId;

    struct Stamp {
        uint256 totalAmount;
        uint256 remainAmount;
        uint8 rarity;
    }

    struct User {
        uint256 lastDrawTime;
        bool isWhitelisted;
    }

    mapping(address => User) public userList;
    mapping(uint256 => Stamp) public stampList;
    uint256[] public stamps;

    bool public isStopped;
    bool public nonWhitelistIsActive;

    function initialize(string memory _name, string memory _symbol, string memory _baseURI) public initializer {
        name = _name;
        symbol = _symbol;
        __ERC1155_init(_baseURI);
        __Ownable_init();
        nonWhitelistIsActive = true;
    }

    function createStamps(uint256[] memory amounts, uint8[] memory rarities) public onlyOwner {
        require(amounts.length > 0 && rarities.length == amounts.length, "length not match");
        for (uint256 i = 0; i < amounts.length; i++) {
            _tokenId.increment();
            stampList[_tokenId.current()] = Stamp(amounts[i], amounts[i], rarities[i]);
            stamps.push(_tokenId.current());
        }
    }

    function reCreateStamp(uint256 tokenId, uint256 amount) public onlyOwner {
        require(amount > 0, "amount must above 0");
        require(stampList[tokenId].totalAmount > 0 && stampList[tokenId].remainAmount == 0, "stamp never created or remain");
        stampList[tokenId].remainAmount = amount;
        stampList[tokenId].totalAmount += amount;
        stamps.push(tokenId);
    }

    function drawStampDaily(uint256 seed) public onlyOpened {
        require(nonWhitelistIsActive || userList[msg.sender].isWhitelisted, 'ec1');
        uint256 timeInterval = getTimeInterval(msg.sender);
        require(timeInterval > 24 * 3600, 'ec2');
        require(stamps.length > 0, 'ec3');

        uint256 randomIndex = random(timeInterval, seed, stamps);

        uint256 mintTokenId = 0;

        Stamp storage stamp = stampList[stamps[randomIndex]];
        if (stamp.remainAmount > 0) {
            _mint(msg.sender, stamps[randomIndex], 1, '');
            mintTokenId = stamps[randomIndex];
            userList[msg.sender].lastDrawTime = block.timestamp;
            stamp.remainAmount--;
            if (stamp.remainAmount == 0) {
                removeFromStamps(randomIndex, stamps);
            }
        } else {
            removeFromStamps(randomIndex, stamps);
        }

        emit DrawStampDailyEvent(mintTokenId, mintTokenId > 0, msg.sender);
    }

    function removeFromStamps(uint index, uint[] storage _stamps) internal {
        if (_stamps.length > 1) {
            _stamps[index] = _stamps[_stamps.length - 1];
        }
        _stamps.pop();
    }

    function random(uint256 timeInterval, uint256 seed, uint[] storage _stamps) internal view returns (uint256 result) {
        result = (timeInterval + seed) % _stamps.length;
    }

    function getTimeInterval(address user) public view returns (uint256){
        return block.timestamp - userList[user].lastDrawTime;
    }

    function uri(uint256 id) public view override returns (string memory) {
        return string(abi.encodePacked(super.uri(id), id.toString()));
    }

    function changeUri(string memory _newUri) public onlyOwner {
        _setURI(_newUri);
    }

    function getStamps() public view returns (uint256[] memory){
        return stamps;
    }

    function ownerMint(address to, uint256 id, uint256 amount) public onlyOwner {
        require(isStopped, "contract must stop");
        require(stampList[id].remainAmount >= amount, "remainAmount must >= amount ");
        stampList[id].remainAmount = stampList[id].remainAmount - amount;
        if (stampList[id].remainAmount == 0) {
            for (uint i = 0; i < stamps.length; i++) {
                if (stamps[i] == id) {
                    removeFromStamps(i, stamps);
                    break;
                }
            }
        }
        _mint(to, id, amount, '');
    }

    function importWhitelist(address[] memory _accounts, bool[] memory _isWhitelists) public onlyOwner {
        require(_accounts.length == _isWhitelists.length, "not match");
        for (uint i = 0; i < _accounts.length; i++) {
            userList[_accounts[i]].isWhitelisted = _isWhitelists[i];
        }
    }

    modifier onlyOpened {
        require(!isStopped, "The contract is under maintenance");
        _;
    }

    function updateContractState(bool _isStopped) external onlyOwner {
        isStopped = _isStopped;
    }

    function mintBatch(address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }

    function burnBatch(address account, uint256[] calldata ids, uint256[] calldata amounts) external onlyOwner {
        _burnBatch(account, ids, amounts);
    }


    function importStampList(uint[] memory ids, uint[] memory totalAmounts, uint[] memory remainAmounts, uint8[] memory rarities) public onlyOwner {
        require(isStopped, "contract must stop");

        for (uint i = 0; i < ids.length; i++) {
            stampList[ids[i]].totalAmount = totalAmounts[i];
            stampList[ids[i]].remainAmount = remainAmounts[i];
            stampList[ids[i]].rarity = rarities[i];
        }
    }

    function getStampRarity(uint256 tokenId) external view returns (uint8) {
        return stampList[tokenId].rarity;
    }

    function mint(
        address account, uint256 id, uint256 amount, bytes calldata data
    ) external onlyOwner{
        _mint(account, id, amount, data);
    }

    function flipNonWhitelistState() public onlyOwner {
        nonWhitelistIsActive = !nonWhitelistIsActive;
    }

    event DrawStampDailyEvent(uint256 tokenId, bool drawSuccess, address account);
}
