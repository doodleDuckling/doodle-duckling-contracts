// scripts/deploy.js
async function main() {
    DoodleDucklingStamp = await ethers.getContractFactory("DoodleDucklingStamp");
    doodleDucklingStamp = await upgrades.deployProxy(DoodleDucklingStamp, ["DoodleDucklingStamp","DoodleDucklingStamp","https://jsonserver.doodleduckling.com/metadata-stamp/"], {initializer: 'initialize'});
    console.log(doodleDucklingStamp.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
