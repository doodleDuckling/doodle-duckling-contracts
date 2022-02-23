const {MerkleTree} = require("merkletreejs");
const keccak256 = require("keccak256");

let whitelistAddress = ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4","0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2","0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db"];

const leafNodes = whitelistAddress.map(addr => keccak256(addr));
const merkleTree = new MerkleTree(leafNodes, keccak256, {sortPairs: true});

const rootHash = merkleTree.getRoot();

console.log("Whiltelist Merkle Tree\n", merkleTree.toString());
console.log("Root Hash:", rootHash.toString("hex"));

const claimingAddress = keccak256(whitelistAddress[1]);

const hexProof = merkleTree.getHexProof(claimingAddress);

console.log("Merkle Proof for Address - ",whitelistAddress[1]);
//这样的格式才会成功["0x5931b4ed56ace4c46b68524cb5bcbf4195f1bbaacbe5228fbd090546c88dd229","0x04a10bfd00977f54cc3450c9b25c9b3a502a089eba0097ba35fc33c4ea5fcb54"]
console.log(hexProof);

let result = "";
if(hexProof && hexProof.length > 0){
    result += "[";
    hexProof.forEach((value, index) => {
        if(index === hexProof.length - 1){
            result += "\"" + value + "\"]";
        }else{
            result += "\"" + value + "\",";
        }
    });
    console.log(result);
}





