// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract DoodleDuckling is ERC721, Ownable
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenId;
    using MerkleProof for *;

    uint256 public price = 60000000000000000;//0.06 ETH
    uint256 public MAX_AMOUNT = 8888;
    uint public constant maxPurchaseOnce = 10;
    uint public constant maxPurchaseOnePerson = 10;
    bool public saleIsActive = false;
    bool public nonWhitelistIsActive = false;
    address payable public payee;
    bytes32 public merkleRoot;

    mapping(address => uint) public userPurchaseList;

    constructor(address payable payee_, bytes32 root) ERC721("Doodle Duckling", "DOODLE DUCKLING") {
        payee = payee_;
        merkleRoot = root;
    }

    function mint(address to, uint256 tokenId) external onlyOwner {
        _mint(to, tokenId);
    }

    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }

    function contractURI() public pure returns (string memory) {
        return "ipfs://QmcaZT1asEtVEGj2Rjvgxj8Kvsftad6qpxdZ848sZqyZQc";
    }

    function _baseURI() internal override view virtual returns (string memory) {
        return "ipfs://QmZPQm7GD9hFRUFsxdZzZhWH5V1p35m7o1aJucER1cUSH6/";
    }

    function updateMerkleRoot(bytes32 root) public onlyOwner {
        merkleRoot = root;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipNonWhitelistState() public onlyOwner {
        nonWhitelistIsActive = !nonWhitelistIsActive;
    }

    function updatePrice(uint newPrice) public onlyOwner {
        nonWhitelistIsActive = true;
        price = newPrice;
    }

    function mintDoodleDuckling(uint numberOfTokens, bytes32[] memory proof) public payable {
        require(saleIsActive, "Sale must be active to mint");
        require(numberOfTokens > 0, "Purchase number must be above 0");
        require(numberOfTokens <= maxPurchaseOnePerson, "Can only buy 10 at a time");
        require(_tokenId.current() + numberOfTokens <= MAX_AMOUNT, "Purchase would exceed max supply");
        require(nonWhitelistIsActive || userPurchaseList[_msgSender()] <= maxPurchaseOnePerson, "During the whitelist period, a person can buy a maximum of 10 ducklings");
        require(checkPurchaseQualification(proof), "You have no purchase qualification");

        uint fee = price * numberOfTokens;
        require(fee == msg.value, "Value sent is not correct");
        payee.transfer(fee);

        for (uint i = 0; i < numberOfTokens; i++) {
            _tokenId.increment();
            _mint(_msgSender(), _tokenId.current());
        }

        userPurchaseList[_msgSender()] += numberOfTokens;
    }

    function ownerMint(address[] memory accounts) public onlyOwner {
        require(_tokenId.current() + accounts.length <= MAX_AMOUNT, "Mint would exceed max supply");

        for (uint i = 0; i < accounts.length; i++) {
            _tokenId.increment();
            _mint(accounts[i], _tokenId.current());
        }
    }

    function getAvailable() public view returns (uint) {
        return MAX_AMOUNT - _tokenId.current();
    }

    function checkPurchaseQualification(bytes32[] memory proof) public view returns (bool){
        return nonWhitelistIsActive || MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(_msgSender())));
    }
}
