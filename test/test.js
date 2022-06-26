// test/Box.js
// Load dependencies
const {expect} = require('chai');

let Test;
let test;

const array = [];
// Start test block
describe('Test', function () {
    beforeEach(async function () {
        if (test) {
            return;
        }
        for (let i = 0; i < 1000; i++) {
            array.push(i + 1);
        }
        Test = await ethers.getContractFactory("Test");
        test = await Test.deploy();
        await test.deployed();
    });

    // Test case
    it('111', async function () {
        await test2();
    }).timeout(200000);

    it('222', async function () {
        await test2();
    }).timeout(200000);

    it('333', async function () {
        await test2();
    }).timeout(200000);

    it('444', async function () {
        await test2();
    }).timeout(200000);

    async function test2() {
        await test.importNfts(array);

        const nfts = await test.getNfts();
        console.log(nfts.length);
    }
});
