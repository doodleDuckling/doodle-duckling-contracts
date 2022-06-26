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

    uint256 public price = 50000000000000000;//0.05 ETH
    uint256 public MAX_AMOUNT = 8888;
    bool public saleIsActive = false;
    bool public freeMintIsActive = true;
    address payable public payee;
    bytes32 public freeMintMerkleRoot;
    string public baseURI;

    mapping(address => bool) public freeMintedList;

    constructor(address payable payee_,string memory baseURI_) ERC721("Doodle Duckling", "DOODLE DUCKLING") {
        payee = payee_;
        baseURI = baseURI_;
    }

    function mint(address to, uint256 tokenId) external onlyOwner {
        _mint(to, tokenId);
    }

    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }

    function changeBaseURI(string memory newUri) public onlyOwner {
        baseURI = newUri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function updateFreeMintMerkleRoot(bytes32 root) public onlyOwner {
        freeMintMerkleRoot = root;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipFreeMintState() public onlyOwner {
        freeMintIsActive = !freeMintIsActive;
    }

    function freeMint(bytes32[] memory proof) public {
        require(freeMintIsActive, "Free mint is not available");
        require(_tokenId.current() + 1 <= MAX_AMOUNT, "No more Ducklings");
        require(checkWhitelist(freeMintMerkleRoot, proof),"You are not in whitelist");
        require(!freeMintedList[_msgSender()],"You have free minted");
        _tokenId.increment();
        _mint(_msgSender(), _tokenId.current());
        freeMintedList[_msgSender()] = true;
    }

    function buy(uint256 buyNum) public payable {
        require(saleIsActive, "Buy is not available");
        require(buyNum > 0, "Purchase number must be above 0");
        require(_tokenId.current() + buyNum <= MAX_AMOUNT, "Purchase would exceed max supply");
        uint256 fee = price * buyNum;
        require(fee == msg.value, "Value sent is not correct");
        payee.transfer(fee);

        for (uint i = 0; i < buyNum; i++) {
            _tokenId.increment();
            _mint(_msgSender(), _tokenId.current());
        }
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

    function checkWhitelist(bytes32 root, bytes32[] memory proof) public view returns (bool){
        return MerkleProof.verify(proof, root, keccak256(abi.encodePacked(_msgSender())));
    }
}
