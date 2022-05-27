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
    uint256 public specialPrice = 30000000000000000;//0.03 ETH
    uint256 public MAX_AMOUNT = 8888;
    uint public constant maxPurchaseOnePerson = 5;
    bool public saleIsActive = false;
    bool public earlyBirdIsActive = true;
    bool public freeMintIsActive = true;
    address payable public payee;
    bytes32 public earlyBirdMerkleRoot;
    bytes32 public freeMintMerkleRoot;
    string public baseURI;

    mapping(address => uint) public userPurchaseList;
    mapping(address => bool) public freeMintedList;

    constructor(address payable payee_) ERC721("Doodle Duckling", "DOODLE DUCKLING") {
        payee = payee_;
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

    function updateEarlyBirdMerkleRoot(bytes32 root) public onlyOwner {
        earlyBirdMerkleRoot = root;
    }

    function updateFreeMintMerkleRoot(bytes32 root) public onlyOwner {
        freeMintMerkleRoot = root;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipEarlyBirdIState() public onlyOwner {
        earlyBirdIsActive = !earlyBirdIsActive;
    }

    function flipFreeMintState() public onlyOwner {
        freeMintIsActive = !freeMintIsActive;
    }

    function mintDoodleDuckling(uint numberOfTokens, bytes32[] memory proof) public payable {
//        require(saleIsActive, "Sale must be active to mint");
//        require(numberOfTokens > 0, "Purchase number must be above 0");
//        require(numberOfTokens <= maxPurchaseOnePerson, "Can only buy 5 at a time");
//        require(_tokenId.current() + numberOfTokens <= MAX_AMOUNT, "Purchase would exceed max supply");
//        require(userPurchaseList[_msgSender()] + numberOfTokens <= maxPurchaseOnePerson, "A person can only buy five at most");
//
//        bool isEarlyBird = earlyBirdIsActive && checkWhitelist(earlyBirdMerkleRoot, proof);
//        bool isFreeMint = freeMintIsActive && !freeMintedList[_msgSender()] && checkWhitelist(freeMintMerkleRoot, proof);
//
//        //calculate fee
//        uint fee = 0;
//        if (isFreeMint) {
//            if (isEarlyBird) {
//                if (numberOfTokens > 1) {
//                    fee = specialPrice * (numberOfTokens - 1);
//                } else {
//                    fee = 0;
//                }
//            } else {
//                if (numberOfTokens > 1) {
//                    fee = price * (numberOfTokens - 1);
//                } else {
//                    fee = 0;
//                }
//            }
//            if (!freeMintedList[_msgSender()]) {
//                freeMintedList[_msgSender()] = true;
//            }
//        } else {
//            if (isEarlyBird) {
//                fee = specialPrice * numberOfTokens;
//            } else {
//                fee = price * numberOfTokens;
//            }
//        }
        (uint256 fee,bool isFreeMint) = calculateFee(numberOfTokens,proof);
        if (isFreeMint && !freeMintedList[_msgSender()]) {
            freeMintedList[_msgSender()] = true;
        }

        //todo : check safety of transferring fee in this way
        require(fee == msg.value, "Value sent is not correct");
        payee.transfer(fee);

        for (uint i = 0; i < numberOfTokens; i++) {
            _tokenId.increment();
            _mint(_msgSender(), _tokenId.current());
        }

        userPurchaseList[_msgSender()] += numberOfTokens;
    }

    function calculateFee(uint numberOfTokens, bytes32[] memory proof) public view returns(uint256 fee,bool isFreeMint){
        require(saleIsActive, "Sale must be active to mint");
        require(numberOfTokens > 0, "Purchase number must be above 0");
        require(numberOfTokens <= maxPurchaseOnePerson, "Can only buy 5 at a time");
        require(_tokenId.current() + numberOfTokens <= MAX_AMOUNT, "Purchase would exceed max supply");
        require(userPurchaseList[_msgSender()] + numberOfTokens <= maxPurchaseOnePerson, "A person can only buy five at most");

        bool isEarlyBird = earlyBirdIsActive && checkWhitelist(earlyBirdMerkleRoot, proof);
        isFreeMint = freeMintIsActive && !freeMintedList[_msgSender()] && checkWhitelist(freeMintMerkleRoot, proof);

        //calculate fee
        fee = 0;
        if (isFreeMint) {
            if (isEarlyBird) {
                if (numberOfTokens > 1) {
                    fee = specialPrice * (numberOfTokens - 1);
                } else {
                    fee = 0;
                }
            } else {
                if (numberOfTokens > 1) {
                    fee = price * (numberOfTokens - 1);
                } else {
                    fee = 0;
                }
            }
        } else {
            if (isEarlyBird) {
                fee = specialPrice * numberOfTokens;
            } else {
                fee = price * numberOfTokens;
            }
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
