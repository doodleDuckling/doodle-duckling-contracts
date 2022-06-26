async function main() {
    DoodleDucklingStamp3 = await ethers.getContractFactory("DoodleDucklingStamp3");
    doodleDucklingStamp3 =  await upgrades.upgradeProxy("0xBD870f3500b52357C5Fac07a92B7eF38c74983d5", DoodleDucklingStamp3);
    console.log("upgrade success")
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
